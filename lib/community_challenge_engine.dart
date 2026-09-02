import 'run_tracking_store.dart';
import 'training_store.dart';

enum CommunityChallengeType {
  workoutsPerWeek,
  runningDistanceMonth,
  first5k,
  consistencyMonth,
}

class CommunityChallenge {
  final String id;
  final String title;
  final String description;
  final CommunityChallengeType type;
  final double target;
  final String unit;

  const CommunityChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    required this.unit,
  });
}

class CommunityChallengeProgress {
  final CommunityChallenge challenge;
  final double value;
  final bool complete;

  const CommunityChallengeProgress({
    required this.challenge,
    required this.value,
    required this.complete,
  });

  double get fraction => challenge.target <= 0
      ? 0
      : (value / challenge.target).clamp(0, 1).toDouble();
}

class CommunityChallengeEngine {
  const CommunityChallengeEngine._();

  static const List<CommunityChallenge> starterChallenges =
      <CommunityChallenge>[
    CommunityChallenge(
      id: 'three_sessions_week',
      title: '3 Sessions This Week',
      description: 'Complete any three workouts or runs in one calendar week.',
      type: CommunityChallengeType.workoutsPerWeek,
      target: 3,
      unit: 'sessions',
    ),
    CommunityChallenge(
      id: 'twenty_k_month',
      title: '20K This Month',
      description: 'Accumulate 20 km of running this calendar month.',
      type: CommunityChallengeType.runningDistanceMonth,
      target: 20,
      unit: 'km',
    ),
    CommunityChallenge(
      id: 'first_5k',
      title: 'Complete a 5K',
      description: 'Complete at least 5 km in a single run.',
      type: CommunityChallengeType.first5k,
      target: 5,
      unit: 'km',
    ),
    CommunityChallenge(
      id: 'four_active_weeks',
      title: '4 Active Weeks',
      description: 'Complete at least one session in four consecutive weeks.',
      type: CommunityChallengeType.consistencyMonth,
      target: 4,
      unit: 'weeks',
    ),
  ];

  static CommunityChallengeProgress progress({
    required CommunityChallenge challenge,
    required List<WorkoutRecord> workouts,
    required List<RunRecord> runs,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    double value;
    switch (challenge.type) {
      case CommunityChallengeType.workoutsPerWeek:
        final start = _weekStart(reference);
        final end = start.add(const Duration(days: 7));
        final workoutCount = workouts
            .where((item) =>
                !item.completedAt.isBefore(start) && item.completedAt.isBefore(end))
            .length;
        final runCount = runs
            .where((item) =>
                !item.startedAt.isBefore(start) && item.startedAt.isBefore(end))
            .length;
        value = (workoutCount + runCount).toDouble();
        break;
      case CommunityChallengeType.runningDistanceMonth:
        value = runs
            .where((run) =>
                run.startedAt.year == reference.year &&
                run.startedAt.month == reference.month)
            .fold<double>(0, (sum, run) => sum + run.distanceKm);
        break;
      case CommunityChallengeType.first5k:
        value = runs.isEmpty
            ? 0
            : runs
                .map((run) => run.distanceKm)
                .reduce((a, b) => a > b ? a : b);
        break;
      case CommunityChallengeType.consistencyMonth:
        final weeks = <DateTime>{
          ...workouts.map((item) => _weekStart(item.completedAt)),
          ...runs.map((item) => _weekStart(item.startedAt)),
        }.toList()
          ..sort();
        value = _currentStreak(weeks).toDouble();
        break;
    }
    return CommunityChallengeProgress(
      challenge: challenge,
      value: value,
      complete: value >= challenge.target,
    );
  }

  static String shareText({
    required String headline,
    required int workouts,
    required int runs,
    required double runningKm,
    bool includeNumbers = true,
  }) {
    if (!includeNumbers) {
      return '$headline\n\nShared from LeanIt. Training details kept private.';
    }
    return '$headline\n'
        'Strength workouts: $workouts\n'
        'Runs: $runs\n'
        'Running: ${runningKm.toStringAsFixed(1)} km\n\n'
        'Shared from LeanIt.';
  }

  static int _currentStreak(List<DateTime> weeks) {
    if (weeks.isEmpty) return 0;
    var streak = 1;
    for (var i = weeks.length - 1; i > 0; i -= 1) {
      if (weeks[i].difference(weeks[i - 1]).inDays == 7) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  static DateTime _weekStart(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }
}
