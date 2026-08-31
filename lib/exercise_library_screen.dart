import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'custom_exercise_form_screen.dart';
import 'custom_exercise_store.dart';
import 'exercise_media.dart';
import 'exercise_repository.dart';
import 'safety_engine.dart';

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
  late final ExerciseRepository _repository;
  late final CustomExerciseStore _customStore;
  late Future<List<OnlineExercise>> _future;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedNames = {};
  String _search = '';
  String? _category;
  String? _difficulty;
  String? _location;

  @override
  void initState() {
    super.initState();
    _repository = ExerciseRepository(widget.client);
    _customStore = CustomExerciseStore(widget.client);
    _future = _loadAll();
    _selectedNames.addAll(widget.initialSelectedNames);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isCustom(OnlineExercise exercise) =>
      exercise.mediaSource == CustomExerciseStore.mediaSource;

  Future<List<OnlineExercise>> _loadAll() async {
    List<OnlineExercise> builtIn = const [];
    List<CustomExerciseRecord> custom = const [];
    try {
      builtIn = await _repository.fetchAll();
    } catch (_) {}
    try {
      custom = await _customStore.load();
    } catch (_) {}

    final merged = <String, OnlineExercise>{};
    for (final exercise in builtIn) {
      merged[exercise.name.trim().toLowerCase()] = exercise;
    }
    for (final exercise in custom) {
      merged[exercise.name.trim().toLowerCase()] = exercise.toOnlineExercise();
    }
    final result = merged.values.toList(growable: false)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  Future<void> _reload() async {
    setState(() => _future = _loadAll());
    await _future;
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

  List<OnlineExercise> _filtered(List<OnlineExercise> source) {
    final query = _search.trim().toLowerCase();
    return source.where((exercise) {
      final searchText = [
        exercise.name,
        exercise.category ?? '',
        exercise.primaryMuscles.join(' '),
        exercise.secondaryMuscles.join(' '),
        exercise.equipment.join(' '),
      ].join(' ').toLowerCase();
      return (query.isEmpty || searchText.contains(query)) &&
          (_category == null || exercise.category == _category) &&
          (_difficulty == null || exercise.difficulty == _difficulty) &&
          (_location == null || exercise.locations.contains(_location));
    }).toList(growable: false);
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete custom exercise?'),
        content: Text('Delete “${exercise.name}”? Saved workouts that already contain it will keep their existing copy.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _customStore.delete(exercise.id);
    _selectedNames.remove(exercise.name);
    if (mounted) await _reload();
  }

  Future<void> _openDetail(OnlineExercise exercise) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibraryExerciseDetailScreen(exercise: exercise),
      ),
    );
  }

  Widget _visual(OnlineExercise exercise, {double size = 82}) {
    if (_isCustom(exercise)) {
      return Container(
        color: const Color(0xFFEAF7FA),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF176B87)),
            if (size > 100) ...[
              const SizedBox(height: 7),
              const Text(
                'CUSTOM EXERCISE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF176B87),
                ),
              ),
            ],
          ],
        ),
      );
    }
    return ExerciseMedia(
      exerciseName: exercise.name,
      movementPattern: exercise.movementPattern,
      fit: size > 100 ? BoxFit.contain : BoxFit.cover,
      compact: size <= 100,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        title: Text(
          widget.selectionMode ? 'Choose exercises' : 'Exercise library',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF102A43),
          ),
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
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load the exercise library.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final all = snapshot.data ?? const <OnlineExercise>[];
          final categories = all
              .map((exercise) => exercise.category)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();
          final difficulties = all
              .map((exercise) => exercise.difficulty)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();
          final exercises = _filtered(all);
          final customCount = all.where(_isCustom).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _search = value),
                      decoration: InputDecoration(
                        hintText: 'Search exercise, muscle or equipment',
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
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterMenu(
                            label: _category ?? 'Category',
                            values: categories,
                            onSelected: (value) => setState(() => _category = value),
                            onClear: () => setState(() => _category = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterMenu(
                            label: _difficulty ?? 'Difficulty',
                            values: difficulties,
                            onSelected: (value) => setState(() => _difficulty = value),
                            onClear: () => setState(() => _difficulty = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterMenu(
                            label: _location ?? 'Location',
                            values: const ['Home', 'Gym', 'Outside'],
                            onSelected: (value) => setState(() => _location = value),
                            onClear: () => setState(() => _location = null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '${exercises.length} of ${all.length} exercises',
                          style: const TextStyle(
                            color: Color(0xFF627D98),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (customCount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• $customCount custom',
                            style: const TextStyle(
                              color: Color(0xFF176B87),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
                    if (widget.safetyProfile?.hasLimitation == true) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Exercises that clearly conflict with your reported limitation cannot be added here. This is conservative screening, not a diagnosis.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Color(0xFF9A6700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: exercises.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('No exercises match these filters.'),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _createCustomExercise,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('CREATE CUSTOM EXERCISE'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          final custom = _isCustom(exercise);
                          final allowed = _allowed(exercise);
                          final selected = _selectedNames.contains(exercise.name);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: allowed ? Colors.white : const Color(0xFFF1F3F5),
                              borderRadius: BorderRadius.circular(18),
                              border: custom
                                  ? Border.all(color: const Color(0xFFB9E2EA))
                                  : null,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: widget.selectionMode
                                  ? () {
                                      if (!allowed) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('This exercise conflicts with the limitation you reported.'),
                                          ),
                                        );
                                        return;
                                      }
                                      setState(() {
                                        if (selected) {
                                          _selectedNames.remove(exercise.name);
                                        } else {
                                          _selectedNames.add(exercise.name);
                                        }
                                      });
                                    }
                                  : () => _openDetail(exercise),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 82,
                                      height: 82,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _visual(exercise),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  exercise.name,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: allowed
                                                        ? const Color(0xFF102A43)
                                                        : const Color(0xFF829AB1),
                                                  ),
                                                ),
                                              ),
                                              if (custom)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFE5F4F8),
                                                    borderRadius: BorderRadius.circular(999),
                                                  ),
                                                  child: const Text(
                                                    'CUSTOM',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF176B87),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            [
                                              if (exercise.category != null) exercise.category!,
                                              if (exercise.difficulty != null) exercise.difficulty!,
                                            ].join(' • '),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF176B87),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            exercise.primaryMuscles.join(', '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13, color: Color(0xFF627D98)),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            exercise.equipment.join(', '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF829AB1)),
                                          ),
                                          if (!allowed) ...[
                                            const SizedBox(height: 5),
                                            const Text(
                                              'Not recommended for your current limitation',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF9A6700),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (widget.selectionMode)
                                      Checkbox(
                                        value: selected,
                                        onChanged: allowed
                                            ? (_) {
                                                setState(() {
                                                  if (selected) {
                                                    _selectedNames.remove(exercise.name);
                                                  } else {
                                                    _selectedNames.add(exercise.name);
                                                  }
                                                });
                                              }
                                            : null,
                                      )
                                    else if (custom)
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
                                      IconButton(
                                        tooltip: 'Exercise details',
                                        onPressed: () => _openDetail(exercise),
                                        icon: const Icon(Icons.chevron_right, color: Color(0xFF9FB3C8)),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (widget.selectionMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _selectedNames.isEmpty
                          ? null
                          : () {
                              final selected = all
                                  .where(
                                    (exercise) =>
                                        _selectedNames.contains(exercise.name) && _allowed(exercise),
                                  )
                                  .toList(growable: false);
                              Navigator.pop(context, selected);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF176B87),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'USE SELECTED EXERCISES',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: widget.selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _createCustomExercise,
              icon: const Icon(Icons.add_rounded),
              label: const Text('CUSTOM EXERCISE'),
            ),
    );
  }
}

