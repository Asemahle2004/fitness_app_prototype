import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/exercise_media_coverage_service.dart';
import 'package:fitness_app_prototype/master_exercise_catalogue.dart';
import 'package:fitness_app_prototype/musclewiki_media_service.dart';

void main() {
  const definitions = <MasterExerciseDefinition>[
    MasterExerciseDefinition(
      name: 'Bench Press',
      section: 'Chest',
      exerciseType: 'Strength & Muscle',
      groups: ['Chest'],
    ),
    MasterExerciseDefinition(
      name: 'Goblet Squat',
      section: 'Quadriceps',
      exerciseType: 'Strength & Muscle',
      groups: ['Quadriceps'],
    ),
  ];

  test('counts male and female media independently', () async {
    final service = ExerciseMediaCoverageService(
      resolver: ({required exerciseName, required sex}) async {
        final available = exerciseName == 'Bench Press' || sex == 'Male';
        return MuscleWikiMediaResult(
          available: available,
          providerExerciseId: exerciseName == 'Bench Press' ? 10 : 20,
          reason: available ? null : 'missing_female',
        );
      },
    );

    final report = await service.audit(definitions: definitions);

    expect(report.totalExercises, 2);
    expect(report.expectedSides, 4);
    expect(report.availableSides, 3);
    expect(report.completeExercises, 1);
    expect(report.missingExercises, 1);
    expect(report.coveragePercent, 75);
    expect(report.incomplete.single.exerciseName, 'Goblet Squat');
    expect(report.missingBySection['Quadriceps'], 1);
  });

  test('master catalogue has a deterministic provider key for every exercise', () {
    expect(MasterExerciseCatalogue.definitions.length, greaterThan(400));
    for (final definition in MasterExerciseCatalogue.definitions) {
      final key = ExerciseMediaCoverageService.canonicalProviderKey(
        definition.name,
      );
      expect(key, isNotEmpty, reason: definition.name);
    }
  });
}
