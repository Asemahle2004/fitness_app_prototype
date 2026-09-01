import 'rest_timer_coach.dart';
import 'strength_adaptation_cache.dart';
import 'workout_engine.dart';

/// Legacy compatibility wrapper now used as a lightweight final preparation
/// layer before safety/fatigue adaptation.
///
/// Warm-up and cool-down remain owned by SessionPreparationEngine. This layer
/// only personalizes working-set rest from movement demands and the current
/// strength adaptation state; it never inserts fake warm-up exercises.
class WorkoutStructureEnhancer {
  static GeneratedWorkout enhance(
    GeneratedWorkout base, {
    required String sessionDuration,
    required String location,
  }) {
    final adaptation = StrengthAdaptationCache.current;
    return GeneratedWorkout(
      title: base.title,
      exercises: base.exercises
          .map((exercise) {
            final rest = RestTimerCoach.recommend(
              exercise: exercise,
              adaptation: adaptation,
            );
            return exercise.copyWith(
              rest: RestTimerCoach.formatSeconds(rest.seconds),
            );
          })
          .toList(growable: false),
    );
  }
}
