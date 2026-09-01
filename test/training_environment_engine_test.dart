import 'package:flutter_test/flutter_test.dart';

import '../lib/training_environment_engine.dart';

void main() {
  group('TrainingEnvironmentEngine', () {
    test('normalises environment labels', () {
      expect(TrainingEnvironmentEngine.normalise('Home today'), 'Home');
      expect(TrainingEnvironmentEngine.normalise('Outside run'), 'Outside');
      expect(TrainingEnvironmentEngine.normalise('Full gym'), 'Gym');
    });

    test('bodyweight-only home override removes saved equipment for today', () {
      final equipment = TrainingEnvironmentEngine.effectiveHomeEquipment(
        savedEquipment: {'Dumbbells', 'Bench'},
        todayOverride: {'Bodyweight only'},
      );
      expect(equipment, isEmpty);
    });

    test('switching gym workout to bodyweight home changes exercise slots', () {
      final gym = TrainingEnvironmentEngine.generate(
        sessionTitle: 'Full Body Strength',
        environment: 'Gym',
        sessionDuration: '45 min',
        gymAccess: 'Full gym',
      );
      final home = TrainingEnvironmentEngine.generate(
        sessionTitle: 'Full Body Strength',
        environment: 'Home',
        sessionDuration: '45 min',
        todayHomeEquipment: {'Bodyweight only'},
      );
      final summary = TrainingEnvironmentEngine.compare(
        original: gym,
        originalEnvironment: 'Gym',
        adapted: home,
        adaptedEnvironment: 'Home',
      );

      expect(summary.fromEnvironment, 'Gym');
      expect(summary.toEnvironment, 'Home');
      expect(summary.changed, isTrue);
      expect(summary.changedSlots, greaterThan(0));
      expect(home.exercises.every((exercise) =>
          !exercise.equipment.toLowerCase().contains('machine')),
        isTrue,
      );
    });

    test('today home override does not mutate saved equipment input', () {
      final saved = <String>{'Dumbbells', 'Bench'};
      final effective = TrainingEnvironmentEngine.effectiveHomeEquipment(
        savedEquipment: saved,
        todayOverride: {'Resistance bands'},
      );
      expect(effective, {'Resistance bands'});
      expect(saved, {'Dumbbells', 'Bench'});
    });
  });
}
