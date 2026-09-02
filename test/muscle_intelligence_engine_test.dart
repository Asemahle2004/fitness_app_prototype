import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/exercise_performance_store.dart';
import 'package:fitness_app_prototype/muscle_intelligence_engine.dart';
import 'package:fitness_app_prototype/set_effort_store.dart';

ExerciseSetPerformance setAt(
  DateTime at, {
  String exercise = 'Bench Press',
  double weight = 60,
  int reps = 8,
  int setNumber = 1,
}) {
  return ExerciseSetPerformance(
    workoutTitle: 'Strength',
    exerciseName: exercise,
    setNumber: setNumber,
    reps: reps,
    weightKg: weight,
    durationSeconds: null,
    performedAt: at,
  );
}

void main() {
  final now = DateTime(2026, 9, 2, 12);

  test('recent bench work lowers chest recovery', () {
    final report = MuscleIntelligenceEngine.analyse(
      now: now,
      sets: [
        setAt(now.subtract(const Duration(hours: 8)), setNumber: 1),
        setAt(now.subtract(const Duration(hours: 8)), setNumber: 2),
        setAt(now.subtract(const Duration(hours: 8)), setNumber: 3),
      ],
    );
    final chest = report.statusFor(TrainingMuscle.chest);
    expect(chest.currentWeekSets, 3);
    expect(chest.recoveryPercent, lessThan(60));
  });

  test('old work recovers close to full', () {
    final report = MuscleIntelligenceEngine.analyse(
      now: now,
      sets: [setAt(now.subtract(const Duration(days: 5)))],
    );
    final chest = report.statusFor(TrainingMuscle.chest);
    expect(chest.recoveryPercent, greaterThanOrEqualTo(95));
  });

  test('hard set effort further reduces muscle recovery', () {
    final at = now.subtract(const Duration(hours: 24));
    final baseline = MuscleIntelligenceEngine.analyse(
      now: now,
      sets: [setAt(at)],
    ).statusFor(TrainingMuscle.chest);
    final hard = MuscleIntelligenceEngine.analyse(
      now: now,
      sets: [setAt(at)],
      efforts: [
        SetEffortRecord(
          id: 'e1',
          workoutTitle: 'Strength',
          exerciseName: 'Bench Press',
          setNumber: 1,
          rpe: 10,
          rir: 0,
          recordedAt: at,
        ),
      ],
    ).statusFor(TrainingMuscle.chest);
    expect(hard.recoveryPercent, lessThan(baseline.recoveryPercent));
  });

  test('current and previous Monday weeks are separated', () {
    final report = MuscleIntelligenceEngine.analyse(
      now: now,
      sets: [
        setAt(DateTime(2026, 9, 1, 10)),
        setAt(DateTime(2026, 8, 25, 10), setNumber: 2),
        setAt(DateTime(2026, 8, 26, 10), setNumber: 3),
      ],
    );
    final chest = report.statusFor(TrainingMuscle.chest);
    expect(chest.currentWeekSets, 1);
    expect(chest.previousWeekSets, 2);
  });
}
