import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/programme_engine.dart';

void main() {
  test('fitness prototype core engine is available', () {
    final programme = ProgrammeEngine.generate(
      goal: 'Build Muscle',
      experience: 'Beginner',
      fitnessLevel: 'Low',
      availableDays: {'Monday', 'Wednesday', 'Friday'},
      locations: {'Home'},
      sessionLength: '30 min',
      trainingTime: 'Morning',
    );

    expect(programme.sessions, isNotEmpty);
    expect(programme.goal, 'Build Muscle');
  });
}
