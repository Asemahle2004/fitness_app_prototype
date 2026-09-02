import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'custom_exercise_form_screen.dart';
import 'custom_exercise_store.dart';
import 'exercise_favorite_store.dart';
import 'exercise_repository.dart';
import 'master_exercise_catalogue.dart';
import 'master_exercise_library_adapter.dart';
import 'master_exercise_library_screen.dart' as legacy;
import 'safety_engine.dart';

/// Mobile-first Exercise Library.
///
/// The master catalogue is bundled with the app and renders without network
/// access. Remote media/source enrichment is intentionally deferred to an
/// individual exercise detail screen so opening/scrolling the 488-item library
/// never fans out hundreds of database or provider requests.
class ExerciseLibraryScreen extends StatefulWidget {
  final SupabaseClient client;
  final bool selectionMode;
  final Set<String> initialSelectedNames;
  final SafetyProfile? safetyProfile;

  const ExerciseLibraryScreen({
    super.key,
    required this.client,
    this.selectionMode = false,
    this.initialSelectedNames = const {},
    this.safetyProfile,
  });

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  late final CustomExerciseStore _customStore;
  late final ExerciseFavoriteStore _favoriteStore;
  late Future<List<OnlineExercise>> _future;

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedNames = <String>{};
  final Set<String> _favoriteIds = <String>{};
  final Map<String, String> _searchIndex = <String, String>{};

  static final Map<String, MasterExerciseDefinition> _definitionsByName = {
    for (final definition in MasterExerciseCatalogue.definitions)
      MasterExerciseCatalogue.normalize(definition.name): definition,
  };

  String _search = '';
  String? _type;
  String? _group;
  String? _difficulty;
  String? _location;
  bool _favoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _customStore = CustomExerciseStore(widget.client);
    _favoriteStore = ExerciseFavoriteStore(widget.client);
    _selectedNames.addAll(widget.initialSelectedNames);
    _future = _loadLocalLibrary();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  MasterExerciseDefinition? _definition(OnlineExercise exercise) =>
      _definitionsByName[MasterExerciseCatalogue.normalize(exercise.name)];

  bool _isCustom(OnlineExercise exercise) =>
      exercise.mediaSource == CustomExerciseStore.mediaSource;

  String _typeFor(OnlineExercise exercise) =>
      _definition(exercise)?.exerciseType ?? 'Custom';

  List<String> _groupsFor(OnlineExercise exercise) {
    final definition = _definition(exercise);
    if (definition != null) return definition.groups;
    final category = exercise.category?.trim();
    return category == null || category.isEmpty
        ? const <String>['Custom']
        : <String>[category];
  }

  Future<List<OnlineExercise>> _loadLocalLibrary() async {
    final merged = <String, OnlineExercise>{
      for (final exercise in MasterExerciseLibraryAdapter.builtIn)
        exercise.name.trim().toLowerCase(): exercise,
    };

    try {
      for (final custom in await _customStore.load()) {
        merged[custom.name.trim().toLowerCase()] = custom.toOnlineExercise();
      }
    } catch (_) {
      // The built-in catalogue is still fully usable.
    }

    final result = merged.values.toList(growable: false)..sort(_compareExercises);
    _searchIndex.clear();
    return result;
  }

  int _compareExercises(OnlineExercise a, OnlineExercise b) {
    final aDef = _definition(a);
    final bDef = _definition(b);
    final type = MasterExerciseCatalogue.typeIndex(aDef?.exerciseType).compareTo(
      MasterExerciseCatalogue.typeIndex(bDef?.exerciseType),
    );
    if (type != 0) return type;
    final section = MasterExerciseCatalogue.sectionIndex(aDef?.section).compareTo(
      MasterExerciseCatalogue.sectionIndex(bDef?.section),
    );
    if (section != 0) return section;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  Future<void> _reload() async {
    setState(() => _future = _loadLocalLibrary());
    await _future;
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _favoriteStore.load();
      if (!mounted) return;
      setState(() {
        _favoriteIds
          ..clear()
          ..addAll(favorites);
      });
    } catch (_) {}
  }

