import 'package:fitness_app_prototype/programme_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('muscle fat loss and running share one safe weekly programme', () {
    final programme = ProgrammeEngine.generateForGoals(
      goals: const [
        'Build Muscle',
        'Lose Body Fat',
        'Improve Running Performance',
      ],
      mainGoal: 'Build Muscle',
      experience: 'Intermediate',
      fitnessLevel: 'Moderate',
      availableDays: const {
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
      },
      locations: const {'Gym', 'Outside'},
      sessionLength: '60 min',
      trainingTime: 'Evening',
    );

    expect(programme.sessions, isNotEmpty);
    expect(programme.sessions.length, lessThanOrEqualTo(6));
    expect(programme.goal, contains('Build Muscle'));
    expect(programme.goal, contains('Lose Body Fat'));
    expect(programme.goal, contains('Improve Running Performance'));
    expect(
      programme.sessions.any((s) =>
          s.title.contains('Upper') ||
          s.title.contains('Lower') ||
          s.title.contains('Full Body')),
      isTrue,
    );
    expect(
      programme.sessions.any((s) =>
          s.title.contains('Run') ||
          s.title == 'Intervals' ||
          s.title == 'Tempo Run' ||
          s.title == 'Quality Run'),
      isTrue,
    );
  });

  test('beginner concurrent programme respects limited available days', () {
    final programme = ProgrammeEngine.generateForGoals(
      goals: const ['Build Muscle', 'Start Running'],
      mainGoal: 'Build Muscle',
      experience: 'Beginner',
      fitnessLevel: 'Low',
      activityLevel: 'Mostly inactive',
      availableDays: const {'Monday', 'Wednesday', 'Saturday'},
      locations: const {'Home', 'Outside'},
      homeEquipment: const {'Dumbbells'},
      sessionLength: '30 min',
      trainingTime: 'Morning',
    );

    expect(programme.sessions.length, lessThanOrEqualTo(3));
    expect(programme.sessions.map((s) => s.day).toSet().length,
        programme.sessions.length);
  });

  test('home-only running fallback explains Outside or Gym limitation', () {
    final programme = ProgrammeEngine.generateForGoals(
      goals: const ['Build Muscle', 'Start Running'],
      mainGoal: 'Build Muscle',
      experience: 'Beginner',
      fitnessLevel: 'Low',
      availableDays: const {'Monday', 'Wednesday', 'Saturday'},
      locations: const {'Home'},
      homeEquipment: const {'Dumbbells'},
      sessionLength: '30 min',
      trainingTime: 'Morning',
    );

    expect(programme.explanation, contains('Outside or Gym'));
    expect(programme.sessions.every((s) => s.location == 'Home'), isTrue);
  });
}
