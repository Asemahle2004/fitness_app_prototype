import 'exercise_performance_store.dart';
import 'training_store.dart';

class WeeklyTrainingPoint {
  final DateTime weekStart;
  final int workouts;
  final int trainingSeconds;
  final int completedSets;
  final double loggedVolumeKg;

  const WeeklyTrainingPoint({
    required this.weekStart,
    required this.workouts,
    required this.trainingSeconds,
    required this.completedSets,
    required this.loggedVolumeKg,
  });

  int get trainingMinutes => (trainingSeconds / 60).round();
  bool get active => workouts > 0;
}

class ExerciseFrequencyInsight {
  final String exerciseName;
  final int appearances;

  const ExerciseFrequencyInsight({
    required this.exerciseName,
    required this.appearances,
  });
}

class ProgressInsights {
  final List<WeeklyTrainingPoint> weeklySeries;
  final List<ExerciseFrequencyInsight> mostTrainedExercises;
  final int currentWeekWorkouts;
  final int previousWeekWorkouts;
  final int currentWeekMinutes;
  final int previousWeekMinutes;
  final double currentWeekVolumeKg;
  final double previousWeekVolumeKg;
  final int activeWeeks;
  final int weeklyStreak;

  const ProgressInsights({
    required this.weeklySeries,
    required this.mostTrainedExercises,
    required this.currentWeekWorkouts,
    required this.previousWeekWorkouts,
    required this.currentWeekMinutes,
    required this.previousWeekMinutes,
    required this.currentWeekVolumeKg,
    required this.previousWeekVolumeKg,
    required this.activeWeeks,
    required this.weeklyStreak,
  });

  int get trackedWeeks => weeklySeries.length;

  int get consistencyPercent {
    if (trackedWeeks == 0) return 0;
    return ((activeWeeks / trackedWeeks) * 100)
        .round()
        .clamp(0, 100)
        .toInt();
  }

  bool get hasTrainingHistory =>
      weeklySeries.any((week) => week.workouts > 0) ||
      mostTrainedExercises.isNotEmpty;

  double? get workoutChangePercent => ProgressInsightsEngine.percentChange(
        currentWeekWorkouts.toDouble(),
        previousWeekWorkouts.toDouble(),
      );

  double? get minutesChangePercent => ProgressInsightsEngine.percentChange(
        currentWeekMinutes.toDouble(),
        previousWeekMinutes.toDouble(),
      );

  double? get volumeChangePercent => ProgressInsightsEngine.percentChange(
        currentWeekVolumeKg,
        previousWeekVolumeKg,
      );
}

class ProgressInsightsEngine {
  static const int defaultWeeks = 8;

  static ProgressInsights analyse({
    required List<WorkoutRecord> workouts,
    required List<ExerciseSetPerformance> sets,
    DateTime? now,
    int weeks = defaultWeeks,
  }) {
    final safeWeeks = weeks.clamp(2, 16).toInt();
    final reference = now ?? DateTime.now();
    final currentWeekStart = startOfWeek(reference);
    final oldestWeekStart = currentWeekStart.subtract(
      Duration(days: 7 * (safeWeeks - 1)),
    );

    final workoutBuckets = <DateTime, List<WorkoutRecord>>{};
    for (final workout in workouts) {
      final week = startOfWeek(workout.completedAt);
      if (week.isBefore(oldestWeekStart) || week.isAfter(currentWeekStart)) {
        continue;
      }
      workoutBuckets.putIfAbsent(week, () => <WorkoutRecord>[]).add(workout);
    }

    final setBuckets = <DateTime, List<ExerciseSetPerformance>>{};
    for (final set in sets) {
      final week = startOfWeek(set.performedAt);
      if (week.isBefore(oldestWeekStart) || week.isAfter(currentWeekStart)) {
        continue;
      }
      setBuckets.putIfAbsent(week, () => <ExerciseSetPerformance>[]).add(set);
    }

    final weeklySeries = <WeeklyTrainingPoint>[];
    for (var index = safeWeeks - 1; index >= 0; index -= 1) {
      final weekStart = currentWeekStart.subtract(Duration(days: 7 * index));
      final weekWorkouts = workoutBuckets[weekStart] ?? const <WorkoutRecord>[];
      final weekSets = setBuckets[weekStart] ?? const <ExerciseSetPerformance>[];
      weeklySeries.add(
        WeeklyTrainingPoint(
          weekStart: weekStart,
          workouts: weekWorkouts.length,
          trainingSeconds: weekWorkouts.fold<int>(
            0,
            (sum, workout) => sum + workout.durationSeconds,
          ),
          completedSets: weekWorkouts.fold<int>(
            0,
            (sum, workout) => sum + workout.completedSets,
          ),
          loggedVolumeKg: weekSets.fold<double>(
            0,
            (sum, set) => sum + set.volumeKg,
          ),
        ),
      );
    }

    final current = weeklySeries.last;
    final previous = weeklySeries[weeklySeries.length - 2];
    final activeWeeks = weeklySeries.where((week) => week.active).length;

    var weeklyStreak = 0;
    for (final week in weeklySeries.reversed) {
      if (!week.active) break;
      weeklyStreak += 1;
    }

    return ProgressInsights(
      weeklySeries: List<WeeklyTrainingPoint>.unmodifiable(weeklySeries),
      mostTrainedExercises: List<ExerciseFrequencyInsight>.unmodifiable(
        _topExercises(workouts: workouts, sets: sets),
      ),
      currentWeekWorkouts: current.workouts,
      previousWeekWorkouts: previous.workouts,
      currentWeekMinutes: current.trainingMinutes,
      previousWeekMinutes: previous.trainingMinutes,
      currentWeekVolumeKg: current.loggedVolumeKg,
      previousWeekVolumeKg: previous.loggedVolumeKg,
      activeWeeks: activeWeeks,
      weeklyStreak: weeklyStreak,
    );
  }

  static List<ExerciseFrequencyInsight> _topExercises({
    required List<WorkoutRecord> workouts,
    required List<ExerciseSetPerformance> sets,
  }) {
    final counts = <String, int>{};
    final labels = <String, String>{};

    if (sets.isNotEmpty) {
      for (final set in sets) {
        final key = normaliseName(set.exerciseName);
        if (key.isEmpty) continue;
        labels.putIfAbsent(key, () => set.exerciseName.trim());
        counts[key] = (counts[key] ?? 0) + 1;
      }
    } else {
      for (final workout in workouts) {
        for (final exercise in workout.exercises.toSet()) {
          final key = normaliseName(exercise);
          if (key.isEmpty) continue;
          labels.putIfAbsent(key, () => exercise.trim());
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }

    final ranked = counts.entries.toList(growable: false)
      ..sort((a, b) {
        final count = b.value.compareTo(a.value);
        if (count != 0) return count;
        return (labels[a.key] ?? a.key).compareTo(labels[b.key] ?? b.key);
      });

    return ranked
        .take(3)
        .map(
          (entry) => ExerciseFrequencyInsight(
            exerciseName: labels[entry.key] ?? entry.key,
            appearances: entry.value,
          ),
        )
        .toList(growable: false);
  }

  static DateTime startOfWeek(DateTime value) {
    final local = DateTime(value.year, value.month, value.day);
    return local.subtract(Duration(days: local.weekday - DateTime.monday));
  }

  static String normaliseName(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static double? percentChange(double current, double previous) {
    if (previous == 0) {
      if (current == 0) return 0;
      return null;
    }
    return ((current - previous) / previous) * 100;
  }
}
