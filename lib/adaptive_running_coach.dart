import 'guided_run_engine.dart';
import 'run_tracking_store.dart';
import 'training_store.dart';

enum RunningCoachAction { start, progress, repeat, reduce, recovery }

class AdaptiveRunRecommendation {
  final GuidedRunPlan plan;
  final RunningCoachAction action;
  final String headline;
  final List<String> reasons;
  final int recentRunCount;
  final int recentMinutes;
  final int previousWeekMinutes;
  final bool readinessUsed;

  const AdaptiveRunRecommendation({
    required this.plan,
    required this.action,
    required this.headline,
    required this.reasons,
    required this.recentRunCount,
    required this.recentMinutes,
    required this.previousWeekMinutes,
    required this.readinessUsed,
  });
}

class AdaptiveRunningCoach {
  static const GuidedRunPlan recoveryPlan = GuidedRunPlan(
    id: 'easy_recovery_run_walk',
    title: 'Easy Recovery Run-Walk',
    description:
        'Very easy running with generous walking recovery to keep the habit without adding unnecessary load.',
    level: 'Recovery',
    steps: <GuidedRunStep>[
      GuidedRunStep(
        label: 'Warm up',
        instruction: 'Walk easily and let your breathing settle.',
        durationSeconds: 300,
        type: GuidedRunPhaseType.warmUp,
      ),
      GuidedRunStep(label: 'Easy run 1', instruction: 'Jog very easily. You should be able to talk.', durationSeconds: 60, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Walk 1', instruction: 'Walk and recover fully.', durationSeconds: 90, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Easy run 2', instruction: 'Jog very easily. You should be able to talk.', durationSeconds: 60, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Walk 2', instruction: 'Walk and recover fully.', durationSeconds: 90, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Easy run 3', instruction: 'Jog very easily. You should be able to talk.', durationSeconds: 60, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Walk 3', instruction: 'Walk and recover fully.', durationSeconds: 90, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Easy run 4', instruction: 'Jog very easily. You should be able to talk.', durationSeconds: 60, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Walk 4', instruction: 'Walk and recover fully.', durationSeconds: 90, type: GuidedRunPhaseType.recover),
      GuidedRunStep(
        label: 'Cool down',
        instruction: 'Walk gently until breathing is comfortable.',
        durationSeconds: 300,
        type: GuidedRunPhaseType.coolDown,
      ),
    ],
  );

  static const GuidedRunPlan runWalkBuild = GuidedRunPlan(
    id: 'run_walk_build',
    title: 'Run-Walk Build',
    description:
        'A small step up from the foundation session: slightly longer running with controlled walking recovery.',
    level: 'Beginner',
    steps: <GuidedRunStep>[
      GuidedRunStep(label: 'Warm up', instruction: 'Brisk walk and easy mobility.', durationSeconds: 300, type: GuidedRunPhaseType.warmUp),
      GuidedRunStep(label: 'Run 1', instruction: 'Run easy and controlled.', durationSeconds: 90, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Walk 1', instruction: 'Walk and recover.', durationSeconds: 75, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Run 2', instruction: 'Run easy and controlled.', durationSeconds: 90, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Walk 2', instruction: 'Walk and recover.', durationSeconds: 75, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Run 3', instruction: 'Run easy and controlled.', durationSeconds: 90, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Walk 3', instruction: 'Walk and recover.', durationSeconds: 75, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Run 4', instruction: 'Run easy and controlled.', durationSeconds: 90, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Walk 4', instruction: 'Walk and recover.', durationSeconds: 75, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Run 5', instruction: 'Run easy and controlled.', durationSeconds: 90, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Walk 5', instruction: 'Walk and recover.', durationSeconds: 75, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Run 6', instruction: 'Run easy and controlled.', durationSeconds: 90, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Walk 6', instruction: 'Walk and recover.', durationSeconds: 75, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Cool down', instruction: 'Walk easily.', durationSeconds: 300, type: GuidedRunPhaseType.coolDown),
    ],
  );

  static const GuidedRunPlan twoMinuteBuild = GuidedRunPlan(
    id: 'run_walk_2min',
    title: 'Two-Minute Run Build',
    description:
        'Longer easy running blocks while keeping short walking recoveries between efforts.',
    level: 'Beginner',
    steps: <GuidedRunStep>[
      GuidedRunStep(label: 'Warm up', instruction: 'Walk briskly or jog very easily.', durationSeconds: 300, type: GuidedRunPhaseType.warmUp),
      GuidedRunStep(label: 'Run 1', instruction: 'Run easy and controlled.', durationSeconds: 120, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Walk 1', instruction: 'Walk and reset.', durationSeconds: 60, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Run 2', instruction: 'Run easy and controlled.', durationSeconds: 120, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Walk 2', instruction: 'Walk and reset.', durationSeconds: 60, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Run 3', instruction: 'Run easy and controlled.', durationSeconds: 120, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Walk 3', instruction: 'Walk and reset.', durationSeconds: 60, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Run 4', instruction: 'Run easy and controlled.', durationSeconds: 120, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Walk 4', instruction: 'Walk and reset.', durationSeconds: 60, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Run 5', instruction: 'Run easy and controlled.', durationSeconds: 120, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Walk 5', instruction: 'Walk and reset.', durationSeconds: 60, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Run 6', instruction: 'Run easy and controlled.', durationSeconds: 120, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Walk 6', instruction: 'Walk and reset.', durationSeconds: 60, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Cool down', instruction: 'Walk easily.', durationSeconds: 300, type: GuidedRunPhaseType.coolDown),
    ],
  );

  static const GuidedRunPlan steadyBuild = GuidedRunPlan(
    id: 'steady_build',
    title: 'Steady Endurance Build',
    description:
        'Longer steady blocks that build aerobic durability without turning the session into a race.',
    level: 'Beginner / Intermediate',
    steps: <GuidedRunStep>[
      GuidedRunStep(label: 'Warm up', instruction: 'Easy jog and gradually settle in.', durationSeconds: 300, type: GuidedRunPhaseType.warmUp),
      GuidedRunStep(label: 'Steady 1', instruction: 'Comfortably hard enough to focus, never all-out.', durationSeconds: 180, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Easy 1', instruction: 'Walk or jog very easily.', durationSeconds: 75, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Steady 2', instruction: 'Controlled steady effort.', durationSeconds: 180, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Easy 2', instruction: 'Walk or jog very easily.', durationSeconds: 75, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Steady 3', instruction: 'Controlled steady effort.', durationSeconds: 180, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Easy 3', instruction: 'Walk or jog very easily.', durationSeconds: 75, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Steady 4', instruction: 'Controlled steady effort.', durationSeconds: 180, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Easy 4', instruction: 'Walk or jog very easily.', durationSeconds: 75, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Steady 5', instruction: 'Finish controlled, not exhausted.', durationSeconds: 180, type: GuidedRunPhaseType.run),
      GuidedRunStep(label: 'Easy 5', instruction: 'Walk or jog very easily.', durationSeconds: 75, type: GuidedRunPhaseType.recover),
      GuidedRunStep(label: 'Cool down', instruction: 'Jog or walk easily.', durationSeconds: 300, type: GuidedRunPhaseType.coolDown),
    ],
  );

  static List<GuidedRunPlan> get allPlans => <GuidedRunPlan>[
        recoveryPlan,
        ...GuidedRunEngine.starterPlans,
        runWalkBuild,
        twoMinuteBuild,
        steadyBuild,
      ];

  static AdaptiveRunRecommendation recommend({
    required List<RunRecord> runs,
    ReadinessRecord? readiness,
    String? mainGoal,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final sorted = List<RunRecord>.from(runs)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final guided = sorted.where((run) => run.isGuided).toList(growable: false);
    final latestGuided = guided.isEmpty ? null : guided.first;

    final recentStart = reference.subtract(const Duration(days: 7));
    final previousStart = reference.subtract(const Duration(days: 14));
    final recentRuns = sorted
        .where((run) => !run.startedAt.isBefore(recentStart) && !run.startedAt.isAfter(reference))
        .toList(growable: false);
    final previousRuns = sorted
        .where((run) =>
            !run.startedAt.isBefore(previousStart) && run.startedAt.isBefore(recentStart))
        .toList(growable: false);
    final recentSeconds = _duration(recentRuns);
    final previousSeconds = _duration(previousRuns);
    final overloaded = _isOverloaded(
      recentRuns: recentRuns.length,
      recentSeconds: recentSeconds,
      previousSeconds: previousSeconds,
    );

    final recentReadiness = readiness != null &&
            readiness.recordedAt.isAfter(reference.subtract(const Duration(hours: 48))) &&
            !readiness.recordedAt.isAfter(reference.add(const Duration(minutes: 5)))
        ? readiness
        : null;
    final readinessScore = recentReadiness?.score;
    final reasons = <String>[];

    if (readinessScore != null && readinessScore < 40) {
      reasons.add('Recent readiness is ${readinessScore.round()}%, so today should reduce training stress.');
      if (recentRuns.isNotEmpty) {
        reasons.add('${recentRuns.length} run${recentRuns.length == 1 ? '' : 's'} already logged in the last 7 days.');
      }
      return _result(
        plan: recoveryPlan,
        action: RunningCoachAction.recovery,
        headline: 'Keep today very easy',
        reasons: reasons,
        recentRuns: recentRuns.length,
        recentSeconds: recentSeconds,
        previousSeconds: previousSeconds,
        readinessUsed: true,
      );
    }

    if (overloaded) {
      reasons.add('Recent running load is already high relative to the previous week.');
      if (readinessScore != null) {
        reasons.add('Readiness is ${readinessScore.round()}%; LeanIt is protecting recovery before adding more load.');
      }
      return _result(
        plan: recoveryPlan,
        action: RunningCoachAction.recovery,
        headline: 'Absorb the work before progressing',
        reasons: reasons,
        recentRuns: recentRuns.length,
        recentSeconds: recentSeconds,
        previousSeconds: previousSeconds,
        readinessUsed: recentReadiness != null,
      );
    }

    if (latestGuided == null) {
      reasons.add(sorted.isEmpty
          ? 'No running history yet, so LeanIt starts with short, controlled run-walk intervals.'
          : 'No completed guided progression is recorded yet, so LeanIt starts with the foundation session.');
      if (recentReadiness == null) {
        reasons.add('No recent readiness check is available; the conservative starting session is used.');
      } else {
        reasons.add('Readiness is ${readinessScore!.round()}%, which is suitable for a controlled foundation run.');
      }
      return _result(
        plan: GuidedRunEngine.starterPlans.first,
        action: RunningCoachAction.start,
        headline: 'Build the running base first',
        reasons: reasons,
        recentRuns: recentRuns.length,
        recentSeconds: recentSeconds,
        previousSeconds: previousSeconds,
        readinessUsed: recentReadiness != null,
      );
    }

    final latestPlan = planById(latestGuided.guidedPlanId) ??
        GuidedRunEngine.starterPlans.first;
    final completionRatio = latestGuided.guidedCompletionRatio;
    final endedEarly = latestGuided.guidedCompleted == false ||
        (completionRatio != null && completionRatio < 0.85);
    final effort = latestGuided.perceivedEffort?.toLowerCase();

    if (endedEarly) {
      reasons.add('The last guided session ended before the planned work was completed.');
      if (completionRatio != null) {
        reasons.add('About ${(completionRatio * 100).round()}% of its planned duration was logged.');
      }
      final substantiallyShort = completionRatio != null && completionRatio < 0.70;
      return _result(
        plan: substantiallyShort ? recoveryPlan : latestPlan,
        action: substantiallyShort ? RunningCoachAction.reduce : RunningCoachAction.repeat,
        headline: substantiallyShort
            ? 'Reduce the session before building again'
            : 'Repeat before progressing',
        reasons: reasons,
        recentRuns: recentRuns.length,
        recentSeconds: recentSeconds,
        previousSeconds: previousSeconds,
        readinessUsed: recentReadiness != null,
      );
    }

    if (effort == 'hard') {
      reasons.add('You marked the last guided session as hard.');
      reasons.add('LeanIt will consolidate the same level instead of increasing difficulty.');
      return _result(
        plan: latestPlan,
        action: RunningCoachAction.repeat,
        headline: 'Own this level before progressing',
        reasons: reasons,
        recentRuns: recentRuns.length,
        recentSeconds: recentSeconds,
        previousSeconds: previousSeconds,
        readinessUsed: recentReadiness != null,
      );
    }

    if (readinessScore != null && readinessScore < 60) {
      reasons.add('Readiness is ${readinessScore.round()}%, so today is not a good progression day.');
      reasons.add('The current running level is retained with no extra intensity.');
      return _result(
        plan: latestPlan.id == GuidedRunEngine.starterPlans[2].id ? steadyBuild : latestPlan,
        action: RunningCoachAction.repeat,
        headline: 'Hold the level today',
        reasons: reasons,
        recentRuns: recentRuns.length,
        recentSeconds: recentSeconds,
        previousSeconds: previousSeconds,
        readinessUsed: true,
      );
    }

    final successfulGuided = guided
        .where((run) => run.guidedCompleted == true && run.perceivedEffort?.toLowerCase() != 'hard')
        .length;
    final next = _progressionAfter(
      latestPlan: latestPlan,
      successfulGuided: successfulGuided,
      goal: mainGoal,
    );

    if (next.id == latestPlan.id) {
      reasons.add('The latest session was completed successfully.');
      reasons.add('LeanIt is keeping the same level because the next intensity jump is not yet justified.');
      return _result(
        plan: latestPlan,
        action: RunningCoachAction.repeat,
        headline: 'Consolidate this level',
        reasons: reasons,
        recentRuns: recentRuns.length,
        recentSeconds: recentSeconds,
        previousSeconds: previousSeconds,
        readinessUsed: recentReadiness != null,
      );
    }

    final capped = _durationJumpSafe(latestPlan, next) ? next : latestPlan;
    if (capped.id == latestPlan.id) {
      reasons.add('Your last guided run was successful, but the next session would increase duration too sharply.');
      reasons.add('LeanIt is repeating the current level to keep progression gradual.');
      return _result(
        plan: latestPlan,
        action: RunningCoachAction.repeat,
        headline: 'Progress gradually, not abruptly',
        reasons: reasons,
        recentRuns: recentRuns.length,
        recentSeconds: recentSeconds,
        previousSeconds: previousSeconds,
        readinessUsed: recentReadiness != null,
      );
    }

    reasons.add('The last guided session was completed without a hard-effort flag.');
    if (readinessScore != null) {
      reasons.add('Readiness is ${readinessScore.round()}%, so a small progression is reasonable.');
    } else {
      reasons.add('No recent readiness check is available, so the progression remains deliberately small.');
    }
    if (mainGoal != null && mainGoal.trim().isNotEmpty) {
      reasons.add('Your programme goal (${mainGoal.trim()}) is considered when choosing later steady or speed work.');
    }
    return _result(
      plan: capped,
      action: RunningCoachAction.progress,
      headline: 'A small progression is ready',
      reasons: reasons,
      recentRuns: recentRuns.length,
      recentSeconds: recentSeconds,
      previousSeconds: previousSeconds,
      readinessUsed: recentReadiness != null,
    );
  }

  static GuidedRunPlan? planById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final plan in allPlans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  static GuidedRunPlan _progressionAfter({
    required GuidedRunPlan latestPlan,
    required int successfulGuided,
    String? goal,
  }) {
    switch (latestPlan.id) {
      case 'run_walk_foundation':
        return runWalkBuild;
      case 'run_walk_build':
        return twoMinuteBuild;
      case 'run_walk_2min':
        return GuidedRunEngine.starterPlans[1];
      case 'steady_intervals':
        return successfulGuided >= 3 ? steadyBuild : latestPlan;
      case 'steady_build':
        if (successfulGuided < 4 || !_speedRelevant(goal)) return latestPlan;
        return GuidedRunEngine.starterPlans[2];
      case 'speed_intervals':
        return latestPlan;
      default:
        return GuidedRunEngine.starterPlans.first;
    }
  }

  static bool _speedRelevant(String? goal) {
    final lower = goal?.toLowerCase() ?? '';
    return lower.contains('run') ||
        lower.contains('endurance') ||
        lower.contains('cardio') ||
        lower.contains('speed') ||
        lower.contains('fitness');
  }

  static bool _durationJumpSafe(GuidedRunPlan current, GuidedRunPlan next) {
    if (current.totalSeconds <= 0) return true;
    return next.totalSeconds <= (current.totalSeconds * 1.20).round();
  }

  static bool _isOverloaded({
    required int recentRuns,
    required int recentSeconds,
    required int previousSeconds,
  }) {
    if (recentRuns >= 4) return true;
    if (recentSeconds < 45 * 60 || previousSeconds < 20 * 60) return false;
    return recentSeconds > previousSeconds * 1.30;
  }

  static int _duration(Iterable<RunRecord> runs) =>
      runs.fold<int>(0, (total, run) => total + run.durationSeconds);

  static AdaptiveRunRecommendation _result({
    required GuidedRunPlan plan,
    required RunningCoachAction action,
    required String headline,
    required List<String> reasons,
    required int recentRuns,
    required int recentSeconds,
    required int previousSeconds,
    required bool readinessUsed,
  }) {
    return AdaptiveRunRecommendation(
      plan: plan,
      action: action,
      headline: headline,
      reasons: List<String>.unmodifiable(reasons),
      recentRunCount: recentRuns,
      recentMinutes: (recentSeconds / 60).round(),
      previousWeekMinutes: (previousSeconds / 60).round(),
      readinessUsed: readinessUsed,
    );
  }
}
