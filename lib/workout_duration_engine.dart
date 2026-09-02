import 'exercise_intelligence_engine.dart';
import 'session_preparation_engine.dart';
import 'workout_engine.dart';

class WorkoutDurationEstimate {
  final int workingSeconds;
  final int warmUpSeconds;
  final int coolDownSeconds;

  const WorkoutDurationEstimate({
    required this.workingSeconds,
    required this.warmUpSeconds,
    required this.coolDownSeconds,
  });

  int get totalSeconds => workingSeconds + warmUpSeconds + coolDownSeconds;
  int get totalMinutes => (totalSeconds / 60).ceil();

  String get summary =>
      'about $totalMinutes min • ${(warmUpSeconds / 60).ceil()} min warm-up • ${(coolDownSeconds / 60).ceil()} min cool-down';
}

class WorkoutDurationEngine {
  const WorkoutDurationEngine._();

  static WorkoutDurationEstimate estimate(GeneratedWorkout workout) {
    final preparation = SessionPreparationEngine.forWorkout(workout);
    return WorkoutDurationEstimate(
      workingSeconds:
          ExerciseIntelligenceEngine.estimateWorkoutSeconds(workout.exercises),
      warmUpSeconds: preparation.warmUpSeconds,
      coolDownSeconds: preparation.coolDownSeconds,
    );
  }

  static int targetMinutes(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    return int.tryParse(match?.group(0) ?? '') ?? 45;
  }

  static bool fitsTarget(
    GeneratedWorkout workout,
    String target, {
    int toleranceMinutes = 5,
  }) {
    final estimate = WorkoutDurationEngine.estimate(workout);
    return estimate.totalMinutes <= targetMinutes(target) + toleranceMinutes;
  }
}
