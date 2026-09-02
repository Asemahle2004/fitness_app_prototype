import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/periodization_engine.dart';
import 'package:fitness_app_prototype/programme_engine.dart';

PlannedSession session(
  String day,
  String title, {
  String intensity = 'Moderate',
  String focus = 'Balanced training',
}) =>
    PlannedSession(
      day: day,
      title: title,
      location: 'Gym',
      duration: '60 min',
      focus: focus,
      intensity: intensity,
    );

void main() {
  group('PeriodizationEngine', () {
    test('uses an eight-week block with planned recovery at week eight', () {
      final plan = PeriodizationEngine.forWeek(
        programmeWeek: 8,
        progressionSupported: true,
        goals: const ['Build Muscle'],
      );

      expect(plan.blockNumber, 1);
      expect(plan.weekInBlock, 8);
      expect(plan.phase, TrainingBlockPhase.deload);
      expect(plan.plannedRecovery, isTrue);
      expect(plan.sessionVolumeMultiplier, lessThanOrEqualTo(0.70));
      expect(plan.allowDropSets, isFalse);
      expect(plan.allowSupersets, isFalse);
    });

    test('week nine starts a fresh second block', () {
      final plan = PeriodizationEngine.forWeek(
        programmeWeek: 9,
        goals: const ['Build Muscle'],
      );

      expect(plan.blockNumber, 2);
      expect(plan.weekInBlock, 1);
      expect(plan.phase, TrainingBlockPhase.foundation);
    });

    test('fatigue evidence overrides calendar build week with deload', () {
      final plan = PeriodizationEngine.forWeek(
        programmeWeek: 3,
        forceRecovery: true,
        progressionSupported: true,
      );

      expect(plan.phase, TrainingBlockPhase.deload);
      expect(plan.plannedRecovery, isFalse);
      expect(plan.sessionVolumeMultiplier, lessThan(0.70));
      expect(plan.workingLoadMultiplier, lessThan(1));
    });

    test('calendar never forces intensification without progression evidence', () {
      final held = PeriodizationEngine.forWeek(
        programmeWeek: 6,
        progressionSupported: false,
      );
      final progressed = PeriodizationEngine.forWeek(
        programmeWeek: 6,
        progressionSupported: true,
      );

      expect(held.phase, TrainingBlockPhase.build);
      expect(progressed.phase, TrainingBlockPhase.intensify);
    });

    test('deload never adds sessions and trims a high-stress slot in long weeks', () {
      final base = [
        session('Monday', 'Upper Strength'),
        session('Tuesday', 'Speed Intervals', intensity: 'Hard'),
        session('Thursday', 'Lower Strength', intensity: 'High'),
        session('Saturday', 'Easy Cardio'),
        session('Sunday', 'Mobility Recovery'),
      ];
      final plan = PeriodizationEngine.forWeek(
        programmeWeek: 2,
        forceRecovery: true,
      );
      final adapted = PeriodizationEngine.adaptSessions(base, plan);

      expect(adapted.length, lessThan(base.length));
      expect(adapted.length, lessThanOrEqualTo(base.length));
      expect(adapted.every((item) => item.duration != '60 min'), isTrue);
      expect(adapted.any((item) => item.title == 'Mobility Recovery'), isTrue);
    });

    test('three-session beginner deload keeps frequency but reduces workload', () {
      final base = [
        session('Monday', 'Full Body A'),
        session('Wednesday', 'Full Body B'),
        session('Friday', 'Full Body C'),
      ];
      final plan = PeriodizationEngine.forWeek(
        programmeWeek: 3,
        forceRecovery: true,
      );
      final adapted = PeriodizationEngine.adaptSessions(base, plan);

      expect(adapted.length, 3);
      expect(adapted.every((item) => item.duration == '45 min'), isTrue);
      expect(adapted.every((item) => item.intensity.contains('deload')), isTrue);
    });

    test('recovery plan downgrades adjacent hard sessions rather than moving them', () {
      final base = [
        session('Monday', 'Lower Strength', intensity: 'Hard'),
        session('Tuesday', 'Speed Intervals', intensity: 'Hard'),
        session('Friday', 'Upper Strength'),
      ];
      final plan = PeriodizationEngine.forWeek(
        programmeWeek: 5,
        forceRecovery: true,
      );
      final adapted = PeriodizationEngine.adaptSessions(base, plan);

      expect(adapted.map((item) => item.day).toList(),
          containsAll(<String>['Monday', 'Tuesday', 'Friday']));
      expect(
        adapted.firstWhere((item) => item.day == 'Tuesday').intensity,
        contains('recovery-protected'),
      );
    });

    test('running emphasis does not enable gym intensity techniques', () {
      final plan = PeriodizationEngine.forWeek(
        programmeWeek: 6,
        progressionSupported: true,
        goals: const ['Improve Running Performance'],
      );

      expect(plan.goalEmphasis, 'running');
      expect(plan.allowDropSets, isFalse);
    });
  });
}
