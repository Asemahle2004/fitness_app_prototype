import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/programme_store.dart';

Map<String, dynamic> profile(List<String> goals) => <String, dynamic>{
      'main_goal': 'Build Muscle',
      'goals': goals,
      'experience': 'Beginner',
      'fitness_level': 'Low',
      'activity_level': 'Moderately active',
      'available_days': ['Monday', 'Wednesday', 'Friday', 'Saturday'],
      'training_locations': ['Gym', 'Outside'],
      'home_equipment': <String>[],
      'gym_access': 'Full gym',
      'session_length': '60 min',
      'training_time': 'Flexible',
      'has_limitation': false,
      'affected_areas': <String>[],
      'warning_signs': <String>[],
    };

void main() {
  test('secondary goal changes programme profile signature', () {
    final muscleOnly = ProgrammeStore.signatureForProfile(
      profile(['Build Muscle']),
    );
    final concurrent = ProgrammeStore.signatureForProfile(
      profile(['Build Muscle', 'Improve Running Performance']),
    );

    expect(muscleOnly, isNot(equals(concurrent)));
  });

  test('goal order does not create a false programme change', () {
    final a = ProgrammeStore.signatureForProfile(
      profile(['Build Muscle', 'Lose Body Fat', 'Start Running']),
    );
    final b = ProgrammeStore.signatureForProfile(
      profile(['Start Running', 'Build Muscle', 'Lose Body Fat']),
    );

    expect(a, equals(b));
  });

  test('programme generation reads complete saved goal set', () {
    final generated = ProgrammeStore.programmeFromProfile(
      profile(['Build Muscle', 'Lose Body Fat', 'Improve Running Performance']),
    );

    expect(generated.goal, contains('Build Muscle'));
    expect(generated.goal, contains('Lose Body Fat'));
    expect(generated.goal, contains('Improve Running Performance'));
  });
}
