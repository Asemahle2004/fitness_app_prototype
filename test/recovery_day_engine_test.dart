import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/recovery_day_engine.dart';
import 'package:fitness_app_prototype/training_store.dart';

ReadinessRecord readiness({
  double sleep = 3,
  double energy = 3,
  double soreness = 3,
  double stress = 3,
}) {
  return ReadinessRecord(
    recordedAt: DateTime(2026, 9, 1, 8),
    sleep: sleep,
    energy: energy,
    soreness: soreness,
    stress: stress,
  );
}

void main() {
  test('recovery is offered below sixty readiness', () {
    final low = readiness(sleep: 2, energy: 2, soreness: 4, stress: 4);
    final good = readiness(sleep: 4, energy: 4, soreness: 2, stress: 2);

    expect(RecoveryDayEngine.shouldOffer(low), isTrue);
    expect(RecoveryDayEngine.shouldOffer(good), isFalse);
  });

  test('very low readiness creates a short gentle plan', () {
    final record = readiness(sleep: 1, energy: 1, soreness: 5, stress: 5);
    final plan = RecoveryDayEngine.forReadiness(
      record,
      locations: {'Home', 'Gym'},
    );

    expect(plan.location, 'Home');
    expect(plan.title, contains('Recovery Day'));
    expect(plan.totalSeconds, greaterThanOrEqualTo(600));
    expect(plan.totalSeconds, lessThanOrEqualTo(1200));
    expect(plan.steps.any((step) => step.name == 'Slow breathing'), isTrue);
  });

  test('outside profile uses walking for easy recovery movement', () {
    final record = readiness(sleep: 2, energy: 2, soreness: 4, stress: 3);
    final plan = RecoveryDayEngine.forReadiness(
      record,
      locations: {'Outside'},
    );

    expect(plan.location, 'Outside');
    expect(plan.steps.first.name, 'Easy walk');
  });

  test('gym-only profile uses treadmill or bike recovery', () {
    final record = readiness(sleep: 2, energy: 3, soreness: 4, stress: 3);
    final plan = RecoveryDayEngine.forReadiness(
      record,
      locations: {'Gym'},
    );

    expect(plan.location, 'Gym');
    expect(plan.steps.first.name, contains('treadmill'));
  });

  test('today check-in only matches the same calendar day', () {
    final record = readiness();

    expect(
      RecoveryDayEngine.isTodaysCheckIn(
        record,
        now: DateTime(2026, 9, 1, 23, 59),
      ),
      isTrue,
    );
    expect(
      RecoveryDayEngine.isTodaysCheckIn(
        record,
        now: DateTime(2026, 9, 2, 0, 1),
      ),
      isFalse,
    );
  });
}
