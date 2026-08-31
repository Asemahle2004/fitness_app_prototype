import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise_library_screen.dart';
import 'exercise_repository.dart';
import 'profile_service.dart';
import 'safety_engine.dart';
import 'workout_engine.dart';

class WorkoutEditorMapper {
  static ExercisePrescription fromOnlineExercise(OnlineExercise exercise) {
    final category = exercise.category?.toLowerCase() ?? '';

    int sets = 3;
    String reps = '8–12';
    String rest = '75 sec';
    String? metricLabel;

    if (category.contains('stretch')) {
      sets = 2;
      reps = '30–45 sec';
      rest = '30 sec';
      metricLabel = 'TIME';
    } else if (category.contains('cardio')) {
      sets = 1;
      reps = '10 min';
      rest = 'As needed';
      metricLabel = 'TIME';
    }

    final targets = <String>{
      ...exercise.primaryMuscles,
      ...exercise.secondaryMuscles.take(2),
    }.where((value) => value.trim().isNotEmpty).join(', ');

    return ExercisePrescription(
      name: exercise.name,
      sets: sets,
      reps: reps,
      rest: rest,
      equipment: exercise.equipment.isEmpty
          ? 'Bodyweight'
          : exercise.equipment.join(' + '),
      target: targets.isEmpty ? 'General fitness' : targets,
      metricLabel: metricLabel,
    );
  }
}

class WorkoutEditorScreen extends StatefulWidget {
  final GeneratedWorkout workout;

  const WorkoutEditorScreen({
    super.key,
    required this.workout,
  });

  @override
  State<WorkoutEditorScreen> createState() => _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends State<WorkoutEditorScreen> {
  late final List<ExercisePrescription> _original;
  late final List<ExercisePrescription> _exercises;
  SafetyProfile? _safetyProfile;
  bool _profileLoading = true;
  bool _openingLibrary = false;

  @override
  void initState() {
    super.initState();
    _original = List<ExercisePrescription>.from(widget.workout.exercises);
    _exercises = List<ExercisePrescription>.from(widget.workout.exercises);
    _loadSafetyProfile();
  }

  Future<void> _loadSafetyProfile() async {
    try {
      final client = Supabase.instance.client;
      final map = await ProfileService(client).currentProfileMap();
      if (!mounted) return;
      setState(() {
        _safetyProfile = SafetyProfile(
          hasLimitation: map?['has_limitation'] == true,
          affectedAreas: _strings(map?['affected_areas']).toSet(),
          warningSigns: _strings(map?['warning_signs']).toSet(),
          notes: map?['limitation_notes']?.toString() ?? '',
        );
        _profileLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _safetyProfile = const SafetyProfile(hasLimitation: false);
        _profileLoading = false;
      });
    }
  }

  List<String> _strings(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  Future<void> _addExercises() async {
    if (_openingLibrary) return;
    setState(() => _openingLibrary = true);

    final selected = await Navigator.push<List<OnlineExercise>>(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseLibraryScreen(
          client: Supabase.instance.client,
          selectionMode: true,
          safetyProfile: _safetyProfile,
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _openingLibrary = false);
    if (selected == null || selected.isEmpty) return;

    final existingNames = _exercises
        .map((exercise) => exercise.name.trim().toLowerCase())
        .toSet();
    final additions = selected
        .where(
          (exercise) =>
              !existingNames.contains(exercise.name.trim().toLowerCase()),
        )
        .map(WorkoutEditorMapper.fromOnlineExercise)
        .toList(growable: false);

    if (additions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Those exercises are already in this workout.')),
      );
      return;
    }

    setState(() => _exercises.addAll(additions));
  }

  void _removeExercise(int index) {
    if (_exercises.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keep at least one exercise in the workout.')),
      );
      return;
    }
    final removed = _exercises[index];
    setState(() => _exercises.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${removed.name} removed.')),
    );
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final exercise = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, exercise);
    });
  }

  void _reset() {
    setState(() {
      _exercises
        ..clear()
        ..addAll(_original);
    });
  }

  void _useWorkout() {
    Navigator.pop(
      context,
      GeneratedWorkout(
        title: widget.workout.title,
        exercises: List<ExercisePrescription>.unmodifiable(_exercises),
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
        title: const Text('Edit workout'),
        actions: [
          TextButton(
            onPressed: _reset,
            child: const Text('RESET'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD9E2EC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.workout.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_exercises.length} exercises • drag to reorder',
                      style: const TextStyle(color: Color(0xFF627D98)),
                    ),
                    if (_profileLoading) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(minHeight: 2),
                    ] else if (_safetyProfile?.hasLimitation == true) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Your saved limitation settings are applied when adding exercises.',
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
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                itemCount: _exercises.length,
                onReorder: _reorder,
                buildDefaultDragHandles: false,
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  return Container(
                    key: ValueKey('workout-editor-${exercise.name}'),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD9E2EC)),
                    ),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              color: Color(0xFF829AB1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF102A43),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                exercise.summary,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF176B87),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${exercise.target} • ${exercise.equipment}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF627D98),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove exercise',
                          onPressed: () => _removeExercise(index),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _profileLoading || _openingLibrary
                      ? null
                      : _addExercises,
                  icon: _openingLibrary
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_rounded),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  label: Text(
                    _openingLibrary ? 'OPENING LIBRARY…' : 'ADD EXERCISES',
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exercises.isEmpty ? null : _useWorkout,
                  icon: const Icon(Icons.check_rounded),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    backgroundColor: const Color(0xFF176B87),
                    foregroundColor: Colors.white,
                  ),
                  label: const Text(
                    'USE THIS WORKOUT',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
