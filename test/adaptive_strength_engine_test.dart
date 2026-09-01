import 'package:fitness_app_prototype/adaptive_strength_engine.dart';
import 'package:fitness_app_prototype/exercise_performance_store.dart';
import 'package:fitness_app_prototype/training_store.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutRecord workout(
  DateTime date, {
  String? effort,
  int sets = 8,
  int minutes = 45,
}) {
  return WorkoutRecord(
    title: 'Strength',
    completedAt: date,
    durationSeconds: minutes * 60,
    completedSets: sets,
    exercises: const ['Bench Press', 'Row'],
    perceivedEffort: effort,
  );
}

ExerciseSetPerformance set(
  String exercise,
  DateTime date, {
  double weight = 50,
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
    performedAt: date,
  );
}

List<ExerciseSetPerformance> weekSets(
  DateTime date, {
  double benchWeight = 50,
  double rowWeight = 40,
  int countPerExercise = 4,
}) {
  final result = <ExerciseSetPerformance>[];
  for (var i = 0; i < countPerExercise; i += 1) {
    result.add(set('Bench Press', date, weight: benchWeight, setNumber: i + 1));
    result.add(set('Row', date, weight: rowWeight, setNumber: i + 1));
  }
  return result;
}

ReadinessRecord readiness(DateTime date, double value) {
  return ReadinessRecord(
    recordedAt: date,
    sleep: value,
    energy: value,
    soreness: 6 - value,
    stress: 6 - value,
  );
}

void main() {
  final now = DateTime(2026, 9, 2, 12);

  test('builds baseline before automatic progression with little history', () {
    final result = StrengthAdaptationEngine.analyse(
      workouts: [workout(DateTime(2026, 9, 1))],
      sets: [
        set('Bench Press', DateTime(2026, 9, 1)),
        set('Bench Press', DateTime(2026, 9, 1), setNumber: 2),
      ],
      readiness: readiness(DateTime(2026, 9, 2, 8), 4),
      now: now,
    );

    expect(result.action, StrengthAdaptationAction.buildBaseline);
    expect(result.allowsProgression, isFalse);
  });

  test('very low fresh readiness triggers deload when history exists', () {
    final sets = [
      ...weekSets(DateTime(2026, 8, 26)),
      ...weekSets(DateTime(2026, 9, 1)),
    ];
    final result = StrengthAdaptationEngine.analyse(
      workouts: [
        workout(DateTime(2026, 8, 26)),
        workout(DateTime(2026, 9, 1)),
      ],
      sets: sets,
      readiness: readiness(DateTime(2026, 9, 2, 8), 1),
      now: now,
    );

    expect(result.action, StrengthAdaptationAction.deload);
    expect(result.readinessUsed, isTrue);
    expect(result.suggestedLoadMultiplier, 0.90);
    expect(result.suggestedVolumeMultiplier, 0.65);
  });

  test('two hard sessions with sustained workload trigger deload', () {
    final result = StrengthAdaptationEngine.analyse(
      workouts: [
        workout(DateTime(2026, 8, 27)),
        workout(DateTime(2026, 9, 1), effort: 'hard'),
        workout(DateTime(2026, 9, 2, 8), effort: 'hard'),
      ],
      sets: [
        ...weekSets(DateTime(2026, 8, 27)),
        ...weekSets(DateTime(2026, 9, 1)),
      ],
      readiness: readiness(DateTime(2026, 9, 2, 9), 4),
      now: now,
    );

    expect(result.action, StrengthAdaptationAction.deload);
    expect(result.recentHardSessions, 2);
  });

  test('large weekly workload spike reduces rather than progresses', () {
    final previous = weekSets(DateTime(2026, 8, 27), countPerExercise: 3);
    final current = weekSets(
      DateTime(2026, 9, 1),
      benchWeight: 55,
      rowWeight: 45,
      countPerExercise: 5,
    );
    final result = StrengthAdaptationEngine.analyse(
      workouts: [
        workout(DateTime(2026, 8, 27)),
        workout(DateTime(2026, 9, 1)),
        workout(DateTime(2026, 9, 2, 8)),
      ],
      sets: [...previous, ...current],
      readiness: readiness(DateTime(2026, 9, 2, 9), 4),
      now: now,
    );

    expect(result.action, StrengthAdaptationAction.reduce);
    expect(result.currentWeekSets, greaterThan(result.previousWeekSets));
  });

  test('multiple declining exercises trigger deload under meaningful load', () {
    final previous = weekSets(
      DateTime(2026, 8, 27),
      benchWeight: 60,
      rowWeight: 50,
    );
    final current = weekSets(
      DateTime(2026, 9, 1),
      benchWeight: 50,
      rowWeight: 40,
    );
    final result = StrengthAdaptationEngine.analyse(
      workouts: [
        workout(DateTime(2026, 8, 27)),
        workout(DateTime(2026, 9, 1)),
      ],
      sets: [...previous, ...current],
      readiness: readiness(DateTime(2026, 9, 2, 9), 4),
      now: now,
    );

    expect(result.decliningExercises, 2);
    expect(result.action, StrengthAdaptationAction.deload);
  });

  test('stable load and improving performance allow conservative progression', () {
    final previous = weekSets(
      DateTime(2026, 8, 27),
      benchWeight: 50,
      rowWeight: 40,
    );
    final current = weekSets(
      DateTime(2026, 9, 1),
      benchWeight: 52.5,
      rowWeight: 42.5,
    );
    final result = StrengthAdaptationEngine.analyse(
      workouts: [
        workout(DateTime(2026, 8, 27)),
        workout(DateTime(2026, 9, 1), effort: 'about_right'),
      ],
      sets: [...previous, ...current],
      readiness: readiness(DateTime(2026, 9, 2, 9), 4.5),
      now: now,
    );

    expect(result.improvingExercises, 2);
    expect(result.action, StrengthAdaptationAction.progress);
    expect(result.allowsProgression, isTrue);
  });

  test('stale readiness is ignored', () {
    final previous = weekSets(DateTime(2026, 8, 27));
    final current = weekSets(DateTime(2026, 9, 1), benchWeight: 52.5, rowWeight: 42);
    final result = StrengthAdaptationEngine.analyse(
      workouts: [
        workout(DateTime(2026, 8, 27)),
        workout(DateTime(2026, 9, 1)),
      ],
      sets: [...previous, ...current],
      readiness: readiness(DateTime(2026, 8, 29), 1),
      now: now,
    );

    expect(result.readinessUsed, isFalse);
    expect(result.action, isNot(StrengthAdaptationAction.deload));
  });
}
