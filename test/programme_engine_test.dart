import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/programme_engine.dart';

void main() {
  const goals = [
    'Build Muscle',
    'Lose Body Fat',
    'Improve General Fitness',
    'Start Running',
    'Improve Running Performance',
    'Gain Weight',
  ];

  final availableDays = {
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  };

  for (final goal in goals) {
    test('$goal generates a usable programme', () {
      final programme = ProgrammeEngine.generate(
        goal: goal,
        experience: 'Intermediate',
        fitnessLevel: 'Moderate',
        availableDays: availableDays,
        locations: {'Home', 'Gym', 'Outside'},
        sessionLength: '60 min',
        trainingTime: 'Morning',
      );

      expect(programme.sessions, isNotEmpty);
      expect(programme.structure, isNotEmpty);
      expect(programme.explanation, isNotEmpty);
      expect(programme.sessions.length, lessThanOrEqualTo(availableDays.length));

      for (final session in programme.sessions) {
        expect(availableDays, contains(session.day));
        expect(session.title, isNotEmpty);
        expect(session.location, isNotEmpty);
        expect(session.duration, '60 min');
      }
    });
  }

  test('Start Running prefers an actual running location when available', () {
    final programme = ProgrammeEngine.generate(
      goal: 'Start Running',
      experience: 'Beginner',
      fitnessLevel: 'Low',
      availableDays: {'Monday', 'Wednesday', 'Saturday'},
      locations: {'Home', 'Outside'},
      sessionLength: '30 min',
      trainingTime: 'Evening',
    );

    expect(programme.sessions, isNotEmpty);
    expect(
      programme.sessions.any((session) => session.location == 'Outside'),
      isTrue,
    );
  });

  test('Running goal has a home fallback when no running location exists', () {
    final programme = ProgrammeEngine.generate(
      goal: 'Start Running',
      experience: 'Beginner',
      fitnessLevel: 'Low',
      availableDays: {'Monday', 'Wednesday', 'Saturday'},
      locations: {'Home'},
      sessionLength: '30 min',
      trainingTime: 'Evening',
    );

    expect(programme.sessions, isNotEmpty);
    expect(programme.sessions.every((session) => session.location == 'Home'), isTrue);
    expect(programme.explanation, contains('Outside or Gym'));
  });
}
