import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/running_distance_engine.dart';

void main() {
  group('RunningDistanceEngine', () {
    test('every supported event generates at least its minimum plan length', () {
      for (final goal in RunningGoalDistance.values) {
        final plan = RunningDistanceEngine.generate(
          RunningPlanConfig(
            goal: goal,
            daysPerWeek: goal.recommendedDaysPerWeek,
            totalWeeks: goal.minimumRecommendedWeeks,
          ),
        );
        expect(plan.weeks.length, greaterThanOrEqualTo(goal.minimumRecommendedWeeks));
        expect(plan.weeks.every((week) => week.sessions.isNotEmpty), isTrue);
      }
    });

    test('100 m plan is sprint quality, not long-run training', () {
      final plan = RunningDistanceEngine.generate(
        const RunningPlanConfig(
          goal: RunningGoalDistance.m100,
          daysPerWeek: 4,
          totalWeeks: 8,
        ),
      );
      final types = plan.weeks.first.sessions.map((item) => item.type).toSet();
      expect(types, contains(RunningSessionType.acceleration));
      expect(types, contains(RunningSessionType.maxVelocity));
      expect(types, contains(RunningSessionType.speedEndurance));
      expect(types, isNot(contains(RunningSessionType.longRun)));
      expect(types, isNot(contains(RunningSessionType.threshold)));
      expect(plan.weeks.first.plannedKm, 0);
    });

    test('400 m plan uses long-sprint speed endurance', () {
      final plan = RunningDistanceEngine.generate(
        const RunningPlanConfig(
          goal: RunningGoalDistance.m400,
          daysPerWeek: 3,
          totalWeeks: 8,
        ),
      );
      final session = plan.weeks.first.sessions.firstWhere(
        (item) => item.type == RunningSessionType.speedEndurance,
      );
      expect(session.repetitionDistanceMeters, 200);
      expect(session.recoverySeconds, greaterThanOrEqualTo(300));
    });

    test('marathon has long runs and final two taper weeks', () {
      final plan = RunningDistanceEngine.generate(
        const RunningPlanConfig(
          goal: RunningGoalDistance.marathon,
          daysPerWeek: 4,
          totalWeeks: 16,
          recentWeeklyKm: 30,
        ),
      );
      expect(
        plan.weeks.take(12).any(
              (week) => week.sessions.any(
                (item) => item.type == RunningSessionType.longRun,
              ),
            ),
        isTrue,
      );
      expect(plan.weeks[14].taperWeek, isTrue);
      expect(plan.weeks[15].taperWeek, isTrue);
    });

    test('every fourth non-taper week consolidates load', () {
      final plan = RunningDistanceEngine.generate(
        const RunningPlanConfig(
          goal: RunningGoalDistance.k10,
          daysPerWeek: 4,
          totalWeeks: 12,
          recentWeeklyKm: 20,
        ),
      );
      expect(plan.weeks[3].recoveryWeek, isTrue);
      expect(plan.weeks[7].recoveryWeek, isTrue);
    });

    test('pace zones require an aerobic benchmark', () {
      expect(
        RunningDistanceEngine.paceZones(distanceMeters: 100, seconds: 13),
        isNull,
      );
      final zones = RunningDistanceEngine.paceZones(
        distanceMeters: 5000,
        seconds: 1500,
      );
      expect(zones, isNotNull);
      expect(zones!.easyMaxSecondsPerKm, greaterThan(zones.thresholdSecondsPerKm));
    });

    test('sprint benchmark is not extrapolated into marathon prediction', () {
      final prediction = RunningDistanceEngine.predict(
        benchmarkDistanceMeters: 100,
        benchmarkSeconds: 13,
        goal: RunningGoalDistance.marathon,
      );
      expect(prediction, isNull);
    });

    test('100 m heat guidance stays effort based', () {
      final adjustment = RunningDistanceEngine.weatherAdjustment(
        goal: RunningGoalDistance.m100,
        temperatureC: 34,
        humidityPercent: 70,
      );
      expect(adjustment.paceMultiplier, 1);
      expect(adjustment.preferEffortOverPace, isTrue);
    });

    test('hot humid endurance weather slows pace target', () {
      final adjustment = RunningDistanceEngine.weatherAdjustment(
        goal: RunningGoalDistance.k10,
        temperatureC: 32,
        humidityPercent: 80,
      );
      expect(adjustment.paceMultiplier, greaterThan(1));
      expect(adjustment.adjustPace(300), greaterThan(300));
    });

    test('very low readiness blocks hard running', () {
      final adjustment = RunningDistanceEngine.dayAdjustment(
        readinessScore: 30,
      );
      expect(adjustment.allowHardWork, isFalse);
      expect(adjustment.replaceWithRecovery, isTrue);
    });
  });
}
