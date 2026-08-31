import 'package:fitness_app_prototype/training_store.dart';
import 'package:fitness_app_prototype/workout_calendar_engine.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutRecord workout(
  DateTime at, {
  String title = 'Workout',
  int duration = 1800,
  int sets = 10,
}) {
  return WorkoutRecord(
    title: title,
    completedAt: at,
    durationSeconds: duration,
    completedSets: sets,
    exercises: const ['Squat', 'Row'],
  );
}

void main() {
  test('groups multiple workouts on the same calendar day', () {
    final records = [
      workout(DateTime(2026, 8, 10, 8), title: 'AM'),
      workout(DateTime(2026, 8, 10, 18), title: 'PM'),
      workout(DateTime(2026, 8, 12, 9)),
    ];

    final grouped = WorkoutCalendarEngine.groupByDay(records);
    expect(grouped.length, 2);
    expect(grouped[DateTime(2026, 8, 10)]!.length, 2);
    expect(grouped[DateTime(2026, 8, 10)]!.first.title, 'PM');
  });

  test('current month rest days exclude future dates', () {
    final records = [
      workout(DateTime(2026, 8, 1)),
      workout(DateTime(2026, 8, 3)),
      workout(DateTime(2026, 8, 3, 18)),
    ];

    final stats = WorkoutCalendarEngine.monthStats(
      records,
      DateTime(2026, 8),
      today: DateTime(2026, 8, 5, 15),
    );

    expect(stats.trainedDays, 2);
    expect(stats.restDays, 3);
    expect(stats.workouts, 3);
    expect(stats.totalDurationSeconds, 5400);
    expect(stats.completedSets, 30);
  });

  test('past month counts all untrained days as rest days', () {
    final stats = WorkoutCalendarEngine.monthStats(
      [workout(DateTime(2026, 7, 1)), workout(DateTime(2026, 7, 31))],
      DateTime(2026, 7),
      today: DateTime(2026, 8, 10),
    );

    expect(stats.trainedDays, 2);
    expect(stats.restDays, 29);
  });

  test('streak calculations cross month boundaries', () {
    final records = [
      workout(DateTime(2026, 7, 30)),
      workout(DateTime(2026, 7, 31)),
      workout(DateTime(2026, 8, 1)),
      workout(DateTime(2026, 8, 5)),
      workout(DateTime(2026, 8, 6)),
    ];

    expect(WorkoutCalendarEngine.longestStreak(records), 3);
    expect(WorkoutCalendarEngine.latestStreak(records), 2);
  });

  test('monday-first calendar leading blanks are correct', () {
    expect(WorkoutCalendarEngine.leadingBlankCount(DateTime(2026, 6)), 0);
    expect(WorkoutCalendarEngine.leadingBlankCount(DateTime(2026, 8)), 5);
  });

  test('recordsForDay matches only the selected date', () {
    final records = [
      workout(DateTime(2026, 8, 12, 8), title: 'First'),
      workout(DateTime(2026, 8, 12, 19), title: 'Second'),
      workout(DateTime(2026, 8, 13, 8), title: 'Other'),
    ];

    final result = WorkoutCalendarEngine.recordsForDay(
      records,
      DateTime(2026, 8, 12),
    );
    expect(result.length, 2);
    expect(result.first.title, 'Second');
  });
}