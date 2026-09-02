import 'run_tracking_store.dart';
import 'training_store.dart';

enum LeanItAchievementType {
  firstWorkout,
  firstRun,
  workouts10,
  workouts25,
  workouts50,
  workouts100,
  run5k,
  run10k,
  halfMarathon,
  marathon,
  fourWeekConsistency,
  eightWeekConsistency,
}

class LeanItAchievement {
  final LeanItAchievementType type;
  final String title;
  final String description;
  final bool unlocked;
  final DateTime? unlockedAt;

  const LeanItAchievement({
    required this.type,
    required this.title,
    required this.description,
    required this.unlocked,
    required this.unlockedAt,
  });
}

class WeeklyTrainingReview {
  final DateTime weekStart;
  final int workouts;
  final int strengthSets;
  final int runningSessions;
  final double runningKm;
  final int trainingMinutes;
  final String headline;

  const WeeklyTrainingReview({
    required this.weekStart,
    required this.workouts,
    required this.strengthSets,
    required this.runningSessions,
    required this.runningKm,
    required this.trainingMinutes,
    required this.headline,
  });
}

class LeanItWrapped {
  final int year;
  final int workouts;
  final int trainingMinutes;
  final int completedSets;
  final int runs;
  final double runningKm;
  final int activeWeeks;
  final String headline;

  const LeanItWrapped({
    required this.year,
    required this.workouts,
    required this.trainingMinutes,
    required this.completedSets,
    required this.runs,
    required this.runningKm,
    required this.activeWeeks,
    required this.headline,
  });
}

class MotivationEngine {
  const MotivationEngine._();

  static List<LeanItAchievement> achievements({
    required List<WorkoutRecord> workouts,
    required List<RunRecord> runs,
  }) {
    DateTime? nthWorkout(int count) => workouts.length >= count
        ? (List<WorkoutRecord>.from(workouts)
              ..sort((a, b) => a.completedAt.compareTo(b.completedAt)))[count - 1]
            .completedAt
        : null;
    DateTime? firstRunAt(double meters) {
      final matches = runs.where((run) => run.distanceMeters >= meters).toList()
        ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
      return matches.isEmpty ? null : matches.first.startedAt;
    }

    final activeWeeks = _activeWeekStarts(workouts, runs).toList()..sort();
    final streak = _longestWeeklyStreak(activeWeeks);
    final firstWorkoutAt = nthWorkout(1);
    final firstRun = runs.isEmpty
        ? null
        : (List<RunRecord>.from(runs)
              ..sort((a, b) => a.startedAt.compareTo(b.startedAt)))
            .first
            .startedAt;

    LeanItAchievement item(
      LeanItAchievementType type,
      String title,
      String description,
      DateTime? at,
    ) =>
        LeanItAchievement(
          type: type,
          title: title,
          description: description,
          unlocked: at != null,
          unlockedAt: at,
        );

    return <LeanItAchievement>[
      item(LeanItAchievementType.firstWorkout, 'First workout', 'Complete your first LeanIt workout.', firstWorkoutAt),
      item(LeanItAchievementType.firstRun, 'First run', 'Log or complete your first run.', firstRun),
      item(LeanItAchievementType.workouts10, '10 workouts', 'Build the first double-digit training history.', nthWorkout(10)),
      item(LeanItAchievementType.workouts25, '25 workouts', 'Complete 25 workouts.', nthWorkout(25)),
      item(LeanItAchievementType.workouts50, '50 workouts', 'Complete 50 workouts.', nthWorkout(50)),
      item(LeanItAchievementType.workouts100, '100 workouts', 'Complete 100 workouts.', nthWorkout(100)),
      item(LeanItAchievementType.run5k, '5K complete', 'Complete at least 5 km in one run.', firstRunAt(5000)),
      item(LeanItAchievementType.run10k, '10K complete', 'Complete at least 10 km in one run.', firstRunAt(10000)),
      item(LeanItAchievementType.halfMarathon, 'Half marathon complete', 'Complete at least 21.1 km in one run.', firstRunAt(21097.5)),
      item(LeanItAchievementType.marathon, 'Marathon complete', 'Complete at least 42.195 km in one run.', firstRunAt(42195)),
      item(
        LeanItAchievementType.fourWeekConsistency,
        '4 active weeks',
        'Train in four consecutive calendar weeks.',
        streak >= 4 && activeWeeks.isNotEmpty ? activeWeeks.last : null,
      ),
      item(
        LeanItAchievementType.eightWeekConsistency,
        '8 active weeks',
        'Train in eight consecutive calendar weeks.',
        streak >= 8 && activeWeeks.isNotEmpty ? activeWeeks.last : null,
      ),
    ];
  }

