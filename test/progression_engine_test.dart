import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/exercise_performance_store.dart';
import 'package:fitness_app_prototype/progression_engine.dart';
import 'package:fitness_app_prototype/workout_engine.dart';

ExercisePrescription exercise({
  String reps = '8–12',
  String equipment = 'Dumbbells',
}) {
  return ExercisePrescription(
    name: 'Test Press',
    sets: 3,
    reps: reps,
    rest: '60 sec',
    equipment: equipment,
    target: 'Chest',
  );
}

ExerciseSetPerformance previous({
  int? reps,
  double? weight,
  int? duration,
}) {
  return ExerciseSetPerformance(
    exerciseName: 'Test Press',
    setNumber: 3,
    reps: reps,
    weightKg: weight,
    durationSeconds: duration,
    performedAt: DateTime(2026, 8, 31),
  );
}

void main() {
  test('adds one rep before increasing load', () {
    final result = ProgressionEngine.suggest(
      exercise: exercise(),
      previous: previous(reps: 10, weight: 20),
    );

    expect(result?.targetWeightKg, 20);
    expect(result?.targetReps, 11);
  });

  test('raises load after reaching top of rep range', () {
    final result = ProgressionEngine.suggest(
      exercise: exercise(),
      previous: previous(reps: 12, weight: 20),
    );

    expect(result?.targetWeightKg, 22);
    expect(result?.targetReps, 8);
  });

  test('progresses bodyweight reps conservatively', () {
    final result = ProgressionEngine.suggest(
      exercise: exercise(equipment: 'Bodyweight'),
      previous: previous(reps: 9),
    );

    expect(result?.targetWeightKg, isNull);
    expect(result?.targetReps, 10);
  });

  test('progresses timed work with a small increase', () {
    final result = ProgressionEngine.suggest(
      exercise: exercise(reps: '30–60 sec', equipment: 'Bodyweight'),
      previous: previous(duration: 40),
    );

    expect(result?.targetDurationSeconds, 45);
  });
}
