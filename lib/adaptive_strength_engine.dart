import 'exercise_performance_store.dart';
import 'training_store.dart';

enum StrengthAdaptationAction {
  buildBaseline,
  progress,
  maintain,
  reduce,
  deload,
}

class StrengthAdaptationRecommendation {
  final StrengthAdaptationAction action;
  final String headline;
  final String explanation;
  final List<String> reasons;
  final double? readinessScore;
  final bool readinessUsed;
  final int currentWeekWorkouts;
  final int previousWeekWorkouts;
  final int currentWeekSets;
  final int previousWeekSets;
  final double currentWeekVolumeKg;
  final double previousWeekVolumeKg;
  final int improvingExercises;
  final int decliningExercises;
  final int recentHardSessions;

  const StrengthAdaptationRecommendation({
    required this.action,
    required this.headline,
    required this.explanation,
    required this.reasons,
    required this.readinessScore,
    required this.readinessUsed,
    required this.currentWeekWorkouts,
    required this.previousWeekWorkouts,
    required this.currentWeekSets,
    required this.previousWeekSets,
    required this.currentWeekVolumeKg,
    required this.previousWeekVolumeKg,
    required this.improvingExercises,
    required this.decliningExercises,
    required this.recentHardSessions,
  });

  bool get allowsProgression => action == StrengthAdaptationAction.progress;

  bool get protectsRecovery =>
      action == StrengthAdaptationAction.reduce ||
      action == StrengthAdaptationAction.deload;

  double get suggestedLoadMultiplier {
    switch (action) {
      case StrengthAdaptationAction.deload:
        return 0.90;
      case StrengthAdaptationAction.reduce:
        return 0.95;
      case StrengthAdaptationAction.buildBaseline:
      case StrengthAdaptationAction.maintain:
      case StrengthAdaptationAction.progress:
        return 1.0;
    }
  }

  double get suggestedVolumeMultiplier {
    switch (action) {
      case StrengthAdaptationAction.deload:
        return 0.65;
      case StrengthAdaptationAction.reduce:
        return 0.80;
      case StrengthAdaptationAction.buildBaseline:
      case StrengthAdaptationAction.maintain:
      case StrengthAdaptationAction.progress:
        return 1.0;
    }
  }
}

