import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/motivation_engine.dart';
import 'package:fitness_app_prototype/run_tracking_store.dart';
import 'package:fitness_app_prototype/training_store.dart';

WorkoutRecord workout(DateTime at, {int sets = 12}) => WorkoutRecord(
      title: 'Workout',
      completedAt: at,
      durationSeconds: 1800,
      completedSets: sets,
      exercises: const ['Squat', 'Press'],
    );

RunRecord run(DateTime at, double km) => RunRecord(
      id: 'run_${at.microsecondsSinceEpoch}',
      startedAt: at,
      durationSeconds: (km * 360).round(),
      distanceMeters: km * 1000,
    );

void main() {
  test('10 workouts unlocks the 10-workout milestone', () {
    final workouts = List.generate(
      10,
      (index) => workout(DateTime(2026, 8, 1).add(Duration(days: index))),
    );
    final achievements = MotivationEngine.achievements(
      workouts: workouts,
      runs: const [],
    );
    final milestone = achievements.firstWhere(
      (item) => item.type == LeanItAchievementType.workouts10,
    );
    expect(milestone.unlocked, isTrue);
  });

  test('a 5K run unlocks the 5K achievement', () {
    final achievements = MotivationEngine.achievements(
      workouts: const [],
      runs: [run(DateTime(2026, 9, 1), 5.2)],
    );
    expect(
      achievements
          .firstWhere((item) => item.type == LeanItAchievementType.run5k)
          .unlocked,
      isTrue,
    );
  });

  test('weekly review combines workouts and running minutes', () {
    final review = MotivationEngine.weeklyReview(
      now: DateTime(2026, 9, 2),
      workouts: [workout(DateTime(2026, 9, 1))],
      runs: [run(DateTime(2026, 9, 2), 5)],
    );
    expect(review.workouts, 1);
    expect(review.runningSessions, 1);
    expect(review.runningKm, closeTo(5, 0.01));
    expect(review.trainingMinutes, greaterThan(30));
  });

  test('wrapped includes annual workouts runs and distance', () {
    final wrapped = MotivationEngine.wrapped(
      year: 2026,
      workouts: [workout(DateTime(2026, 3, 1), sets: 10)],
      runs: [run(DateTime(2026, 4, 1), 10)],
    );
    expect(wrapped.workouts, 1);
    expect(wrapped.completedSets, 10);
    expect(wrapped.runs, 1);
    expect(wrapped.runningKm, closeTo(10, 0.01));
    expect(wrapped.activeWeeks, 2);
  });
}
