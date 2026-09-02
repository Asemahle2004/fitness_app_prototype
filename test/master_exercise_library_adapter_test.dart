import 'package:fitness_app_prototype/master_exercise_catalogue.dart';
import 'package:fitness_app_prototype/master_exercise_library_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MasterExerciseLibraryAdapter', () {
    test('creates a selectable record for every master exercise', () {
      final library = MasterExerciseLibraryAdapter.mergeWithSource(const []);
      expect(library.length, MasterExerciseCatalogue.definitions.length);
      expect(library.map((item) => item.name).toSet().length, library.length);
    });

    test('strength exercises keep their anatomical workout category', () {
      final library = MasterExerciseLibraryAdapter.mergeWithSource(const []);
      final bench = library.firstWhere(
        (item) => item.name == 'Barbell Bench Press',
      );
      expect(bench.category, 'Chest');
    });

    test('warm-ups and running drills use timed workout-builder defaults', () {
      final library = MasterExerciseLibraryAdapter.mergeWithSource(const []);
      final aSkip = library.firstWhere((item) => item.name == 'A-Skip');
      final warmUp = library.firstWhere((item) => item.name == 'Arm Circles');
      expect(aSkip.category!.toLowerCase(), contains('cardio'));
      expect(warmUp.category!.toLowerCase(), contains('cardio'));
    });

    test('cooldowns and mobility use stretch-style workout defaults', () {
      final library = MasterExerciseLibraryAdapter.mergeWithSource(const []);
      final calfStretch = library.firstWhere(
        (item) => item.name == 'Calf Stretch',
      );
      final easyWalk = library.firstWhere(
        (item) => item.name == 'Easy Walking',
      );
      expect(calfStretch.category!.toLowerCase(), contains('stretch'));
      expect(easyWalk.category!.toLowerCase(), contains('stretch'));
    });
  });
}
