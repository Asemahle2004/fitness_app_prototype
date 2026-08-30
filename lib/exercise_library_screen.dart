import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise_repository.dart';
import 'movement_visual.dart';
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
  late final Future<List<OnlineExercise>> _future;
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
    _future = _repository.fetchAll();
    _selectedNames.addAll(widget.initialSelectedNames);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _allowed(OnlineExercise exercise) {
    final profile = widget.safetyProfile;
    if (profile == null) return true;
    return SafetyEngine.exerciseNameAllowed(
      exercise.name,
      profile,
      target:
          '${exercise.primaryMuscles.join(' ')} ${exercise.movementPattern ?? ''}',
      equipment: exercise.equipment.join(' '),
    );
  }

  List<OnlineExercise> _filtered(List<OnlineExercise> source) {
    final query = _search.trim().toLowerCase();
    return source.where((exercise) {
      final matchesSearch = query.isEmpty ||
          exercise.name.toLowerCase().contains(query) ||
          (exercise.category ?? '').toLowerCase().contains(query) ||
          exercise.primaryMuscles
              .any((muscle) => muscle.toLowerCase().contains(query));
      final matchesCategory =
          _category == null || exercise.category == _category;
      final matchesDifficulty =
          _difficulty == null || exercise.difficulty == _difficulty;
      final matchesLocation =
          _location == null || exercise.locations.contains(_location);
      return matchesSearch &&
          matchesCategory &&
          matchesDifficulty &&
          matchesLocation;
    }).toList(growable: false);
  }

  Future<void> _openDetail(OnlineExercise exercise) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibraryExerciseDetailScreen(
          exercise: exercise,
          repository: _repository,
        ),
      ),
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
          widget.selectionMode ? 'Customise workout' : 'Exercise library',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF102A43),
          ),
        ),
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
              .map((e) => e.category)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();
          final difficulties = all
              .map((e) => e.difficulty)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();
          final exercises = _filtered(all);

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
                        hintText: 'Search exercise, muscle or category',
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
                          borderSide: const BorderSide(
                            color: Color(0xFFD9E2EC),
                          ),
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
                            onSelected: (value) {
                              setState(() => _category = value);
                            },
                            onClear: () => setState(() => _category = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterMenu(
                            label: _difficulty ?? 'Difficulty',
                            values: difficulties,
                            onSelected: (value) {
                              setState(() => _difficulty = value);
                            },
                            onClear: () => setState(() => _difficulty = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterMenu(
                            label: _location ?? 'Location',
                            values: const ['Home', 'Gym', 'Outside'],
                            onSelected: (value) {
                              setState(() => _location = value);
                            },
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
                    ? const Center(child: Text('No exercises match these filters.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          final allowed = _allowed(exercise);
                          final selected = _selectedNames.contains(exercise.name);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: allowed
                                  ? Colors.white
                                  : const Color(0xFFF1F3F5),
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: widget.selectionMode
                                    ? () {
                                        if (!allowed) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'This exercise conflicts with the limitation you reported.',
                                              ),
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
                                        child: exercise.imagePath != null &&
                                                exercise.imagePath!.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.network(
                                                  _repository.publicImageUrl(
                                                    exercise.imagePath!,
                                                  ),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      MovementVisual(
                                                    exerciseName: exercise.name,
                                                    movementPattern:
                                                        exercise.movementPattern,
                                                    compact: true,
                                                  ),
                                                ),
                                              )
                                            : MovementVisual(
                                                exerciseName: exercise.name,
                                                movementPattern:
                                                    exercise.movementPattern,
                                                compact: true,
                                              ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              exercise.name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: allowed
                                                    ? const Color(0xFF102A43)
                                                    : const Color(0xFF829AB1),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              [
                                                if (exercise.category != null)
                                                  exercise.category!,
                                                if (exercise.difficulty != null)
                                                  exercise.difficulty!,
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
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF627D98),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              exercise.equipment.join(', '),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF829AB1),
                                              ),
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
                                                      _selectedNames.remove(
                                                        exercise.name,
                                                      );
                                                    } else {
                                                      _selectedNames.add(
                                                        exercise.name,
                                                      );
                                                    }
                                                  });
                                                }
                                              : null,
                                        )
                                      else
                                        IconButton(
                                          tooltip: 'Exercise details',
                                          onPressed: () => _openDetail(exercise),
                                          icon: const Icon(
                                            Icons.chevron_right,
                                            color: Color(0xFF9FB3C8),
                                          ),
                                        ),
                                    ],
                                  ),
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
                                        _selectedNames.contains(exercise.name) &&
                                        _allowed(exercise),
                                  )
                                  .toList(growable: false);
                              Navigator.pop(context, selected);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF176B87),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
    );
  }
}

class LibraryExerciseDetailScreen extends StatelessWidget {
  final OnlineExercise exercise;
  final ExerciseRepository repository;

  const LibraryExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.repository,
  });

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
          Text(
            exercise.name,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (exercise.category != null) exercise.category!,
              if (exercise.difficulty != null) exercise.difficulty!,
              if (exercise.primaryMuscles.isNotEmpty)
                exercise.primaryMuscles.join(', '),
            ].join(' • '),
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF176B87),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 320,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: exercise.imagePath != null && exercise.imagePath!.isNotEmpty
                  ? Image.network(
                      repository.publicImageUrl(exercise.imagePath!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => MovementVisual(
                        exerciseName: exercise.name,
                        movementPattern: exercise.movementPattern,
                      ),
                    )
                  : MovementVisual(
                      exerciseName: exercise.name,
                      movementPattern: exercise.movementPattern,
                    ),
            ),
          ),
          const SizedBox(height: 24),
          _LibrarySection(
            title: 'How to perform',
            children: exercise.instructions.isEmpty
                ? const ['Technique instructions are being reviewed.']
                : exercise.instructions,
            numbered: true,
          ),
          const SizedBox(height: 22),
          _LibrarySection(
            title: 'Common mistakes',
            children: exercise.commonMistakes.isEmpty
                ? const ['No reviewed mistakes have been added yet.']
                : exercise.commonMistakes,
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
        ...values.map(
          (value) => PopupMenuItem(value: value, child: Text(value)),
        ),
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
