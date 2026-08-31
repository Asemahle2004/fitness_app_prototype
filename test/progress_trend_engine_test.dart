import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_app_prototype/exercise_performance_store.dart';
import 'package:fitness_app_prototype/progress_trend_engine.dart';

void main() {
  ExerciseSetPerformance set({
    required DateTime at,
    double? weight,
    int? reps,
    int? seconds,
    bool drop = false,
  }) {
    return ExerciseSetPerformance(
      exerciseName: 'Bench Press',
      setNumber: 1,
      reps: reps,
      weightKg: weight,
      durationSeconds: seconds,
      setType: drop ? 'drop' : 'normal',
      dropNumber: drop ? 1 : null,
      performedAt: at,
    );
  }

  test('aggregates load, reps and daily volume by training day', () {
    final series = ProgressTrendEngine.build('Bench Press', [
      set(at: DateTime(2026, 8, 1, 8), weight: 40, reps: 10),
      set(at: DateTime(2026, 8, 1, 8, 5), weight: 45, reps: 8),
      set(at: DateTime(2026, 8, 8, 8), weight: 47.5, reps: 9),
    ]);

    final load = series.forMetric(ProgressMetric.load);
    final reps = series.forMetric(ProgressMetric.reps);
    final volume = series.forMetric(ProgressMetric.volume);

    expect(load.length, 2);
    expect(load.first.value, 45);
    expect(load.last.value, 47.5);
    expect(reps.first.value, 10);
    expect(volume.first.value, 40 * 10 + 45 * 8);
  });

  test('drop sets do not distort normal progression trends', () {
    final series = ProgressTrendEngine.build('Bench Press', [
      set(at: DateTime(2026, 8, 1), weight: 60, reps: 8),
      set(
        at: DateTime(2026, 8, 1, 0, 5),
        weight: 30,
        reps: 20,
        drop: true,
      ),
    ]);

    expect(series.forMetric(ProgressMetric.load).single.value, 60);
    expect(series.forMetric(ProgressMetric.reps).single.value, 8);
    expect(series.forMetric(ProgressMetric.volume).single.value, 480);
  });

  test('builds timed performance and percent change', () {
    final series = ProgressTrendEngine.build('Bench Press', [
      set(at: DateTime(2026, 8, 1), seconds: 60),
      set(at: DateTime(2026, 8, 8), seconds: 75),
    ]);

    final time = series.forMetric(ProgressMetric.time);
    expect(time.map((point) => point.value), [60, 75]);
    expect(ProgressTrendEngine.percentChange(time), closeTo(25, 0.001));
  });

  test('case-insensitive exercise matching excludes other exercises', () {
    final records = [
      set(at: DateTime(2026, 8, 1), weight: 50, reps: 8),
      ExerciseSetPerformance(
        exerciseName: 'Squat',
        setNumber: 1,
        reps: 10,
        weightKg: 100,
        durationSeconds: null,
        performedAt: DateTime(2026, 8, 2),
      ),
    ];

    final series = ProgressTrendEngine.build('bench press', records);
    expect(series.forMetric(ProgressMetric.load).single.value, 50);
  });
}
