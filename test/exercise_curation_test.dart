import 'package:fitness_app_prototype/exercise_curation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseCuration', () {
    test('keeps original programme core movements', () {
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

    test('adds researched muscle cardio mobility and running movements', () {
      expect(ExerciseCuration.isApprovedCanonicalName('Chin Tuck'), isTrue);
      expect(
        ExerciseCuration.isApprovedCanonicalName('Bayesian Cable Curl'),
        isTrue,
      );
      expect(
        ExerciseCuration.isApprovedCanonicalName('Copenhagen Side Plank'),
        isTrue,
      );
      expect(
        ExerciseCuration.isApprovedCanonicalName('Wall Tibialis Raise'),
        isTrue,
      );
      expect(ExerciseCuration.isApprovedCanonicalName('A-Skip'), isTrue);
      expect(
        ExerciseCuration.isApprovedCanonicalName("World's Greatest Stretch"),
        isTrue,
      );
    });

    test('does not approve arbitrary imported catalogue exercises', () {
      expect(
        ExerciseCuration.isApprovedCanonicalName('Random Unreviewed Exercise'),
        isFalse,
      );
      expect(
        ExerciseCuration.isApprovedCanonicalName('Unsafe Mystery Movement'),
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
        ExerciseCuration.isExplicitApprovedSourceName(
          'Wide-Grip Decline Barbell Bench Press',
        ),
        isFalse,
      );
    });

    test('approved catalogue is comprehensive and unique', () {
      expect(ExerciseCuration.approvedCanonicalNames.length, greaterThan(400));
      expect(ExerciseCuration.approvedCanonicalNames.length, lessThan(600));
      expect(
        ExerciseCuration.approvedCanonicalNames.toSet().length,
        ExerciseCuration.approvedCanonicalNames.length,
      );
    });
  });
}
