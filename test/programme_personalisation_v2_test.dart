import 'package:fitness_app_prototype/programme_engine.dart';
import 'package:fitness_app_prototype/programme_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sixDays = {
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  };

  test('beginner low-fitness general plan stays simple and avoids intervals', () {
    final programme = ProgrammeEngine.generate(
      goal: 'Improve General Fitness',
      experience: 'Beginner',
      fitnessLevel: 'Low',
      activityLevel: 'Mostly sedentary',
      availableDays: sixDays,
      locations: const {'Gym'},
      sessionLength: '45 min',
      trainingTime: 'Evening',
    );

    expect(programme.sessions.length, 3);
    expect(
      programme.sessions.any((session) => session.title == 'Cardio Intervals'),
      isFalse,
    );
    expect(
      programme.sessions.every((session) => session.focus.isNotEmpty),
      isTrue,
    );
    expect(
      programme.sessions.every((session) => session.intensity.isNotEmpty),
      isTrue,
    );
    expect(
      programme.sessions.every((session) => session.personalisationNote.isNotEmpty),
      isTrue,
    );
  });

  test('home-only muscle plan with little resistance equipment caps frequency', () {
    final programme = ProgrammeEngine.generate(
      goal: 'Build Muscle',
      experience: 'Advanced',
      fitnessLevel: 'High',
      activityLevel: 'Very active',
      availableDays: sixDays,
      locations: const {'Home'},
      homeEquipment: const {'None / Bodyweight'},
      sessionLength: '60 min',
      trainingTime: 'Morning',
    );

    expect(programme.sessions.length, 3);
    expect(
      programme.sessions.map((session) => session.title),
      ['Full Body A', 'Full Body B', 'Full Body C'],
    );
    expect(programme.sessions.every((session) => session.location == 'Home'), isTrue);
  });

  test('equipped mixed-location strength plan uses both Home and Gym', () {
    final programme = ProgrammeEngine.generate(
      goal: 'Build Muscle',
      experience: 'Intermediate',
      fitnessLevel: 'Moderate',
      activityLevel: 'Moderately active',
      availableDays: const {'Monday', 'Tuesday', 'Thursday', 'Saturday'},
      locations: const {'Home', 'Gym'},
      homeEquipment: const {'Dumbbells', 'Bench', 'Resistance bands'},
      gymAccess: 'Standard gym',
      sessionLength: '60 min',
      trainingTime: 'Afternoon',
    );

    expect(programme.sessions.length, 4);
    final locations = programme.sessions.map((session) => session.location).toSet();
    expect(locations, contains('Home'));
    expect(locations, contains('Gym'));
    expect(programme.explanation, contains('home-equipment'));
  });

  test('sedentary fat-loss plan does not jump straight to interval sessions', () {
    final programme = ProgrammeEngine.generate(
      goal: 'Lose Body Fat',
      experience: 'Intermediate',
      fitnessLevel: 'Moderate',
      activityLevel: 'Mostly sedentary',
      availableDays: const {'Monday', 'Tuesday', 'Wednesday', 'Friday', 'Saturday'},
      locations: const {'Home', 'Outside'},
      homeEquipment: const {'Resistance bands'},
      sessionLength: '30 min',
      trainingTime: 'Morning',
    );

    expect(
      programme.sessions.any((session) => session.title == 'Cardio Intervals'),
      isFalse,
    );
    expect(programme.sessions.length, lessThanOrEqualTo(4));
  });

  test('running goal still falls back when no running location is available', () {
    final programme = ProgrammeEngine.generate(
      goal: 'Start Running',
      experience: 'Beginner',
      fitnessLevel: 'Low',
      activityLevel: 'Lightly active',
      availableDays: const {'Monday', 'Wednesday', 'Saturday'},
      locations: const {'Home'},
      homeEquipment: const {'Cardio machine'},
      sessionLength: '30 min',
      trainingTime: 'Evening',
    );

    expect(programme.sessions.every((session) => session.location == 'Home'), isTrue);
    expect(programme.explanation, contains('Outside or Gym'));
  });

  test('limitations add safety context without diagnosing the user', () {
    final programme = ProgrammeEngine.generate(
      goal: 'Improve General Fitness',
      experience: 'Beginner',
      fitnessLevel: 'Low',
      activityLevel: 'Lightly active',
      availableDays: const {'Monday', 'Wednesday', 'Friday'},
      locations: const {'Gym'},
      sessionLength: '45 min',
      trainingTime: 'Flexible',
      hasLimitation: true,
      affectedAreas: const {'Knee'},
    );

    expect(programme.explanation, contains('safety engine'));
    expect(programme.explanation.toLowerCase(), isNot(contains('diagnos')));
    expect(
      programme.sessions.every(
        (session) => session.personalisationNote.contains('safety substitutions'),
      ),
      isTrue,
    );
  });

  test('profile activity level changes the programme signature', () {
    final base = <String, dynamic>{
      'main_goal': 'Improve General Fitness',
      'experience': 'Intermediate',
      'fitness_level': 'Moderate',
      'available_days': ['Monday', 'Wednesday', 'Friday', 'Saturday'],
      'training_locations': ['Gym'],
      'home_equipment': <String>[],
      'gym_access': 'Standard gym',
      'session_length': '45 min',
      'training_time': 'Evening',
      'has_limitation': false,
      'affected_areas': <String>[],
      'warning_signs': <String>[],
    };

    final active = {...base, 'activity_level': 'Very active'};
    final sedentary = {...base, 'activity_level': 'Mostly sedentary'};

    expect(
      ProgrammeStore.signatureForProfile(active),
      isNot(ProgrammeStore.signatureForProfile(sedentary)),
    );
  });
}