  Future<void> _toggleFavorite(OnlineExercise exercise) async {
    final id = exercise.id.trim();
    if (id.isEmpty) return;
    final old = _favoriteIds.contains(id);
    setState(() {
      old ? _favoriteIds.remove(id) : _favoriteIds.add(id);
    });
    try {
      await _favoriteStore.setFavorite(id, !old);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        old ? _favoriteIds.add(id) : _favoriteIds.remove(id);
      });
    }
  }

  bool _allowed(OnlineExercise exercise) {
    final profile = widget.safetyProfile;
    if (profile == null) return true;
    return SafetyEngine.exerciseNameAllowed(
      exercise.name,
      profile,
      target:
          '${exercise.primaryMuscles.join(' ')} ${exercise.secondaryMuscles.join(' ')} ${exercise.movementPattern ?? ''}',
      equipment: exercise.equipment.join(' '),
    );
  }

  String _indexedText(OnlineExercise exercise) {
    return _searchIndex.putIfAbsent(exercise.id, () {
      final definition = _definition(exercise);
      return <String>[
        exercise.name,
        definition?.exerciseType ?? 'Custom',
        ...?definition?.groups,
        exercise.category ?? '',
        ...exercise.primaryMuscles,
        ...exercise.secondaryMuscles,
        ...exercise.equipment,
        exercise.movementPattern ?? '',
      ].join(' ').toLowerCase();
    });
  }

  List<OnlineExercise> _filtered(List<OnlineExercise> source) {
    final query = _search.trim().toLowerCase();
    final result = <OnlineExercise>[];
    for (final exercise in source) {
      final definition = _definition(exercise);
      final type = definition?.exerciseType ?? 'Custom';
      final groups = definition?.groups ?? _groupsFor(exercise);
      if (query.isNotEmpty && !_indexedText(exercise).contains(query)) continue;
      if (_favoritesOnly && !_favoriteIds.contains(exercise.id)) continue;
      if (_type != null && type != _type) continue;
      if (_group != null && !groups.contains(_group)) continue;
      if (_difficulty != null && exercise.difficulty != _difficulty) continue;
      if (_location != null && !exercise.locations.contains(_location)) continue;
      result.add(exercise);
    }
    return result;
  }

  List<String> _typeValues(List<OnlineExercise> all) {
    final present = all.map(_typeFor).toSet();
    return <String>[
      ...MasterExerciseCatalogue.typeOrder.where(present.contains),
      if (present.contains('Custom')) 'Custom',
    ];
  }

  List<String> _groupValues(List<OnlineExercise> all) {
    final present = all.expand(_groupsFor).toSet();
    final ordered = MasterExerciseCatalogue.sectionOrder
        .where(present.contains)
        .toList(growable: true);
    final extras = present
        .where((item) => !MasterExerciseCatalogue.sectionOrder.contains(item))
        .toList()
      ..sort();
    ordered.addAll(extras);
    return ordered;
  }

  Future<void> _createCustomExercise() async {
    final created = await Navigator.push<CustomExerciseRecord>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomExerciseFormScreen(client: widget.client),
      ),
    );
    if (created != null && mounted) await _reload();
  }

  Future<void> _editCustomExercise(OnlineExercise exercise) async {
    final record = await _customStore.findById(exercise.id);
    if (record == null || !mounted) return;
    final saved = await Navigator.push<CustomExerciseRecord>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomExerciseFormScreen(
          client: widget.client,
          existing: record,
        ),
      ),
    );
    if (saved != null && mounted) await _reload();
  }

  Future<void> _deleteCustomExercise(OnlineExercise exercise) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete custom exercise?'),
            content: Text('Delete “${exercise.name}”?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('DELETE'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await _customStore.delete(exercise.id);
    await _favoriteStore.remove(exercise.id);
    _selectedNames.remove(exercise.name);
    _favoriteIds.remove(exercise.id);
    if (mounted) await _reload();
  }

  void _openDetail(OnlineExercise exercise) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => legacy.LibraryExerciseDetailScreen(exercise: exercise),
      ),
    );
  }

  IconData _iconFor(OnlineExercise exercise) {
    final type = _typeFor(exercise);
    if (type.contains('Running')) return Icons.directions_run_rounded;
    if (type == 'Cardio') return Icons.favorite_rounded;
    if (type.contains('Stretch') || type == 'Cooldown') {
      return Icons.self_improvement_rounded;
    }
    if (type.contains('Warm-Up')) return Icons.local_fire_department_rounded;
    if (_isCustom(exercise)) return Icons.person_add_alt_1_rounded;
    return Icons.fitness_center_rounded;
  }

  Widget _thumbnail(OnlineExercise exercise) {
    return Container(
      width: 66,
      height: 66,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4ED),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        _iconFor(exercise),
        color: const Color(0xFF176B57),
        size: 28,
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _search = '';
      _type = null;
      _group = null;
      _difficulty = null;
      _location = null;
      _favoritesOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        title: Text(
          widget.selectionMode ? 'Choose exercises' : 'Exercise library',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Create custom exercise',
            onPressed: _createCustomExercise,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<OnlineExercise>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? MasterExerciseLibraryAdapter.builtIn;
          final exercises = _filtered(all);
          final difficulties = all
              .map((item) => item.difficulty)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Find exercises by training type or body area',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'The master catalogue is stored on your phone. Exercise demonstrations load only when you open an exercise.',
                      style: TextStyle(
                        color: Color(0xFF627D98),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _search = value),
                      decoration: InputDecoration(
                        hintText: 'Search exercise, muscle, group or equipment',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _search.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _search = '');
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterMenu(
                            label: _type ?? 'Training type',
                            values: _typeValues(all),
                            onSelected: (value) => setState(() => _type = value),
                            onClear: () => setState(() => _type = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterMenu(
                            label: _group ?? 'Muscle / group',
                            values: _groupValues(all),
                            onSelected: (value) => setState(() => _group = value),
                            onClear: () => setState(() => _group = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterMenu(
                            label: _difficulty ?? 'Level',
                            values: difficulties,
                            onSelected: (value) =>
                                setState(() => _difficulty = value),
                            onClear: () => setState(() => _difficulty = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterMenu(
                            label: _location ?? 'Location',
                            values: const ['Home', 'Gym', 'Outside'],
                            onSelected: (value) =>
                                setState(() => _location = value),
                            onClear: () => setState(() => _location = null),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            selected: _favoritesOnly,
                            label: Text('Favorites (${_favoriteIds.length})'),
                            avatar: const Icon(Icons.favorite_border_rounded, size: 17),
                            onSelected: (value) =>
                                setState(() => _favoritesOnly = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Text(
                          '${exercises.length} of ${all.length} exercises',
                          style: const TextStyle(
                            color: Color(0xFF627D98),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (widget.selectionMode)
                          Text(
                            '${_selectedNames.length} selected',
                            style: const TextStyle(
                              color: Color(0xFF176B87),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: exercises.isEmpty
                    ? Center(
                        child: OutlinedButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.filter_alt_off_rounded),
                          label: const Text('CLEAR FILTERS'),
                        ),
                      )
                    : ListView.builder(
                        cacheExtent: 500,
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                        itemCount: exercises.length,
                        itemBuilder: (context, index) =>
                            _exerciseCard(exercises[index]),
                      ),
              ),
              if (widget.selectionMode) _selectionButton(all),
            ],
          );
        },
      ),
      floatingActionButton: widget.selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _createCustomExercise,
              icon: const Icon(Icons.add_rounded),
              label: const Text('CUSTOM'),
            ),
    );
  }

  Widget _exerciseCard(OnlineExercise exercise) {
    final definition = _definition(exercise);
    final custom = _isCustom(exercise);
    final allowed = _allowed(exercise);
    final selected = _selectedNames.contains(exercise.name);
    final favorite = _favoriteIds.contains(exercise.id);
    final group = definition?.section ?? exercise.category ?? 'Custom';
    final type = definition?.exerciseType ?? 'Custom';

    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      elevation: 0,
      color: allowed ? Colors.white : const Color(0xFFF1F3F5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.selectionMode
            ? () {
                if (!allowed) return;
                setState(() {
                  selected
                      ? _selectedNames.remove(exercise.name)
                      : _selectedNames.add(exercise.name);
                });
              }
            : () => _openDetail(exercise),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              _thumbnail(exercise),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$type • $group${exercise.difficulty == null ? '' : ' • ${exercise.difficulty}'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF176B87),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      exercise.equipment.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF829AB1),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.selectionMode)
                Checkbox(
                  value: selected,
                  onChanged: allowed
                      ? (_) => setState(() {
                            selected
                                ? _selectedNames.remove(exercise.name)
                                : _selectedNames.add(exercise.name);
                          })
                      : null,
                )
              else ...[
                IconButton(
                  tooltip: favorite ? 'Remove favorite' : 'Favorite',
                  onPressed: () => _toggleFavorite(exercise),
                  icon: Icon(
                    favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: favorite ? const Color(0xFFD64545) : const Color(0xFF829AB1),
                  ),
                ),
                if (custom)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _editCustomExercise(exercise);
                      if (value == 'delete') _deleteCustomExercise(exercise);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  )
                else
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF9FB3C8)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectionButton(List<OnlineExercise> all) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _selectedNames.isEmpty
                ? null
                : () {
                    final selected = all
                        .where((exercise) =>
                            _selectedNames.contains(exercise.name) &&
                            _allowed(exercise))
                        .toList(growable: false);
                    Navigator.pop(context, selected);
                  },
            child: const Text('USE SELECTED EXERCISES'),
          ),
        ),
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  final String label;
  final List<String> values;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;

  const _FilterMenu({
    required this.label,
    required this.values,
    required this.onSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == '__clear__') {
          onClear();
        } else {
          onSelected(value);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: '__clear__', child: Text('All')),
        ...values.map((value) => PopupMenuItem(value: value, child: Text(value))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFD9E2EC)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 19),
          ],
        ),
      ),
    );
  }
}
