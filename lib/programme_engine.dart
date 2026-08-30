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

  static const Set<String> supportedGoals = {
    'Build Muscle',
    'Lose Body Fat',
    'Improve General Fitness',
    'Start Running',
    'Improve Running Performance',
    'Gain Weight',
  };

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

    if (!supportedGoals.contains(goal)) {
      return GeneratedProgramme(
        goal: goal,
        structure: 'Goal not supported',
        explanation:
            'Choose one of the supported goals so a programme can be generated.',
        sessions: const [],
      );
    }

    if (sortedDays.isEmpty) {
      return GeneratedProgramme(
        goal: goal,
        structure: 'No training days selected',
        explanation:
            'Select at least one available day before creating a programme.',
        sessions: const [],
      );
    }

    final sessionCount = _chooseSessionCount(
      goal: goal,
      experience: experience,
      fitnessLevel: fitnessLevel,
      availableDays: sortedDays.length,
    );

    final selectedTrainingDays = _spreadTrainingDays(sortedDays, sessionCount);
    final titles = _titlesForGoal(
      goal: goal,
      experience: experience,
      sessionCount: sessionCount,
      locations: locations,
    );

    final sessions = <PlannedSession>[];

    for (int i = 0; i < selectedTrainingDays.length; i++) {
      final title = titles[i % titles.length];
      sessions.add(
        PlannedSession(
          day: selectedTrainingDays[i],
          title: title,
          location: _locationForSession(title, locations),
          duration: sessionLength,
        ),
      );
    }

    return GeneratedProgramme(
      goal: goal,
      structure: _structureName(goal, experience, sessionCount),
      explanation: _explanation(
        goal: goal,
        trainingDays: sortedDays.length,
        sessionCount: sessionCount,
        trainingTime: trainingTime,
        locations: locations,
      ),
      sessions: sessions,
    );
  }

  static int _chooseSessionCount({
    required String goal,
    required String experience,
    required String fitnessLevel,
    required int availableDays,
  }) {
    if (availableDays <= 0) return 0;

    int preferred;

    switch (goal) {
      case 'Build Muscle':
      case 'Gain Weight':
        if (experience == 'Beginner') {
          preferred = 3;
        } else if (experience == 'Intermediate') {
          preferred = 4;
        } else {
          preferred = 5;
        }
        break;

      case 'Lose Body Fat':
        if (experience == 'Beginner') {
          preferred = 3;
        } else if (experience == 'Intermediate') {
          preferred = 4;
        } else {
          preferred = 5;
        }
        break;

      case 'Improve General Fitness':
        if (fitnessLevel == 'Low') {
          preferred = 3;
        } else if (fitnessLevel == 'Moderate') {
          preferred = 4;
        } else {
          preferred = 5;
        }
        break;

      case 'Start Running':
        preferred = availableDays >= 4 ? 4 : 3;
        if (fitnessLevel == 'Low') preferred = 3;
        break;

      case 'Improve Running Performance':
        if (availableDays >= 6) {
          preferred = 6;
        } else if (availableDays >= 5) {
          preferred = 5;
        } else {
          preferred = 4;
        }
        break;

      default:
        preferred = 3;
    }

    if (preferred < 1) preferred = 1;
    return preferred > availableDays ? availableDays : preferred;
  }

  static List<String> _spreadTrainingDays(
    List<String> availableDays,
    int sessionCount,
  ) {
    if (sessionCount <= 0 || availableDays.isEmpty) return [];

    if (sessionCount >= availableDays.length) {
      return List<String>.from(availableDays);
    }

    if (sessionCount == 1) return [availableDays.first];

    final result = <String>[];

    for (int i = 0; i < sessionCount; i++) {
      final position = i * (availableDays.length - 1) / (sessionCount - 1);
      final index = position.round();
      if (!result.contains(availableDays[index])) {
        result.add(availableDays[index]);
      }
    }

    for (final day in availableDays) {
      if (result.length >= sessionCount) break;
      if (!result.contains(day)) result.add(day);
    }

    result.sort(
      (a, b) => _weekOrder.indexOf(a).compareTo(_weekOrder.indexOf(b)),
    );

    return result;
  }

  static List<String> _titlesForGoal({
    required String goal,
    required String experience,
    required int sessionCount,
    required Set<String> locations,
  }) {
    switch (goal) {
      case 'Build Muscle':
      case 'Gain Weight':
        return _strengthTitles(experience, sessionCount);

      case 'Lose Body Fat':
        switch (sessionCount) {
          case 1:
            return ['Full Body Conditioning'];
          case 2:
            return ['Full Body Strength + Conditioning', 'Cardio Base'];
          case 3:
            return ['Full Body Strength', 'Cardio Intervals', 'Full Body Conditioning'];
          case 4:
            return [
              'Upper Body Conditioning',
              'Lower Body Conditioning',
              'Cardio Base',
              'Full Body Conditioning',
            ];
          default:
            return [
              'Upper Body Strength',
              'Lower Body Strength',
              'Cardio Intervals',
              'Full Body Conditioning',
              'Cardio Base',
            ];
        }

      case 'Improve General Fitness':
        switch (sessionCount) {
          case 1:
            return ['General Fitness Full Body'];
          case 2:
            return ['General Fitness Full Body', 'Cardio Base'];
          case 3:
            return ['Full Body Strength', 'Cardio Base', 'Mobility + Core'];
          case 4:
            return [
              'Full Body Strength',
              'Cardio Intervals',
              'Mobility + Core',
              'Mixed Conditioning',
            ];
          default:
            return [
              'Upper Body Strength',
              'Lower Body Strength',
              'Cardio Base',
              'Mobility + Core',
              'Mixed Conditioning',
            ];
        }

      case 'Start Running':
        if (!_hasRunningLocation(locations)) {
          if (sessionCount <= 2) {
            return ['Home Cardio Base', 'Mobility + Core'].take(sessionCount).toList();
          }
          return [
            'Home Cardio Base',
            'Runner Strength',
            'Mobility + Core',
            'Home Cardio Base',
          ].take(sessionCount).toList();
        }

        switch (sessionCount) {
          case 1:
            return ['Run-Walk Easy'];
          case 2:
            return ['Run-Walk Easy', 'Long Easy Run'];
          case 3:
            return ['Run-Walk Easy', 'Easy Run', 'Long Easy Run'];
          default:
            return ['Run-Walk Easy', 'Runner Strength', 'Easy Run', 'Long Easy Run'];
        }

      case 'Improve Running Performance':
        if (!_hasRunningLocation(locations)) {
          return [
            'Home Cardio Base',
            'Runner Strength',
            'Cardio Intervals',
            'Mobility + Core',
            'Home Cardio Base',
            'Runner Strength',
          ].take(sessionCount).toList();
        }

        switch (sessionCount) {
          case 1:
            return ['Quality Run'];
          case 2:
            return ['Intervals', 'Long Run'];
          case 3:
            return ['Easy Run', 'Tempo Run', 'Long Run'];
          case 4:
            return ['Easy Run', 'Intervals', 'Tempo Run', 'Long Run'];
          case 5:
            return ['Recovery Run', 'Intervals', 'Easy Run', 'Tempo Run', 'Long Run'];
          default:
            return [
              'Recovery Run',
              'Intervals',
              'Easy Run',
              'Runner Strength',
              'Tempo Run',
              'Long Run',
            ];
        }

      default:
        return ['General Fitness Full Body'];
    }
  }

  static List<String> _strengthTitles(String experience, int sessionCount) {
    if (sessionCount == 1) return ['Full Body'];
    if (sessionCount == 2) return ['Full Body A', 'Full Body B'];

    if (sessionCount == 3) {
      if (experience == 'Experienced') {
        return ['Upper Body', 'Lower Body', 'Full Body'];
      }
      return ['Full Body A', 'Full Body B', 'Full Body C'];
    }

    if (sessionCount == 4) {
      return ['Upper Body A', 'Lower Body A', 'Upper Body B', 'Lower Body B'];
    }

    return ['Push', 'Pull', 'Lower Body A', 'Upper Body', 'Lower Body B'];
  }

  static bool _hasRunningLocation(Set<String> locations) {
    return locations.contains('Outside') || locations.contains('Gym');
  }

  static String _locationForSession(String title, Set<String> locations) {
    final runSession = _isRunningSession(title);
    final cardioSession = title.contains('Cardio') ||
        title.contains('Conditioning') ||
        title == 'Mixed Conditioning';

    if (runSession) {
      if (locations.contains('Outside')) return 'Outside';
      if (locations.contains('Gym')) return 'Gym';
      return 'Home';
    }

    if (cardioSession && locations.contains('Outside')) return 'Outside';

    if (title == 'Mobility + Core') {
      if (locations.contains('Home')) return 'Home';
      if (locations.contains('Gym')) return 'Gym';
      if (locations.contains('Outside')) return 'Outside';
    }

    if (title == 'Runner Strength' ||
        title.contains('Strength') ||
        title.contains('Body') ||
        title == 'Push' ||
        title == 'Pull') {
      if (locations.contains('Gym')) return 'Gym';
      if (locations.contains('Home')) return 'Home';
      if (locations.contains('Outside')) return 'Outside';
    }

    if (locations.contains('Gym')) return 'Gym';
    if (locations.contains('Home')) return 'Home';
    if (locations.contains('Outside')) return 'Outside';
    return 'Flexible';
  }

  static bool _isRunningSession(String title) {
    const runningTitles = {
      'Run-Walk Easy',
      'Easy Run',
      'Long Easy Run',
      'Recovery Run',
      'Intervals',
      'Tempo Run',
      'Long Run',
      'Quality Run',
    };
    return runningTitles.contains(title);
  }

  static String _structureName(
    String goal,
    String experience,
    int sessionCount,
  ) {
    switch (goal) {
      case 'Build Muscle':
        if (sessionCount <= 3) return 'Full-body muscle-building structure';
        if (sessionCount == 4) return 'Upper / lower muscle-building structure';
        return '5-session muscle-building split';

      case 'Gain Weight':
        if (sessionCount <= 3) return 'Full-body resistance-training structure';
        if (sessionCount == 4) return 'Upper / lower resistance-training structure';
        return '5-session resistance-training split';

      case 'Lose Body Fat':
        return 'Strength + conditioning structure';

      case 'Improve General Fitness':
        return 'Balanced strength, cardio and mobility structure';

      case 'Start Running':
        return 'Progressive running foundation';

      case 'Improve Running Performance':
        return 'Performance running week';

      default:
        return '$sessionCount-session programme';
    }
  }

  static String _explanation({
    required String goal,
    required int trainingDays,
    required int sessionCount,
    required String trainingTime,
    required Set<String> locations,
  }) {
    final base =
        'You are available $trainingDays day(s) per week. '
        'The programme selected $sessionCount session(s) and spread them across your available days. '
        'Your normal training time is $trainingTime.';

    switch (goal) {
      case 'Build Muscle':
        return '$base Sessions prioritise repeatable resistance training with recovery between major muscle groups.';
      case 'Gain Weight':
        return '$base Resistance training supports muscle gain, while actual weight gain also depends on adequate food intake and recovery.';
      case 'Lose Body Fat':
        return '$base The week combines resistance training and conditioning. Body-fat change also depends on overall nutrition and daily activity.';
      case 'Improve General Fitness':
        return '$base The week balances strength, cardiovascular fitness, core work and mobility.';
      case 'Start Running':
        if (!_hasRunningLocation(locations)) {
          return '$base You did not select Outside or Gym, so the app is using home cardio and strength preparation. Add Outside or Gym/treadmill access for running-specific sessions.';
        }
        return '$base Running sessions emphasise gradual easy work, with recovery between harder days.';
      case 'Improve Running Performance':
        if (!_hasRunningLocation(locations)) {
          return '$base You did not select Outside or Gym, so running-specific sessions cannot be scheduled. The app is using home conditioning and runner-strength preparation instead.';
        }
        return '$base The week separates easy running, quality work and the long run so hard sessions are not stacked together.';
      default:
        return base;
    }
  }
}
