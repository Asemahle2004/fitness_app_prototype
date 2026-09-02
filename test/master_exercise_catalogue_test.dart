import 'package:fitness_app_prototype/master_exercise_catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MasterExerciseCatalogue', () {
    test('contains a large deduplicated master catalogue', () {
      expect(MasterExerciseCatalogue.definitions.length, greaterThan(400));
      final normalized = MasterExerciseCatalogue.definitions
          .map((item) => MasterExerciseCatalogue.normalize(item.name))
          .toSet();
      expect(normalized.length, MasterExerciseCatalogue.definitions.length);
    });

    test('keeps the library in human-readable anatomical order', () {
      expect(MasterExerciseCatalogue.sectionOrder.first, 'Neck');
      expect(
        MasterExerciseCatalogue.sectionOrder.indexOf('Chest'),
        lessThan(MasterExerciseCatalogue.sectionOrder.indexOf('Glutes')),
      );
      expect(
        MasterExerciseCatalogue.sectionOrder.indexOf('Quadriceps'),
        lessThan(MasterExerciseCatalogue.sectionOrder.indexOf('Cardio')),
      );
      expect(MasterExerciseCatalogue.sectionOrder.last,
          'Running Stretching & Mobility');
    });

    test('large muscle categories have deep exercise choice', () {
      expect(MasterExerciseCatalogue.namesForSection('Shoulders').length,
          greaterThanOrEqualTo(20));
      expect(MasterExerciseCatalogue.namesForSection('Biceps').length,
          greaterThanOrEqualTo(20));
      expect(MasterExerciseCatalogue.namesForSection('Triceps').length,
          greaterThanOrEqualTo(20));
      expect(MasterExerciseCatalogue.namesForSection('Forearms & Grip').length,
          greaterThanOrEqualTo(20));
      expect(MasterExerciseCatalogue.namesForSection('Chest').length,
          greaterThanOrEqualTo(20));
      expect(MasterExerciseCatalogue.namesForSection('Abs / Six-Pack').length,
          greaterThanOrEqualTo(20));
      expect(MasterExerciseCatalogue.namesForSection('Core & Obliques').length,
          greaterThanOrEqualTo(20));
      expect(MasterExerciseCatalogue.namesForSection('Back').length,
          greaterThanOrEqualTo(20));
      expect(MasterExerciseCatalogue.namesForSection('Quadriceps').length,
          greaterThanOrEqualTo(20));
      expect(MasterExerciseCatalogue.namesForSection('Hamstrings').length,
          greaterThanOrEqualTo(20));
      expect(MasterExerciseCatalogue.namesForSection('Calves').length,
          greaterThanOrEqualTo(20));
      expect(MasterExerciseCatalogue.namesForSection('Full Body').length,
          greaterThanOrEqualTo(20));
    });

    test('cardio warm-up and running phases are represented', () {
      expect(MasterExerciseCatalogue.namesForSection('Cardio').length,
          greaterThanOrEqualTo(20));
      expect(MasterExerciseCatalogue.namesForSection('General Warm-Up').length,
          greaterThanOrEqualTo(20));
      expect(MasterExerciseCatalogue.namesForSection('General Cooldown').length,
          greaterThanOrEqualTo(15));
      expect(
        MasterExerciseCatalogue.namesForSection('Stretching & Mobility').length,
        greaterThanOrEqualTo(20),
      );
      expect(MasterExerciseCatalogue.namesForSection('Running Warm-Up').length,
          greaterThanOrEqualTo(20));
      expect(MasterExerciseCatalogue.namesForSection('Sprint Warm-Up').length,
          greaterThanOrEqualTo(20));
      expect(
        MasterExerciseCatalogue.namesForSection('Running Drills & Technique')
            .length,
        greaterThanOrEqualTo(20),
      );
      expect(
        MasterExerciseCatalogue.namesForSection(
                'Running Stretching & Mobility')
            .length,
        greaterThanOrEqualTo(20),
      );
    });

    test('one movement can belong to multiple useful filters', () {
      final farmer = MasterExerciseCatalogue.findByName("Farmer's Carry");
      expect(farmer, isNotNull);
      expect(farmer!.groups, contains('Forearms & Grip'));
      expect(farmer.groups, contains('Core & Obliques'));
      expect(farmer.groups, contains('Traps & Upper Back'));
      expect(farmer.groups, contains('Whole Upper Body'));
      expect(farmer.groups, contains('Full Body'));

      final deadBug = MasterExerciseCatalogue.findByName('Dead Bug');
      expect(deadBug!.groups, contains('Abs / Six-Pack'));
      expect(deadBug.groups, contains('Core & Obliques'));
    });

    test('running preparation is not mixed into strength type', () {
      final aSkip = MasterExerciseCatalogue.findByName('A-Skip');
      expect(aSkip, isNotNull);
      expect(aSkip!.groups, contains('Running Warm-Up'));
      expect(aSkip.groups, contains('Sprint Warm-Up'));
      expect(aSkip.groups, contains('Running Drills & Technique'));
      expect(aSkip.exerciseType, 'Running Warm-Up');
    });
  });
}
