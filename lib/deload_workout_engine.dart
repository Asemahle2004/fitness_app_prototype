import 'adaptive_strength_engine.dart';
import 'rest_timer_coach.dart';
import 'workout_engine.dart';

class DeloadWorkoutEngine {
  const DeloadWorkoutEngine._();

  static GeneratedWorkout adapt(
    GeneratedWorkout workout,
    StrengthAdaptationRecommendation? adaptation,
  ) {
    if (adaptation == null) return workout;
    final action = adaptation.action;
    if (action != StrengthAdaptationAction.deload &&
        action != StrengthAdaptationAction.reduce) {
      return workout;
    }

    final isDeload = action == StrengthAdaptationAction.deload;
    final setMultiplier = isDeload ? 0.65 : 0.80;
    final exercises = workout.exercises.map((exercise) {
      final targetSets = (exercise.sets * setMultiplier).ceil().clamp(1, exercise.sets);
      final rest = RestTimerCoach.recommend(
        exercise: exercise,
        adaptation: adaptation,
      );
      return exercise.copyWith(
        sets: targetSets,
        rest: RestTimerCoach.formatSeconds(rest.seconds),
        clearDropSet: true,
        clearSuperset: isDeload,
      );
    }).toList(growable: false);

    final suffix = isDeload ? ' • Deload' : ' • Reduced load';
    return GeneratedWorkout(
      title: workout.title.contains(suffix) ? workout.title : '${workout.title}$suffix',
      exercises: exercises,
    );
  }
}
