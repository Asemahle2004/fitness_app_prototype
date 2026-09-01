import 'training_store.dart';

class WorkoutCalendarMonthStats {
  final int trainedDays;
  final int recoveryDays;
  final int restDays;
  final int workouts;
  final int totalDurationSeconds;
  final int completedSets;
  final double trainingDaysPerWeek;

  const WorkoutCalendarMonthStats({
    required this.trainedDays,
    required this.recoveryDays,
    required this.restDays,
    required this.workouts,
    required this.totalDurationSeconds,
    required this.completedSets,
    required this.trainingDaysPerWeek,
  });
}

class WorkoutCalendarEngine {
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isRecoveryRecord(WorkoutRecord record) =>
      record.title.toLowerCase().startsWith('recovery day');

  static int daysInMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0).day;

  static int leadingBlankCount(DateTime month) =>
      DateTime(month.year, month.month, 1).weekday - DateTime.monday;

  static Map<DateTime, List<WorkoutRecord>> groupByDay(
    Iterable<WorkoutRecord> records,
  ) {
    final result = <DateTime, List<WorkoutRecord>>{};
    for (final record in records) {
      final day = dateOnly(record.completedAt);
      result.putIfAbsent(day, () => <WorkoutRecord>[]).add(record);
    }
    for (final workouts in result.values) {
      workouts.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    }
    return result;
  }

  static List<WorkoutRecord> recordsForDay(
    Iterable<WorkoutRecord> records,
    DateTime day,
  ) {
    final result = records
        .where((record) => sameDay(record.completedAt, day))
        .toList(growable: false)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return result;
  }

  static WorkoutCalendarMonthStats monthStats(
    Iterable<WorkoutRecord> records,
    DateTime month, {
    DateTime? today,
  }) {
    final now = dateOnly(today ?? DateTime.now());
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month, daysInMonth(month));

    final effectiveLast = month.year == now.year && month.month == now.month
        ? now
        : last.isBefore(now)
            ? last
            : first.subtract(const Duration(days: 1));

    final monthRecords = records
        .where((record) {
          final day = dateOnly(record.completedAt);
          return !day.isBefore(first) && !day.isAfter(last);
        })
        .toList(growable: false);

    final grouped = groupByDay(monthRecords);
    final trainedDaySet = <DateTime>{};
    final recoveryOnlyDaySet = <DateTime>{};

    for (final entry in grouped.entries) {
      final hasTraining = entry.value.any((record) => !isRecoveryRecord(record));
      if (hasTraining) {
        trainedDaySet.add(entry.key);
      } else if (entry.value.isNotEmpty) {
        recoveryOnlyDaySet.add(entry.key);
      }
    }

    final elapsedDays = effectiveLast.isBefore(first)
        ? 0
        : effectiveLast.difference(first).inDays + 1;
    final activeDays = trainedDaySet.length + recoveryOnlyDaySet.length;
    final restDays = (elapsedDays - activeDays).clamp(0, elapsedDays).toInt();
    final totalDurationSeconds = monthRecords.fold<int>(
      0,
      (sum, record) => sum + record.durationSeconds,
    );
    final completedSets = monthRecords.fold<int>(
      0,
      (sum, record) => sum + record.completedSets,
    );
    final elapsedWeeks = elapsedDays == 0 ? 0.0 : elapsedDays / 7.0;

    return WorkoutCalendarMonthStats(
      trainedDays: trainedDaySet.length,
      recoveryDays: recoveryOnlyDaySet.length,
      restDays: restDays,
      workouts: monthRecords.length,
      totalDurationSeconds: totalDurationSeconds,
      completedSets: completedSets,
      trainingDaysPerWeek:
          elapsedWeeks == 0 ? 0 : trainedDaySet.length / elapsedWeeks,
    );
  }

  static int longestStreak(Iterable<WorkoutRecord> records) {
    final days = records
        .where((record) => !isRecoveryRecord(record))
        .map((record) => dateOnly(record.completedAt))
        .toSet()
        .toList(growable: false)
      ..sort();
    if (days.isEmpty) return 0;

    var longest = 1;
    var current = 1;
    for (var index = 1; index < days.length; index++) {
      if (days[index].difference(days[index - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  static int latestStreak(Iterable<WorkoutRecord> records) {
    final days = records
        .where((record) => !isRecoveryRecord(record))
        .map((record) => dateOnly(record.completedAt))
        .toSet()
        .toList(growable: false)
      ..sort((a, b) => b.compareTo(a));
    if (days.isEmpty) return 0;

    var streak = 1;
    for (var index = 1; index < days.length; index++) {
      if (days[index - 1].difference(days[index]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
