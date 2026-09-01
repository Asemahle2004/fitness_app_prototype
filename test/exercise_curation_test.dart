import 'package:fitness_app_prototype/exercise_curation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseCuration', () {
    test('keeps programme core movements', () {
      expect(
        ExerciseCuration.isApprovedCanonicalName('Barbell Bench Press'),
        isTrue,
      );
      expect(
        ExerciseCuration.isApprovedCanonicalName('Dumbbell Bench Press'),
        isTrue,
      );
      expect(ExerciseCuration.isApprovedCanonicalName('Leg Press'), isTrue);
      expect(ExerciseCuration.isApprovedCanonicalName('Lat Pulldown'), isTrue);
      expect(
        ExerciseCuration.isApprovedCanonicalName('Romanian Deadlift'),
        isTrue,
      );
      expect(ExerciseCuration.isApprovedCanonicalName('Push-Up'), isTrue);
    });

    test('does not approve arbitrary imported catalogue exercises', () {
      expect(
        ExerciseCuration.isApprovedCanonicalName('90/90 Hamstring'),
        isFalse,
      );
      expect(
        ExerciseCuration.isApprovedCanonicalName('Advanced Kettlebell Windmill'),
        isFalse,
      );
      expect(
        ExerciseCuration.isApprovedCanonicalName('Alternate Heel Touchers'),
        isFalse,
      );
    });

    test('recognises only explicit source aliases', () {
      expect(
        ExerciseCuration.isExplicitApprovedSourceName(
          'Barbell Bench Press - Medium Grip',
        ),
        isTrue,
      );
      expect(
        ExerciseCuration.isExplicitApprovedSourceName('Seated Cable Rows'),
        isTrue,
      );
      expect(
        ExerciseCuration.isExplicitApprovedSourceName('Wide-Grip Decline Barbell Bench Press'),
        isFalse,
      );
    });

    test('approved catalogue remains deliberately compact', () {
      expect(ExerciseCuration.approvedCanonicalNames.length, lessThan(100));
      expect(ExerciseCuration.approvedCanonicalNames.length, greaterThan(50));
      expect(
        ExerciseCuration.approvedCanonicalNames.toSet().length,
        ExerciseCuration.approvedCanonicalNames.length,
      );
    });
  });
}
