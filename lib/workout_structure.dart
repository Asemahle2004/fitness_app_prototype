import 'workout_engine.dart';

/// Legacy compatibility wrapper.
///
/// Warm-up, mobility, activation, cool-down and stretching are now generated
/// by SessionPreparationEngine and guided by LiveWorkoutScreen. Keeping the
/// previous structure enhancer active would duplicate those phases and would
/// also create generic placeholder items such as "Dynamic Warm-Up" that do not
/// correspond to a real exercise-library media record.
class WorkoutStructureEnhancer {
  static GeneratedWorkout enhance(
    GeneratedWorkout base, {
    required String sessionDuration,
    required String location,
  }) {
    return base;
  }
}
