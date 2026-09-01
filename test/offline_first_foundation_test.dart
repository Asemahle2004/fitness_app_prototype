import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/offline_programme_exercises.dart';
import 'package:fitness_app_prototype/workout_engine.dart';

void main() {
  group('Offline programme catalogue', () {
    const representativeSessions = <String>[
      'Full Body A',
      'Upper Body A',
      'Lower Body A',
      'Push',
      'Pull',
      'Runner Strength',
      'Mobility + Core',
      'Full Body Conditioning',
    ];

    test('every generated strength/mobility exercise exists in the library seed', () {
      for (final title in representativeSessions) {
        for (final location in const <String>['Home', 'Gym', 'Outside']) {
          final workout = WorkoutEngine.generate(
            sessionTitle: title,
            location: location,
            homeEquipment: const <String>{
              'Dumbbells',
              'Bench',
              'Resistance bands',
              'Barbell',
              'Pull-up bar',
            },
            gymAccess: 'Standard gym',
            sessionDuration: '60 min',
          );

          for (final exercise in workout.exercises) {
            expect(
              offlineProgrammeExerciseNames,
              contains(exercise.name),
              reason: '$title / $location generated ${exercise.name}, which must be available offline in the Exercise Library.',
            );
          }
        }
      }
    });

    test('running/cardio movements used by the engine are also seeded offline', () {
      for (final title in const <String>[
        'Easy Run',
        'Long Easy Run',
        'Recovery Run',
        'Intervals',
        'Tempo Run',
        'Long Run',
      ]) {
        final workout = WorkoutEngine.generate(
          sessionTitle: title,
          location: 'Outside',
          sessionDuration: '45 min',
        );
        for (final exercise in workout.exercises) {
          expect(offlineProgrammeExerciseNames, contains(exercise.name));
        }
      }
    });
  });

  group('Real workout duration budgeting', () {
    GeneratedWorkout fullBody(String duration) => WorkoutEngine.generate(
          sessionTitle: 'Full Body A',
          location: 'Gym',
          gymAccess: 'Standard gym',
          sessionDuration: duration,
        );

    test('45 minute workout includes rest and stays close to 45 minutes', () {
      final workout = fullBody('45 min');
      final estimate = WorkoutEngine.estimateDurationSeconds(
        workout,
        sessionDuration: '45 min',
      );

      expect(estimate, greaterThanOrEqualTo(40 * 60));
      expect(estimate, lessThanOrEqualTo(46 * 60));
      expect(workout.exercises, isNotEmpty);
    });

    test('60 minute workout uses the larger time budget', () {
      final fortyFive = fullBody('45 min');
      final sixty = fullBody('60 min');
      final estimate45 = WorkoutEngine.estimateDurationSeconds(
        fortyFive,
        sessionDuration: '45 min',
      );
      final estimate60 = WorkoutEngine.estimateDurationSeconds(
        sixty,
        sessionDuration: '60 min',
      );

      expect(estimate60, greaterThan(estimate45));
      expect(estimate60, greaterThanOrEqualTo(54 * 60));
      expect(estimate60, lessThanOrEqualTo(61 * 60));
    });

    test('20 and 30 minute workouts do not overflow their selected budget', () {
      for (final duration in const <String>['20 min', '30 min']) {
        final workout = fullBody(duration);
        final targetMinutes = int.parse(duration.split(' ').first);
        final estimate = WorkoutEngine.estimateDurationSeconds(
          workout,
          sessionDuration: duration,
        );
        expect(
          estimate,
          lessThanOrEqualTo((targetMinutes * 60) + 60),
          reason: '$duration programme should include rest without overflowing the selected time.',
        );
      }
    });

    test('continuous run expands to the available session time', () {
      final workout = WorkoutEngine.generate(
        sessionTitle: 'Easy Run',
        location: 'Outside',
        sessionDuration: '45 min',
      );
      final estimate = WorkoutEngine.estimateDurationSeconds(
        workout,
        sessionDuration: '45 min',
      );

      expect(workout.exercises, hasLength(1));
      expect(workout.exercises.single.reps, contains('min'));
      expect(estimate, inInclusiveRange(44 * 60, 46 * 60));
    });
  });
}
