import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/advanced_strength_progression_engine.dart';
import 'package:fitness_app_prototype/exercise_performance_store.dart';
import 'package:fitness_app_prototype/set_effort_store.dart';

ExerciseSetPerformance performance(
  DateTime at, {
  double weight = 60,
  int reps = 10,
}) =>
    ExerciseSetPerformance(
      workoutTitle: 'Upper',
      exerciseName: 'Bench Press',
      setNumber: 1,
      reps: reps,
      weightKg: weight,
      durationSeconds: null,
      performedAt: at,
    );

void main() {
  test('no history builds baseline', () {
    final result = AdvancedStrengthProgressionEngine.recommend(
      exerciseName: 'Bench Press',
      history: const [],
    );
    expect(result.action, AdvancedProgressionAction.buildBaseline);
  });

  test('one exposure does not trigger automatic progression', () {
    final result = AdvancedStrengthProgressionEngine.recommend(
      exerciseName: 'Bench Press',
      history: [performance(DateTime(2026, 9, 1), reps: 12)],
    );
    expect(result.action, AdvancedProgressionAction.buildBaseline);
  });

  test('repeated top-of-range exposure can progress load', () {
    final result = AdvancedStrengthProgressionEngine.recommend(
      exerciseName: 'Bench Press',
      history: [
        performance(DateTime(2026, 9, 1), weight: 60, reps: 12),
        performance(DateTime(2026, 8, 28), weight: 60, reps: 12),
      ],
    );
    expect(result.action, AdvancedProgressionAction.progressLoad);
    expect(result.targetWeightKg, greaterThan(60));
    expect(result.targetReps, lessThan(12));
  });

  test('failure-like RPE and RIR blocks progression', () {
    final at = DateTime(2026, 9, 1);
    final result = AdvancedStrengthProgressionEngine.recommend(
      exerciseName: 'Bench Press',
      history: [
        performance(at, weight: 60, reps: 12),
        performance(DateTime(2026, 8, 28), weight: 60, reps: 12),
      ],
      efforts: [
        SetEffortRecord(
          id: 'hard',
          workoutTitle: 'Upper',
          exerciseName: 'Bench Press',
          setNumber: 1,
          rpe: 10,
          rir: 0,
          recordedAt: at,
        ),
      ],
    );
    expect(result.action, AdvancedProgressionAction.hold);
  });

  test('three stalled exposures trigger plateau reset', () {
    final result = AdvancedStrengthProgressionEngine.recommend(
      exerciseName: 'Bench Press',
      history: [
        performance(DateTime(2026, 9, 1), weight: 60, reps: 10),
        performance(DateTime(2026, 8, 28), weight: 60, reps: 10),
        performance(DateTime(2026, 8, 24), weight: 60, reps: 10),
      ],
    );
    expect(result.action, AdvancedProgressionAction.resetPlateau);
    expect(result.plateauDetected, isTrue);
    expect(result.targetWeightKg, lessThan(60));
  });
}
