import 'rest_timer_coach.dart';
import 'strength_adaptation_cache.dart';
import 'training_context_cache.dart';
import 'training_context_engine.dart';
import 'workout_engine.dart';

/// Lightweight final preparation layer before safety/fatigue adaptation.
///
/// Warm-up and cool-down remain owned by SessionPreparationEngine. This layer
/// personalizes working-set rest and applies an optional temporary context such
/// as quiet training, travel, small space or "not feeling 100%". Temporary
/// context never changes the permanent training profile.
class WorkoutStructureEnhancer {
  static GeneratedWorkout enhance(
    GeneratedWorkout base, {
    required String sessionDuration,
    required String location,
  }) {
    final adaptation = StrengthAdaptationCache.current;
    var prepared = GeneratedWorkout(
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

    final context = TrainingContextCache.current;
    if (context != null && context.mode != TrainingContextMode.normal) {
      prepared = TrainingContextEngine.adapt(
        prepared,
        mode: context.mode,
        readinessScore: context.readinessScore,
      ).workout;
    }
    return prepared;
  }
}
