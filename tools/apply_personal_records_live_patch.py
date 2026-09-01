from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding='utf-8')
    if old not in text:
        raise RuntimeError(f'Patch anchor missing in {path}:\n{old[:300]}')
    file.write_text(text.replace(old, new, 1), encoding='utf-8')


replace_once(
    'lib/live_workout_screen.dart',
    "import 'exercise_performance_store.dart';\nimport 'exercise_swap_service.dart';\n",
    "import 'exercise_performance_store.dart';\nimport 'exercise_swap_service.dart';\nimport 'personal_record_celebration.dart';\nimport 'personal_record_engine.dart';\n",
)

replace_once(
    'lib/live_workout_screen.dart',
    """  Future<void> _saveSetPerformance({
    required String exerciseName,
    required int setNumber,
    required int? reps,
    required double? weightKg,
    required int? durationSeconds,
    bool isDropSet = false,
    int? dropNumber,
  }) async {
    try {
      await _performanceStore.saveSet(
        workoutTitle: widget.workout.title,
        exerciseName: exerciseName,
        setNumber: setNumber,
        reps: reps,
        weightKg: weightKg,
        durationSeconds: durationSeconds,
        isDropSet: isDropSet,
        dropNumber: dropNumber,
      );
    } catch (_) {
      // Workout flow continues if local/cloud logging has a temporary issue.
    }
  }
""",
    """  Future<void> _saveSetPerformance({
    required String exerciseName,
    required int setNumber,
    required int? reps,
    required double? weightKg,
    required int? durationSeconds,
    bool isDropSet = false,
    int? dropNumber,
  }) async {
    try {
      final previous = isDropSet
          ? const <ExerciseSetPerformance>[]
          : await _performanceStore.loadForExercise(
              exerciseName,
              limit: 2000,
            );
      final candidate = ExerciseSetPerformance(
        workoutTitle: widget.workout.title,
        exerciseName: exerciseName,
        setNumber: setNumber,
        reps: reps,
        weightKg: weightKg,
        durationSeconds: durationSeconds,
        setType: isDropSet ? 'drop' : 'normal',
        dropNumber: isDropSet ? dropNumber : null,
        performedAt: DateTime.now(),
      );
      final achievements = PersonalRecordEngine.newSetRecords(
        current: candidate,
        previous: previous,
      );

      await _performanceStore.saveSet(
        workoutTitle: widget.workout.title,
        exerciseName: exerciseName,
        setNumber: setNumber,
        reps: reps,
        weightKg: weightKg,
        durationSeconds: durationSeconds,
        isDropSet: isDropSet,
        dropNumber: dropNumber,
      );

      if (mounted && achievements.isNotEmpty) {
        PersonalRecordCelebration.showSnackBar(context, achievements);
      }
    } catch (_) {
      // Workout flow continues if local/cloud logging or PR detection has a
      // temporary issue. The active session must never depend on analytics.
    }
  }
""",
)