  static WeeklyTrainingReview weeklyReview({
    required List<WorkoutRecord> workouts,
    required List<RunRecord> runs,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final start = _weekStart(reference);
    final end = start.add(const Duration(days: 7));
    final w = workouts
        .where((item) => !item.completedAt.isBefore(start) && item.completedAt.isBefore(end))
        .toList(growable: false);
    final r = runs
        .where((item) => !item.startedAt.isBefore(start) && item.startedAt.isBefore(end))
        .toList(growable: false);
    final trainingMinutes = w.fold<int>(0, (sum, item) => sum + item.durationSeconds) ~/ 60 +
        r.fold<int>(0, (sum, item) => sum + item.durationSeconds) ~/ 60;
    final sets = w.fold<int>(0, (sum, item) => sum + item.completedSets);
    final km = r.fold<double>(0, (sum, item) => sum + item.distanceKm);
    final sessions = w.length + r.length;
    final headline = sessions == 0
        ? 'No completed training yet this week.'
        : sessions >= 5
            ? 'A high-activity week — recovery quality matters now.'
            : sessions >= 3
                ? 'A consistent training week is taking shape.'
                : 'You have started the week; focus on the next planned session.';
    return WeeklyTrainingReview(
      weekStart: start,
      workouts: w.length,
      strengthSets: sets,
      runningSessions: r.length,
      runningKm: km,
      trainingMinutes: trainingMinutes,
      headline: headline,
    );
  }

  static LeanItWrapped wrapped({
    required int year,
    required List<WorkoutRecord> workouts,
    required List<RunRecord> runs,
  }) {
    final w = workouts.where((item) => item.completedAt.year == year).toList();
    final r = runs.where((item) => item.startedAt.year == year).toList();
    final minutes = w.fold<int>(0, (sum, item) => sum + item.durationSeconds) ~/ 60 +
        r.fold<int>(0, (sum, item) => sum + item.durationSeconds) ~/ 60;
    final km = r.fold<double>(0, (sum, item) => sum + item.distanceKm);
    final sets = w.fold<int>(0, (sum, item) => sum + item.completedSets);
    final activeWeeks = _activeWeekStarts(w, r).length;
    return LeanItWrapped(
      year: year,
      workouts: w.length,
      trainingMinutes: minutes,
      completedSets: sets,
      runs: r.length,
      runningKm: km,
      activeWeeks: activeWeeks,
      headline: w.isEmpty && r.isEmpty
          ? 'Your $year training story starts with the first session.'
          : 'You trained across $activeWeeks active week${activeWeeks == 1 ? '' : 's'} in $year.',
    );
  }

  static Set<DateTime> _activeWeekStarts(
    List<WorkoutRecord> workouts,
    List<RunRecord> runs,
  ) {
    return <DateTime>{
      ...workouts.map((item) => _weekStart(item.completedAt)),
      ...runs.map((item) => _weekStart(item.startedAt)),
    };
  }

  static int _longestWeeklyStreak(List<DateTime> weeks) {
    if (weeks.isEmpty) return 0;
    var longest = 1;
    var current = 1;
    for (var i = 1; i < weeks.length; i += 1) {
      if (weeks[i].difference(weeks[i - 1]).inDays == 7) {
        current += 1;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  static DateTime _weekStart(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }
}