class LibraryExerciseDetailScreen extends StatelessWidget {
  final OnlineExercise exercise;

  const LibraryExerciseDetailScreen({
    super.key,
    required this.exercise,
  });

  bool get _isCustom => exercise.mediaSource == CustomExerciseStore.mediaSource;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
              ),
              if (_isCustom)
                const Chip(label: Text('CUSTOM')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (exercise.category != null) exercise.category!,
              if (exercise.difficulty != null) exercise.difficulty!,
              if (exercise.primaryMuscles.isNotEmpty) exercise.primaryMuscles.join(', '),
            ].join(' • '),
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF176B87),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _isCustom
                  ? Container(
                      color: const Color(0xFFEAF7FA),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_add_alt_1_rounded, size: 56, color: Color(0xFF176B87)),
                          SizedBox(height: 10),
                          Text(
                            'USER-CREATED EXERCISE',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF176B87)),
                          ),
                        ],
                      ),
                    )
                  : ExerciseMedia(
                      exerciseName: exercise.name,
                      movementPattern: exercise.movementPattern,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
          const SizedBox(height: 24),
          _LibrarySection(
            title: 'How to perform',
            children: exercise.instructions.isEmpty
                ? [_isCustom
                    ? 'No instructions were added by the user.'
                    : 'Technique instructions are being reviewed.']
                : exercise.instructions,
            numbered: true,
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD9E2EC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Equipment: ${exercise.equipment.join(', ')}'),
                const SizedBox(height: 6),
                Text('Locations: ${exercise.locations.join(', ')}'),
                if (exercise.movementPattern != null) ...[
                  const SizedBox(height: 6),
                  Text('Movement: ${exercise.movementPattern}'),
                ],
                if (_isCustom) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'This exercise was created by the user and has not been independently technique-reviewed by LeanIt.',
                    style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF627D98)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LibrarySection extends StatelessWidget {
  final String title;
  final List<String> children;
  final bool numbered;

  const _LibrarySection({
    required this.title,
    required this.children,
    this.numbered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF102A43),
          ),
        ),
        const SizedBox(height: 12),
        ...children.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        numbered ? '${entry.key + 1}.' : '•',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF176B87),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: Color(0xFF486581),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFD9E2EC)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF486581),
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}
