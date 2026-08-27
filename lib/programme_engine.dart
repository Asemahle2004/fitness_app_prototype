class PlannedSession {
  final String day;
  final String title;
  final String location;
  final String duration;

  const PlannedSession({
    required this.day,
    required this.title,
    required this.location,
    required this.duration,
  });
}

class GeneratedProgramme {
  final String goal;
  final String structure;
  final String explanation;
  final List<PlannedSession> sessions;

  const GeneratedProgramme({
    required this.goal,
    required this.structure,
    required this.explanation,
    required this.sessions,
  });
}

class ProgrammeEngine {
  static const List<String> _weekOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static GeneratedProgramme generate({
    required String goal,
    required String experience,
    required String fitnessLevel,
    required Set<String> availableDays,
    required Set<String> locations,
    required String sessionLength,
    required String trainingTime,
  }) {
    final sortedDays = availableDays.toList()
      ..sort((a, b) => _weekOrder.indexOf(a).compareTo(_weekOrder.indexOf(b)));

    if (goal != 'Build Muscle') {
      return GeneratedProgramme(
        goal: goal,
        structure: 'Coming soon',
        explanation:
            'Prototype 1 currently generates Build Muscle programmes first. This goal will be added after the first engine is tested.',
        sessions: const [],
      );
    }

    final int sessionCount = _chooseSessionCount(
      experience: experience,
      availableDays: sortedDays.length,
    );

    final selectedTrainingDays = _spreadTrainingDays(sortedDays, sessionCount);

    final titles = _chooseWorkoutTitles(
      experience: experience,
      sessionCount: sessionCount,
    );

    final location = _chooseLocation(locations);

    final sessions = <PlannedSession>[];

    for (int i = 0; i < selectedTrainingDays.length; i++) {
      sessions.add(
        PlannedSession(
          day: selectedTrainingDays[i],
          title: titles[i],
          location: location,
          duration: sessionLength,
        ),
      );
    }

    return GeneratedProgramme(
      goal: goal,
      structure: _structureName(experience, sessionCount),
      explanation:
          'You are available ${sortedDays.length} day(s) per week. '
          'The prototype selected $sessionCount structured resistance-training session(s) and spread them across your available days. '
          'Your normal training time is $trainingTime.',
      sessions: sessions,
    );
  }

  static int _chooseSessionCount({
    required String experience,
    required int availableDays,
  }) {
    if (availableDays <= 0) {
      return 0;
    }

    if (experience == 'Beginner') {
      if (availableDays >= 3) return 3;
      return availableDays;
    }

    if (experience == 'Intermediate') {
      if (availableDays >= 4) return 4;
      return availableDays;
    }

    if (experience == 'Experienced') {
      if (availableDays >= 5) return 5;
      return availableDays;
    }

    return availableDays > 3 ? 3 : availableDays;
  }

  static List<String> _spreadTrainingDays(
    List<String> availableDays,
    int sessionCount,
  ) {
    if (sessionCount <= 0 || availableDays.isEmpty) {
      return [];
    }

    if (sessionCount >= availableDays.length) {
      return List<String>.from(availableDays);
    }

    if (sessionCount == 1) {
      return [availableDays.first];
    }

    final result = <String>[];

    for (int i = 0; i < sessionCount; i++) {
      final double position =
          i * (availableDays.length - 1) / (sessionCount - 1);

      int index = position.round();

      if (!result.contains(availableDays[index])) {
        result.add(availableDays[index]);
      }
    }

    // Fallback in case rounding ever produces a duplicate.
    for (final day in availableDays) {
      if (result.length >= sessionCount) break;

      if (!result.contains(day)) {
        result.add(day);
      }
    }

    result.sort(
      (a, b) => _weekOrder.indexOf(a).compareTo(_weekOrder.indexOf(b)),
    );

    return result;
  }

  static List<String> _chooseWorkoutTitles({
    required String experience,
    required int sessionCount,
  }) {
    if (sessionCount == 1) {
      return ['Full Body'];
    }

    if (sessionCount == 2) {
      return ['Full Body A', 'Full Body B'];
    }

    if (sessionCount == 3) {
      if (experience == 'Experienced') {
        return ['Upper Body', 'Lower Body', 'Full Body'];
      }

      return ['Full Body A', 'Full Body B', 'Full Body C'];
    }

    if (sessionCount == 4) {
      return ['Upper Body A', 'Lower Body A', 'Upper Body B', 'Lower Body B'];
    }

    return ['Push', 'Pull', 'Lower Body', 'Upper Body', 'Lower Body'];
  }

  static String _chooseLocation(Set<String> locations) {
    final hasGym = locations.contains('Gym');
    final hasHome = locations.contains('Home');

    if (hasGym && hasHome) {
      return 'Gym / Home';
    }

    if (hasGym) {
      return 'Gym';
    }

    if (hasHome) {
      return 'Home';
    }

    if (locations.contains('Outside')) {
      return 'Outside';
    }

    return 'Flexible';
  }

  static String _structureName(String experience, int sessionCount) {
    if (sessionCount <= 3) {
      return 'Full-body structure';
    }

    if (sessionCount == 4) {
      return 'Upper / Lower structure';
    }

    return '5-session split';
  }
}
