import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/guided_run_engine.dart';

void main() {
  test('starter plans have usable timed phases', () {
    expect(GuidedRunEngine.starterPlans, isNotEmpty);
    for (final plan in GuidedRunEngine.starterPlans) {
      expect(plan.steps, isNotEmpty);
      expect(plan.totalSeconds, greaterThan(0));
      expect(plan.steps.every((step) => step.durationSeconds > 0), isTrue);
      expect(
        plan.steps.any((step) => step.type == GuidedRunPhaseType.run),
        isTrue,
      );
      expect(plan.steps.first.type, GuidedRunPhaseType.warmUp);
      expect(plan.steps.last.type, GuidedRunPhaseType.coolDown);
    }
  });

  test('progress moves from warm-up into first running phase', () {
    final plan = GuidedRunEngine.starterPlans.first;
    final before = GuidedRunEngine.progressFor(plan, 299);
    final after = GuidedRunEngine.progressFor(plan, 300);

    expect(before.step?.type, GuidedRunPhaseType.warmUp);
    expect(before.secondsRemainingInStep, 1);
    expect(after.step?.type, GuidedRunPhaseType.run);
    expect(after.stepIndex, 1);
    expect(after.secondsIntoStep, 0);
  });

  test('pause-safe progress depends only on active elapsed seconds', () {
    final plan = GuidedRunEngine.starterPlans.first;
    final first = GuidedRunEngine.progressFor(plan, 375);
    final unchanged = GuidedRunEngine.progressFor(plan, 375);

    expect(unchanged.stepIndex, first.stepIndex);
    expect(unchanged.secondsRemainingInStep, first.secondsRemainingInStep);
  });

  test('nextStep returns the following interval', () {
    final plan = GuidedRunEngine.starterPlans.first;
    final progress = GuidedRunEngine.progressFor(plan, 300);
    final next = GuidedRunEngine.nextStep(plan, progress);

    expect(progress.step?.type, GuidedRunPhaseType.run);
    expect(next, isNotNull);
    expect(next!.type, GuidedRunPhaseType.recover);
  });

  test('plan becomes complete exactly at total duration', () {
    final plan = GuidedRunEngine.starterPlans.first;
    final lastSecond = GuidedRunEngine.progressFor(plan, plan.totalSeconds - 1);
    final complete = GuidedRunEngine.progressFor(plan, plan.totalSeconds);

    expect(lastSecond.complete, isFalse);
    expect(complete.complete, isTrue);
    expect(complete.step, isNull);
    expect(complete.totalSecondsRemaining, 0);
  });
}
