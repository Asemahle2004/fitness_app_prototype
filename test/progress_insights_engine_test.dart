import 'package:fitness_app_prototype/exercise_performance_store.dart';
import 'package:fitness_app_prototype/progress_insights_engine.dart';
import 'package:fitness_app_prototype/training_store.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutRecord workout(
  DateTime completedAt, {
  String title = 'Strength',
  int minutes = 45,
  int sets = 12,
  List<String> exercises = const <String>['Bench Press', 'Cable Row'],
}) {
  return WorkoutRecord(
    title: title,
    completedAt: completedAt,
    durationSeconds: minutes * 60,
    completedSets: sets,
    exercises: exercises,
  );
}

ExerciseSetPerformance setLog(
  String exerciseName,
  DateTime performedAt, {
  int reps = 10,
  double weightKg = 20,
}) {
  return ExerciseSetPerformance(
    exerciseName: exerciseName,
    setNumber: 1,
    reps: reps,
    weightKg: weightKg,
    durationSeconds: null,
    performedAt: performedAt,
  );
}

void main() {
  group('ProgressInsightsEngine', () {
    final now = DateTime(2026, 9, 2, 12);

    test('compares the current calendar week with the previous week', () {
      final insights = ProgressInsightsEngine.analyse(
        now: now,
        workouts: <WorkoutRecord>[
          workout(DateTime(2026, 9, 1), minutes: 50),
          workout(DateTime(2026, 9, 2), minutes: 40),
          workout(DateTime(2026, 8, 26), minutes: 60),
        ],
        sets: const <ExerciseSetPerformance>[],
      );

      expect(insights.weeklySeries, hasLength(8));
      expect(insights.currentWeekWorkouts, 2);
      expect(insights.previousWeekWorkouts, 1);
      expect(insights.currentWeekMinutes, 90);
      expect(insights.previousWeekMinutes, 60);
      expect(insights.workoutChangePercent, 100);
      expect(insights.minutesChangePercent, 50);
    });

    test('calculates active-week consistency and consecutive weekly streak', () {
      final insights = ProgressInsightsEngine.analyse(
        now: now,
        workouts: <WorkoutRecord>[
          workout(DateTime(2026, 9, 1)),
          workout(DateTime(2026, 8, 25)),
          workout(DateTime(2026, 8, 18)),
          workout(DateTime(2026, 7, 28)),
        ],
        sets: const <ExerciseSetPerformance>[],
      );

      expect(insights.activeWeeks, 4);
      expect(insights.consistencyPercent, 50);
      expect(insights.weeklyStreak, 3);
    });

    test('calculates strength-volume change from logged sets', () {
      final insights = ProgressInsightsEngine.analyse(
        now: now,
        workouts: <WorkoutRecord>[
          workout(DateTime(2026, 9, 1)),
          workout(DateTime(2026, 8, 25)),
        ],
        sets: <ExerciseSetPerformance>[
          setLog('Bench Press', DateTime(2026, 9, 1), weightKg: 20, reps: 10),
          setLog('Cable Row', DateTime(2026, 9, 1), weightKg: 20, reps: 10),
          setLog('Bench Press', DateTime(2026, 8, 25), weightKg: 20, reps: 10),
        ],
      );

      expect(insights.currentWeekVolumeKg, 400);
      expect(insights.previousWeekVolumeKg, 200);
      expect(insights.volumeChangePercent, 100);
    });

    test('ranks most-trained exercises from logged set frequency', () {
      final insights = ProgressInsightsEngine.analyse(
        now: now,
        workouts: <WorkoutRecord>[
          workout(DateTime(2026, 9, 1)),
        ],
        sets: <ExerciseSetPerformance>[
          setLog('Cable Row', DateTime(2026, 9, 1)),
          setLog('Cable Row', DateTime(2026, 9, 1, 13)),
          setLog('Cable Row', DateTime(2026, 9, 1, 14)),
          setLog('Bench Press', DateTime(2026, 9, 1, 15)),
          setLog('Bench Press', DateTime(2026, 9, 1, 16)),
          setLog('Lateral Raise', DateTime(2026, 9, 1, 17)),
        ],
      );

      expect(insights.mostTrainedExercises, hasLength(3));
      expect(insights.mostTrainedExercises.first.exerciseName, 'Cable Row');
      expect(insights.mostTrainedExercises.first.appearances, 3);
      expect(insights.mostTrainedExercises[1].exerciseName, 'Bench Press');
      expect(insights.mostTrainedExercises[1].appearances, 2);
    });

    test('handles no history and a new active week without invalid percentages', () {
      final empty = ProgressInsightsEngine.analyse(
        now: now,
        workouts: const <WorkoutRecord>[],
        sets: const <ExerciseSetPerformance>[],
      );
      expect(empty.hasTrainingHistory, isFalse);
      expect(empty.consistencyPercent, 0);
      expect(empty.workoutChangePercent, 0);

      final newWeek = ProgressInsightsEngine.analyse(
        now: now,
        workouts: <WorkoutRecord>[workout(DateTime(2026, 9, 1))],
        sets: const <ExerciseSetPerformance>[],
      );
      expect(newWeek.currentWeekWorkouts, 1);
      expect(newWeek.previousWeekWorkouts, 0);
      expect(newWeek.workoutChangePercent, isNull);
    });

    test('uses Monday as the beginning of a training week', () {
      expect(
        ProgressInsightsEngine.startOfWeek(DateTime(2026, 9, 2, 23, 30)),
        DateTime(2026, 8, 31),
      );
      expect(
        ProgressInsightsEngine.startOfWeek(DateTime(2026, 8, 30)),
        DateTime(2026, 8, 24),
      );
    });
  });
}
