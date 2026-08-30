import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/programme_engine.dart';
import 'package:fitness_app_prototype/workout_engine.dart';

void main() {
  const goals = [
    'Build Muscle',
    'Lose Body Fat',
    'Improve General Fitness',
    'Start Running',
    'Improve Running Performance',
    'Gain Weight',
  ];

  test('every generated goal session produces exercises', () {
    for (final goal in goals) {
      final programme = ProgrammeEngine.generate(
        goal: goal,
        experience: 'Intermediate',
        fitnessLevel: 'Moderate',
        availableDays: {
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
        },
        locations: {'Home', 'Gym', 'Outside'},
        sessionLength: '60 min',
        trainingTime: 'Morning',
      );

      expect(programme.sessions, isNotEmpty, reason: goal);

      for (final session in programme.sessions) {
        final workout = WorkoutEngine.generate(
          sessionTitle: session.title,
          location: session.location,
          homeEquipment: {'Bodyweight only'},
          gymAccess: 'Full gym',
          sessionDuration: session.duration,
        );

        expect(
          workout.exercises,
          isNotEmpty,
          reason: '$goal -> ${session.title} -> ${session.location}',
        );
      }
    }
  });

  test('bodyweight-only home workout does not require dumbbells', () {
    final workout = WorkoutEngine.generate(
      sessionTitle: 'Full Body',
      location: 'Home',
      homeEquipment: {'Bodyweight only'},
      sessionDuration: '60 min',
    );

    expect(workout.exercises, isNotEmpty);
    expect(
      workout.exercises.any(
        (exercise) => exercise.equipment.toLowerCase().contains('dumbbell'),
      ),
      isFalse,
    );
  });

  test('15 minute session is shortened to at most three exercises', () {
    final workout = WorkoutEngine.generate(
      sessionTitle: 'Full Body',
      location: 'Gym',
      gymAccess: 'Full gym',
      sessionDuration: '15 min',
    );

    expect(workout.exercises.length, lessThanOrEqualTo(3));
  });

  test('outside running performance session produces a running workout', () {
    final workout = WorkoutEngine.generate(
      sessionTitle: 'Tempo Run',
      location: 'Outside',
      sessionDuration: '60 min',
    );

    expect(workout.exercises, isNotEmpty);
    expect(
      workout.exercises.any((exercise) => exercise.name.contains('Run')),
      isTrue,
    );
  });

  test('unknown session title falls back to a non-empty workout', () {
    final workout = WorkoutEngine.generate(
      sessionTitle: 'Future Session Type',
      location: 'Home',
      homeEquipment: {'Bodyweight only'},
      sessionDuration: '30 min',
    );

    expect(workout.exercises, isNotEmpty);
  });
}
