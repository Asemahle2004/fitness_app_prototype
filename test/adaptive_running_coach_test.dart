import 'package:fitness_app_prototype/adaptive_running_coach.dart';
import 'package:fitness_app_prototype/run_tracking_store.dart';
import 'package:fitness_app_prototype/training_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 2, 12);

  RunRecord guided({
    String planId = 'run_walk_foundation',
    int duration = 1800,
    int planned = 1800,
    bool completed = true,
    String effort = 'right',
    int daysAgo = 2,
  }) {
    return RunRecord(
      id: '$planId-$daysAgo-$effort',
      startedAt: now.subtract(Duration(days: daysAgo)),
      durationSeconds: duration,
      distanceMeters: 3000,
      source: 'gps_guided',
      guidedPlanId: planId,
      guidedPlannedSeconds: planned,
      guidedCompleted: completed,
      perceivedEffort: effort,
    );
  }

  ReadinessRecord readiness(double scoreLike) {
    // sleep + energy + (6-soreness) + (6-stress), all on a 1–5 scale.
    final value = scoreLike / 20;
    return ReadinessRecord(
      recordedAt: now.subtract(const Duration(hours: 2)),
      sleep: value,
      energy: value,
      soreness: 6 - value,
      stress: 6 - value,
    );
  }

  test('no running history starts with foundation', () {
    final result = AdaptiveRunningCoach.recommend(runs: const [], now: now);
    expect(result.action, RunningCoachAction.start);
    expect(result.plan.id, 'run_walk_foundation');
  });

  test('successful foundation progresses by a small step', () {
    final result = AdaptiveRunningCoach.recommend(
      runs: [guided(effort: 'easy')],
      readiness: readiness(80),
      now: now,
    );
    expect(result.action, RunningCoachAction.progress);
    expect(result.plan.id, 'run_walk_build');
  });

  test('ended-early guided run never progresses', () {
    final result = AdaptiveRunningCoach.recommend(
      runs: [
        guided(
          duration: 1350,
          planned: 1800,
          completed: false,
          effort: 'right',
        ),
      ],
      readiness: readiness(85),
      now: now,
    );
    expect(result.action, RunningCoachAction.repeat);
    expect(result.plan.id, 'run_walk_foundation');
  });

  test('substantially incomplete session is reduced', () {
    final result = AdaptiveRunningCoach.recommend(
      runs: [
        guided(
          duration: 900,
          planned: 1800,
          completed: false,
        ),
      ],
      readiness: readiness(85),
      now: now,
    );
    expect(result.action, RunningCoachAction.reduce);
    expect(result.plan.id, 'easy_recovery_run_walk');
  });

  test('hard perceived effort repeats rather than progressing', () {
    final result = AdaptiveRunningCoach.recommend(
      runs: [guided(effort: 'hard')],
      readiness: readiness(90),
      now: now,
    );
    expect(result.action, RunningCoachAction.repeat);
    expect(result.plan.id, 'run_walk_foundation');
  });

  test('low recent readiness selects recovery', () {
    final result = AdaptiveRunningCoach.recommend(
      runs: [guided(effort: 'easy')],
      readiness: readiness(35),
      now: now,
    );
    expect(result.action, RunningCoachAction.recovery);
    expect(result.plan.id, 'easy_recovery_run_walk');
  });

  test('stale readiness is ignored', () {
    final stale = ReadinessRecord(
      recordedAt: now.subtract(const Duration(days: 5)),
      sleep: 1,
      energy: 1,
      soreness: 5,
      stress: 5,
    );
    final result = AdaptiveRunningCoach.recommend(
      runs: [guided(effort: 'easy')],
      readiness: stale,
      now: now,
    );
    expect(result.action, RunningCoachAction.progress);
    expect(result.readinessUsed, isFalse);
  });

  test('four runs in seven days triggers recovery instead of progression', () {
    final result = AdaptiveRunningCoach.recommend(
      runs: [
        guided(daysAgo: 1, effort: 'easy'),
        guided(planId: 'run_walk_build', duration: 1500, planned: 1590, daysAgo: 2),
        guided(planId: 'run_walk_build', duration: 1500, planned: 1590, daysAgo: 3),
        guided(planId: 'run_walk_build', duration: 1500, planned: 1590, daysAgo: 4),
      ],
      readiness: readiness(90),
      now: now,
    );
    expect(result.action, RunningCoachAction.recovery);
  });

  test('speed intervals stay locked until enough successful guided work', () {
    final result = AdaptiveRunningCoach.recommend(
      runs: [
        guided(planId: 'steady_build', duration: 1575, planned: 1575, daysAgo: 2),
        guided(planId: 'steady_intervals', duration: 1680, planned: 1680, daysAgo: 10),
        guided(planId: 'run_walk_2min', duration: 1680, planned: 1680, daysAgo: 17),
      ],
      readiness: readiness(90),
      mainGoal: 'Improve running endurance',
      now: now,
    );
    expect(result.plan.id, 'steady_build');
    expect(result.action, RunningCoachAction.repeat);
  });

  test('speed intervals unlock after enough successful guided sessions', () {
    final result = AdaptiveRunningCoach.recommend(
      runs: [
        guided(planId: 'steady_build', duration: 1575, planned: 1575, daysAgo: 1),
        guided(planId: 'steady_intervals', duration: 1680, planned: 1680, daysAgo: 8),
        guided(planId: 'run_walk_2min', duration: 1680, planned: 1680, daysAgo: 15),
        guided(planId: 'run_walk_build', duration: 1590, planned: 1590, daysAgo: 22),
      ],
      readiness: readiness(90),
      mainGoal: 'Improve running endurance',
      now: now,
    );
    expect(result.action, RunningCoachAction.progress);
    expect(result.plan.id, 'speed_intervals');
  });

  test('duration progression never exceeds twenty percent', () {
    final current = AdaptiveRunningCoach.steadyBuild;
    final next = AdaptiveRunningCoach.planById('speed_intervals')!;
    expect(next.totalSeconds, lessThanOrEqualTo((current.totalSeconds * 1.2).round()));
  });
}