class StrengthAdaptationEngine {
  static StrengthAdaptationRecommendation analyse({
    required List<WorkoutRecord> workouts,
    required List<ExerciseSetPerformance> sets,
    ReadinessRecord? readiness,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final weekStart = _weekStart(reference);
    final previousWeekStart = weekStart.subtract(const Duration(days: 7));
    final futureTolerance = reference.add(const Duration(minutes: 5));

    final normalSets = sets
        .where((set) => !set.isDropSet && !set.performedAt.isAfter(futureTolerance))
        .toList(growable: false);
    final currentSets = normalSets
        .where((set) => !set.performedAt.isBefore(weekStart))
        .toList(growable: false);
    final previousSets = normalSets
        .where(
          (set) =>
              !set.performedAt.isBefore(previousWeekStart) &&
              set.performedAt.isBefore(weekStart),
        )
        .toList(growable: false);

    final currentWorkouts = workouts
        .where(
          (workout) =>
              !workout.completedAt.isBefore(weekStart) &&
              !workout.completedAt.isAfter(futureTolerance),
        )
        .toList(growable: false);
    final previousWorkouts = workouts
        .where(
          (workout) =>
              !workout.completedAt.isBefore(previousWeekStart) &&
              workout.completedAt.isBefore(weekStart),
        )
        .toList(growable: false);

    final recentReadiness = readiness != null &&
            !readiness.recordedAt.isBefore(
              reference.subtract(const Duration(hours: 48)),
            ) &&
            !readiness.recordedAt.isAfter(futureTolerance)
        ? readiness
        : null;
    final readinessScore = recentReadiness?.score;

    final currentVolume = _volume(currentSets);
    final previousVolume = _volume(previousSets);
    final trends = _exerciseTrends(normalSets, reference);
    final hardSessions = workouts
        .where(
          (workout) =>
              !workout.completedAt.isBefore(
                reference.subtract(const Duration(days: 7)),
              ) &&
              !workout.completedAt.isAfter(futureTolerance) &&
              workout.perceivedEffort == 'hard',
        )
        .length;

    final reasons = <String>[];
    final totalRecentWorkouts = currentWorkouts.length + previousWorkouts.length;
    final totalRecentSets = currentSets.length + previousSets.length;

    if (totalRecentWorkouts < 2 || totalRecentSets < 6) {
      reasons.add(
        'LeanIt needs at least two recent strength sessions and six logged working sets before it increases training automatically.',
      );
      if (readinessScore != null) {
        reasons.add(
          'Recent readiness is ${readinessScore.round()}%, but performance history is still the limiting signal.',
        );
      }
      return _result(
        action: StrengthAdaptationAction.buildBaseline,
        headline: 'Build a reliable baseline first',
        explanation:
            'Keep the current prescription controlled while LeanIt gathers enough repeated strength data to separate real progress from one unusually good or bad session.',
        reasons: reasons,
        readiness: recentReadiness,
        currentWorkouts: currentWorkouts,
        previousWorkouts: previousWorkouts,
        currentSets: currentSets,
        previousSets: previousSets,
        currentVolume: currentVolume,
        previousVolume: previousVolume,
        trends: trends,
        hardSessions: hardSessions,
      );
    }

    if (readinessScore != null && readinessScore < 40) {
      reasons.add(
        'Readiness is ${readinessScore.round()}%, which is below LeanIt’s recovery threshold for normal progression.',
      );
      reasons.add('Load and total working sets should both come down today.');
      return _result(
        action: StrengthAdaptationAction.deload,
        headline: 'Deload today',
        explanation:
            'Recovery is currently too low to justify adding load. LeanIt will favour roughly 10% lighter working weights and substantially less total volume.',
        reasons: reasons,
        readiness: recentReadiness,
        currentWorkouts: currentWorkouts,
        previousWorkouts: previousWorkouts,
        currentSets: currentSets,
        previousSets: previousSets,
        currentVolume: currentVolume,
        previousVolume: previousVolume,
        trends: trends,
        hardSessions: hardSessions,
      );
    }

    final workloadAtLeastPrevious = previousSets.isEmpty
        ? currentSets.length >= 10
        : currentSets.length >= previousSets.length;
    if (hardSessions >= 2 && workloadAtLeastPrevious) {
      reasons.add('$hardSessions recent strength sessions were marked hard.');
      reasons.add('Current set load is not lower than the previous training week.');
      return _result(
        action: StrengthAdaptationAction.deload,
        headline: 'Take a deload before pushing again',
        explanation:
            'Repeated hard sessions without a drop in workload are a fatigue signal. LeanIt will reduce load and working-set volume rather than chase another progression target.',
        reasons: reasons,
        readiness: recentReadiness,
        currentWorkouts: currentWorkouts,
        previousWorkouts: previousWorkouts,
        currentSets: currentSets,
        previousSets: previousSets,
        currentVolume: currentVolume,
        previousVolume: previousVolume,
        trends: trends,
        hardSessions: hardSessions,
      );
    }

    final meaningfulTrainingLoad = currentSets.length >= 6 &&
        (previousSets.isEmpty || currentSets.length >= previousSets.length * 0.85);
    if (trends.declining >= 2 && meaningfulTrainingLoad) {
      reasons.add(
        '${trends.declining} exercises are below their prior-week performance signal.',
      );
      reasons.add('Training load is still high enough that fatigue may be masking fitness.');
      return _result(
        action: StrengthAdaptationAction.deload,
        headline: 'Performance is asking for recovery',
        explanation:
            'Several exercises are trending down while training load remains meaningful. LeanIt will use a deload instead of automatically increasing reps or weight.',
        reasons: reasons,
        readiness: recentReadiness,
        currentWorkouts: currentWorkouts,
        previousWorkouts: previousWorkouts,
        currentSets: currentSets,
        previousSets: previousSets,
        currentVolume: currentVolume,
        previousVolume: previousVolume,
        trends: trends,
        hardSessions: hardSessions,
      );
    }

    if (readinessScore != null && readinessScore < 60) {
      reasons.add(
        'Readiness is ${readinessScore.round()}%, so adding training stress is not justified today.',
      );
      reasons.add('LeanIt will keep the movement pattern but trim the target.');
      return _result(
        action: StrengthAdaptationAction.reduce,
        headline: 'Train lighter, not harder',
        explanation:
            'You can still train, but LeanIt will reduce the next target instead of progressing until recovery improves.',
        reasons: reasons,
        readiness: recentReadiness,
        currentWorkouts: currentWorkouts,
        previousWorkouts: previousWorkouts,
        currentSets: currentSets,
        previousSets: previousSets,
        currentVolume: currentVolume,
        previousVolume: previousVolume,
        trends: trends,
        hardSessions: hardSessions,
      );
    }

    final volumeSpike = previousVolume > 0 && currentVolume > previousVolume * 1.35;
    final setSpike = previousSets.isNotEmpty &&
        currentSets.length > previousSets.length * 1.35;
    if ((volumeSpike || setSpike) && currentWorkouts.length >= 2) {
      if (volumeSpike) {
        reasons.add(
          'Logged strength volume is more than 35% above the previous week.',
        );
      }
      if (setSpike) {
        reasons.add('Working-set count is more than 35% above the previous week.');
      }
      return _result(
        action: StrengthAdaptationAction.reduce,
        headline: 'Hold progression while workload catches up',
        explanation:
            'The current week already contains a large workload increase. LeanIt will avoid stacking a second progression jump on top of it.',
        reasons: reasons,
        readiness: recentReadiness,
        currentWorkouts: currentWorkouts,
        previousWorkouts: previousWorkouts,
        currentSets: currentSets,
        previousSets: previousSets,
        currentVolume: currentVolume,
        previousVolume: previousVolume,
        trends: trends,
        hardSessions: hardSessions,
      );
    }

    if (hardSessions > 0 || trends.declining > trends.improving) {
      if (hardSessions > 0) {
        reasons.add('A recent strength session was marked hard.');
      }
      if (trends.declining > trends.improving) {
        reasons.add(
          'More tracked exercises are declining than improving across the recent two-week comparison.',
        );
      }
      return _result(
        action: StrengthAdaptationAction.maintain,
        headline: 'Consolidate the current level',
        explanation:
            'The safest next step is to repeat current loads and rep targets cleanly before asking for more.',
        reasons: reasons,
        readiness: recentReadiness,
        currentWorkouts: currentWorkouts,
        previousWorkouts: previousWorkouts,
        currentSets: currentSets,
        previousSets: previousSets,
        currentVolume: currentVolume,
        previousVolume: previousVolume,
        trends: trends,
        hardSessions: hardSessions,
      );
    }

    if (readinessScore != null) {
      reasons.add('Recent readiness is ${readinessScore.round()}%.');
    } else {
      reasons.add('No recent readiness check is available, so progression relies on training history only.');
    }
    if (trends.improving > 0) {
      reasons.add('${trends.improving} tracked exercise${trends.improving == 1 ? '' : 's'} improved versus the prior week.');
    } else {
      reasons.add('No multi-exercise decline signal is present in recent performance.');
    }
    return _result(
      action: StrengthAdaptationAction.progress,
      headline: 'Progress conservatively',
      explanation:
          'Recovery and recent workload do not show a reason to back off. LeanIt can use normal double-progression rules: add a rep first, then add a small amount of load after the top of the rep range is reached.',
      reasons: reasons,
      readiness: recentReadiness,
      currentWorkouts: currentWorkouts,
      previousWorkouts: previousWorkouts,
      currentSets: currentSets,
      previousSets: previousSets,
      currentVolume: currentVolume,
      previousVolume: previousVolume,
      trends: trends,
      hardSessions: hardSessions,
    );
  }

  static StrengthAdaptationRecommendation _result({
    required StrengthAdaptationAction action,
    required String headline,
    required String explanation,
    required List<String> reasons,
    required ReadinessRecord? readiness,
    required List<WorkoutRecord> currentWorkouts,
    required List<WorkoutRecord> previousWorkouts,
    required List<ExerciseSetPerformance> currentSets,
    required List<ExerciseSetPerformance> previousSets,
    required double currentVolume,
    required double previousVolume,
    required _ExerciseTrendSummary trends,
    required int hardSessions,
  }) {
    return StrengthAdaptationRecommendation(
      action: action,
      headline: headline,
      explanation: explanation,
      reasons: List<String>.unmodifiable(reasons),
      readinessScore: readiness?.score,
      readinessUsed: readiness != null,
      currentWeekWorkouts: currentWorkouts.length,
      previousWeekWorkouts: previousWorkouts.length,
      currentWeekSets: currentSets.length,
      previousWeekSets: previousSets.length,
      currentWeekVolumeKg: currentVolume,
      previousWeekVolumeKg: previousVolume,
      improvingExercises: trends.improving,
      decliningExercises: trends.declining,
      recentHardSessions: hardSessions,
    );
  }

  static DateTime _weekStart(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static double _volume(List<ExerciseSetPerformance> sets) => sets.fold<double>(
        0,
        (sum, set) => sum + set.volumeKg,
      );

  static _ExerciseTrendSummary _exerciseTrends(
    List<ExerciseSetPerformance> sets,
    DateTime reference,
  ) {
    final currentStart = reference.subtract(const Duration(days: 7));
    final previousStart = reference.subtract(const Duration(days: 14));
    final current = <String, double>{};
    final previous = <String, double>{};

    for (final set in sets) {
      if (set.performedAt.isBefore(previousStart) ||
          set.performedAt.isAfter(reference.add(const Duration(minutes: 5)))) {
        continue;
      }
      final signal = _performanceSignal(set);
      if (signal == null || signal <= 0) continue;
      final key = set.exerciseName.trim().toLowerCase();
      final bucket = !set.performedAt.isBefore(currentStart) ? current : previous;
      final existing = bucket[key];
      if (existing == null || signal > existing) bucket[key] = signal;
    }

    var improving = 0;
    var declining = 0;
    for (final entry in current.entries) {
      final prior = previous[entry.key];
      if (prior == null || prior <= 0) continue;
      final ratio = entry.value / prior;
      if (ratio >= 1.03) {
        improving += 1;
      } else if (ratio <= 0.95) {
        declining += 1;
      }
    }
    return _ExerciseTrendSummary(improving: improving, declining: declining);
  }

  static double? _performanceSignal(ExerciseSetPerformance set) {
    if (set.weightKg != null && set.weightKg! > 0 && set.reps != null && set.reps! > 0) {
      return set.weightKg! * (1 + set.reps! / 30.0);
    }
    if (set.durationSeconds != null && set.durationSeconds! > 0) {
      return set.durationSeconds!.toDouble();
    }
    if (set.reps != null && set.reps! > 0) return set.reps!.toDouble();
    return null;
  }
}

class _ExerciseTrendSummary {
  final int improving;
  final int declining;

  const _ExerciseTrendSummary({
    required this.improving,
    required this.declining,
  });
}
