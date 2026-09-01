import 'package:fitness_app_prototype/training_settings.dart';
import 'package:fitness_app_prototype/training_tools_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrainingToolsEngine units', () {
    test('round-trips kg and pounds without changing canonical kg', () {
      const kg = 80.0;
      final lb = TrainingToolsEngine.kgToLb(kg);
      final restored = TrainingToolsEngine.lbToKg(lb);

      expect(lb, closeTo(176.37, 0.02));
      expect(restored, closeTo(kg, 0.0001));
    });

    test('formats the same GPS distance in km or miles', () {
      expect(
        TrainingToolsEngine.formatDistanceMeters(5000, UnitSystem.metric),
        '5.00 km',
      );
      expect(
        TrainingToolsEngine.formatDistanceMeters(5000, UnitSystem.imperial),
        '3.11 mi',
      );
    });

    test('converts min per km pace to min per mile', () {
      const fiveMinutesPerKm = 300.0;
      expect(
        TrainingToolsEngine.formatPace(fiveMinutesPerKm, UnitSystem.metric),
        '5:00 /km',
      );
      expect(
        TrainingToolsEngine.formatPace(fiveMinutesPerKm, UnitSystem.imperial),
        '8:03 /mi',
      );
    });
  });

  group('TrainingToolsEngine strength', () {
    test('estimates one rep max with the Epley equation', () {
      final oneRm = TrainingToolsEngine.estimatedOneRepMaxKg(
        weightKg: 60,
        reps: 8,
      );
      expect(oneRm, closeTo(76, 0.01));
    });

    test('one rep input returns the actual lifted weight', () {
      expect(
        TrainingToolsEngine.estimatedOneRepMaxKg(weightKg: 100, reps: 1),
        100,
      );
    });

    test('builds standard working-weight percentages', () {
      final weights = TrainingToolsEngine.workingWeightsKg(100);
      expect(weights[60], 60);
      expect(weights[75], 75);
      expect(weights[90], 90);
    });

    test('loads a 60 kg target correctly on a 20 kg bar', () {
      final result = TrainingToolsEngine.plateLoad(
        targetTotal: 60,
        barWeight: 20,
        availablePlates: const [25, 20, 15, 10, 5, 2.5, 1.25],
      );

      expect(result.platesPerSide, [20]);
      expect(result.achievedTotal, 60);
      expect(result.difference, 0);
    });

    test('plate calculator returns nearest reachable load below target', () {
      final result = TrainingToolsEngine.plateLoad(
        targetTotal: 63,
        barWeight: 20,
        availablePlates: const [20, 10, 5, 2.5, 1.25],
      );

      expect(result.achievedTotal, 62.5);
      expect(result.difference, closeTo(-0.5, 0.001));
    });
  });

  group('TrainingToolsEngine running', () {
    test('calculates 25 minute 5k pace', () {
      final pace = TrainingToolsEngine.paceSecondsPerKm(
        distanceKm: 5,
        durationSeconds: 25 * 60,
      );
      expect(pace, 300);
    });

    test('calculates finish time from distance and pace', () {
      final seconds = TrainingToolsEngine.durationFor(
        distanceKm: 10,
        paceSecondsPerKm: 330,
      );
      expect(seconds, 3300);
    });
  });
}
