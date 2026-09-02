import 'training_profile_context.dart';

class PlannedSession {
  final String day;
  final String title;
  final String location;
  final String duration;
  final String focus;
  final String intensity;
  final String personalisationNote;

  const PlannedSession({
    required this.day,
    required this.title,
    required this.location,
    required this.duration,
    this.focus = 'Balanced training',
    this.intensity = 'Moderate',
    this.personalisationNote = '',
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
    String activityLevel = 'Moderately active',
    Set<String> homeEquipment = const <String>{},
    String gymAccess = 'Standard gym',
    bool hasLimitation = false,
    Set<String> affectedAreas = const <String>{},
  }) {
    final context = TrainingProfileContext.current;
    final goals = context != null &&
            (context.mainGoal == goal || context.goals.contains(goal))
        ? context.goals
        : <String>[goal];
    return generateForGoals(
      goals: goals,
      mainGoal: goal,
      experience: experience,
      fitnessLevel: fitnessLevel,
      activityLevel: activityLevel,
      availableDays: availableDays,
      locations: locations,
      homeEquipment: homeEquipment,
      gymAccess: gymAccess,
      sessionLength: sessionLength,
      trainingTime: trainingTime,
      hasLimitation: hasLimitation,
      affectedAreas: affectedAreas,
    );
  }

  static GeneratedProgramme generateForGoals({
    required List<String> goals,
    String? mainGoal,
    required String experience,
    required String fitnessLevel,
    required Set<String> availableDays,
    required Set<String> locations,
    required String sessionLength,
    required String trainingTime,
    String activityLevel = 'Moderately active',
    Set<String> homeEquipment = const <String>{},
    String gymAccess = 'Standard gym',
    bool hasLimitation = false,
    Set<String> affectedAreas = const <String>{},
  }) {
    final effectiveGoals = <String>[];
    for (final goal in goals) {
      if (supportedGoals.contains(goal) && !effectiveGoals.contains(goal)) {
        effectiveGoals.add(goal);
      }
    }
    if (effectiveGoals.isEmpty &&
        mainGoal != null &&
        supportedGoals.contains(mainGoal)) {
      effectiveGoals.add(mainGoal);
    }
    if (effectiveGoals.isEmpty) {
      return GeneratedProgramme(
        goal: mainGoal ?? 'Unsupported goal',
        structure: 'Goal not supported',
        explanation:
            'Choose at least one supported training goal so LeanIt can create a programme.',
        sessions: const [],
      );
    }

    final sortedDays = availableDays.toList()
      ..sort((a, b) => _dayIndex(a).compareTo(_dayIndex(b)));
    if (sortedDays.isEmpty) {
      return GeneratedProgramme(
        goal: effectiveGoals.join(' + '),
        structure: 'No training days selected',
        explanation:
            'Select at least one available day before creating a programme.',
        sessions: const [],
      );
    }

    final effectiveLocations = locations.isEmpty ? <String>{'Home'} : locations;
    final sessionCount = _sessionCount(
      goals: effectiveGoals,
      experience: experience,
      fitnessLevel: fitnessLevel,
      activityLevel: activityLevel,
      availableDays: sortedDays.length,
      locations: effectiveLocations,
      homeEquipment: homeEquipment,
      hasLimitation: hasLimitation,
    );
    final selectedDays = _spreadTrainingDays(sortedDays, sessionCount);
    final titles = _protectConcurrentRecovery(
      _sessionTitles(
        goals: effectiveGoals,
        experience: experience,
        fitnessLevel: fitnessLevel,
        activityLevel: activityLevel,
        sessionCount: sessionCount,
        locations: effectiveLocations,
        homeEquipment: homeEquipment,
      ),
    );

    final sessions = <PlannedSession>[];
    for (var index = 0; index < selectedDays.length; index++) {
      final title = titles[index % titles.length];
      sessions.add(
        PlannedSession(
          day: selectedDays[index],
          title: title,
          location: _locationForSession(
            title,
            effectiveLocations,
            homeEquipment: homeEquipment,
            gymAccess: gymAccess,
            sessionIndex: index,
          ),
          duration: sessionLength,
          focus: _focus(title, effectiveGoals),
          intensity: _intensity(
            title,
            experience: experience,
            fitnessLevel: fitnessLevel,
          ),
          personalisationNote: _note(
            title,
            experience: experience,
            sessionLength: sessionLength,
            hasLimitation: hasLimitation,
            goals: effectiveGoals,
          ),
        ),
      );
    }

    final combined = effectiveGoals.length > 1;
    final noRunLocation =
        _wantsRunning(effectiveGoals) && !_hasRunningLocation(effectiveLocations);
    final limitationText = hasLimitation
        ? ' LeanIt’s safety engine applies your saved limitation profile${affectedAreas.isEmpty ? '' : ' for ${affectedAreas.join(', ')}'} at exercise level. These filters do not diagnose injuries or prescribe rehabilitation.'
        : '';
    final locationText = noRunLocation
        ? ' Outside or Gym running is unavailable in your saved locations, so LeanIt uses home cardio and runner-strength substitutes until a running location is available.'
        : '';
    final homeEquipmentText = effectiveLocations.contains('Home') &&
            homeEquipment.isNotEmpty
        ? ' Home sessions are filtered against your saved home-equipment before exercises are selected.'
        : '';

    return GeneratedProgramme(
      goal: effectiveGoals.join(' + '),
      structure: combined
          ? 'Concurrent ${experience.toLowerCase()} programme • $sessionCount sessions/week'
          : '${_singleGoalStructure(effectiveGoals.first, experience)} • $sessionCount sessions/week',
      explanation: combined
          ? 'LeanIt is training ${effectiveGoals.join(', ')} together instead of forcing one goal. Strength and running/cardio work are distributed across the week so hard lower-body work is not deliberately stacked beside every hard run. Each ${sessionLength.toLowerCase()} session is filled from the master exercise pool and fitted to its real time budget.$homeEquipmentText$limitationText$locationText'
          : 'This ${experience.toLowerCase()} programme uses your available days, current fitness, training locations and ${sessionLength.toLowerCase()} session preference. The workout generator ranks suitable exercises from LeanIt’s master library, leaving valid same-purpose movements as alternatives.$homeEquipmentText$limitationText$locationText',
      sessions: sessions,
    );
  }

  static int _sessionCount({
    required List<String> goals,
    required String experience,
    required String fitnessLevel,
    required String activityLevel,
    required int availableDays,
    required Set<String> locations,
    required Set<String> homeEquipment,
    required bool hasLimitation,
  }) {
    if (availableDays <= 0) return 0;
    int preferred;
    if (goals.length > 1) {
      preferred = experience == 'Beginner' ? 4 : (experience == 'Advanced' ? 6 : 5);
      if (_wantsRunning(goals) && _wantsStrength(goals)) preferred += 1;
    } else {
      switch (goals.first) {
        case 'Build Muscle':
        case 'Gain Weight':
          preferred = experience == 'Beginner'
              ? 3
              : (experience == 'Advanced' ? 5 : 4);
          break;
        case 'Start Running':
          preferred = fitnessLevel == 'Low' ? 3 : 4;
          break;
        case 'Improve Running Performance':
          preferred = experience == 'Beginner'
              ? 4
              : (experience == 'Advanced' ? 6 : 5);
          break;
        case 'Lose Body Fat':
        case 'Improve General Fitness':
        default:
          preferred = experience == 'Beginner'
              ? 3
              : (experience == 'Advanced' ? 5 : 4);
      }
    }

    final sedentary = activityLevel == 'Mostly sedentary' ||
        activityLevel == 'Mostly inactive';
    if ((experience == 'Beginner' && fitnessLevel == 'Low') || sedentary) {
      preferred = preferred.clamp(1, goals.length > 1 ? 4 : 3).toInt();
    }

    // Preserve the established rule that a home-only muscle plan with very
    // little resistance equipment should not masquerade as a high-frequency
    // advanced split.
    final muscleGoal = goals.any(
      (goal) => goal == 'Build Muscle' || goal == 'Gain Weight',
    );
    if (muscleGoal &&
        locations.length == 1 &&
        locations.contains('Home') &&
        _homeStrengthScore(homeEquipment) < 2) {
      preferred = preferred.clamp(1, 3).toInt();
    }

    if (hasLimitation && fitnessLevel == 'Low') {
      preferred = preferred.clamp(1, 4).toInt();
    }
    return preferred.clamp(1, availableDays).toInt();
  }

  static List<String> _sessionTitles({
    required List<String> goals,
    required String experience,
    required String fitnessLevel,
    required String activityLevel,
    required int sessionCount,
    required Set<String> locations,
    required Set<String> homeEquipment,
  }) {
    if (goals.length == 1) {
      return _singleGoalTitles(
        goals.first,
        experience: experience,
        fitnessLevel: fitnessLevel,
        activityLevel: activityLevel,
        sessionCount: sessionCount,
        locations: locations,
        homeEquipment: homeEquipment,
      );
    }

    final titles = <String>[];
    final strength = _wantsStrength(goals);
    final running = _wantsRunning(goals);
    final fatLoss = goals.contains('Lose Body Fat');

    if (strength && running) {
      if (experience == 'Beginner' || sessionCount <= 4) {
        titles.addAll(['Full Body A', 'Easy Run', 'Full Body B']);
        if (sessionCount >= 4) titles.add('Long Easy Run');
      } else {
        titles.addAll(
          ['Upper Body A', 'Easy Run', 'Lower Body A', 'Quality Run'],
        );
        if (sessionCount >= 5) titles.add('Upper Body B');
        if (sessionCount >= 6) titles.add('Long Run');
      }
    } else if (strength) {
      titles.addAll(_strengthTitles(experience, sessionCount));
    } else if (running) {
      titles.addAll(
        _runningTitles(
          performance: goals.contains('Improve Running Performance'),
          conservative: experience == 'Beginner' || fitnessLevel == 'Low',
          count: sessionCount,
          hasRunLocation: _hasRunningLocation(locations),
        ),
      );
    }

    if (fatLoss && titles.length < sessionCount) titles.add('Cardio Base');
    if (goals.contains('Improve General Fitness') && titles.length < sessionCount) {
      titles.add('Mobility + Core');
    }
    while (titles.length < sessionCount) {
      titles.add(strength ? 'Full Body Strength' : 'Cardio Base');
    }
    return titles.take(sessionCount).toList(growable: false);
  }

  static List<String> _singleGoalTitles(
    String goal, {
    required String experience,
    required String fitnessLevel,
    required String activityLevel,
    required int sessionCount,
    required Set<String> locations,
    required Set<String> homeEquipment,
  }) {
    final conservative = experience == 'Beginner' ||
        fitnessLevel == 'Low' ||
        activityLevel == 'Mostly inactive' ||
        activityLevel == 'Mostly sedentary';
    switch (goal) {
      case 'Build Muscle':
      case 'Gain Weight':
        if (locations.length == 1 &&
            locations.contains('Home') &&
            _homeStrengthScore(homeEquipment) < 2) {
          return ['Full Body A', 'Full Body B', 'Full Body C']
              .take(sessionCount)
              .toList(growable: false);
        }
        return _strengthTitles(experience, sessionCount);
      case 'Start Running':
        return _runningTitles(
          performance: false,
          conservative: conservative,
          count: sessionCount,
          hasRunLocation: _hasRunningLocation(locations),
        );
      case 'Improve Running Performance':
        return _runningTitles(
          performance: true,
          conservative: conservative,
          count: sessionCount,
          hasRunLocation: _hasRunningLocation(locations),
        );
      case 'Lose Body Fat':
        return _fill(
          conservative
              ? const [
                  'Full Body Strength',
                  'Cardio Base',
                  'Full Body Conditioning',
                  'Mobility + Core',
                  'Cardio Base',
                ]
              : const [
                  'Upper Body Strength',
                  'Lower Body Strength',
                  'Cardio Intervals',
                  'Full Body Conditioning',
                  'Cardio Base',
                ],
          sessionCount,
          'Cardio Base',
        );
      case 'Improve General Fitness':
      default:
        return _fill(
          conservative
              ? const [
                  'Full Body Strength',
                  'Cardio Base',
                  'Mobility + Core',
                  'Full Body Conditioning',
                ]
              : const [
                  'Upper Body Strength',
                  'Lower Body Strength',
                  'Cardio Base',
                  'Mobility + Core',
                  'Mixed Conditioning',
                ],
          sessionCount,
          'Cardio Base',
        );
    }
  }

  static List<String> _runningTitles({
    required bool performance,
    required bool conservative,
    required int count,
    required bool hasRunLocation,
  }) {
    if (!hasRunLocation) {
      return _fill(
        const [
          'Home Cardio Base',
          'Runner Strength',
          'Mobility + Core',
          'Home Cardio Base',
        ],
        count,
        'Home Cardio Base',
      );
    }
    if (!performance) {
      return _fill(
        conservative
            ? const [
                'Run-Walk Easy',
                'Runner Strength',
                'Easy Run',
                'Long Easy Run',
              ]
            : const ['Easy Run', 'Runner Strength', 'Easy Run', 'Long Easy Run'],
        count,
        'Easy Run',
      );
    }
    return _fill(
      conservative
          ? const ['Easy Run', 'Runner Strength', 'Tempo Run', 'Long Run']
          : const [
              'Recovery Run',
              'Intervals',
              'Easy Run',
              'Runner Strength',
              'Tempo Run',
              'Long Run',
            ],
      count,
      'Easy Run',
    );
  }

  static List<String> _strengthTitles(String experience, int count) {
    final base = count <= 2
        ? const ['Full Body A', 'Full Body B']
        : count == 3
            ? const ['Full Body A', 'Full Body B', 'Full Body C']
            : count == 4
                ? const [
                    'Upper Body A',
                    'Lower Body A',
                    'Upper Body B',
                    'Lower Body B',
                  ]
                : const [
                    'Push',
                    'Pull',
                    'Lower Body A',
                    'Upper Body',
                    'Lower Body B',
                  ];
    return _fill(
      base,
      count,
      experience == 'Advanced' ? 'Full Body Strength' : 'Full Body C',
    );
  }

  static List<String> _protectConcurrentRecovery(List<String> titles) {
    if (titles.length < 3) return titles;
    final remaining = List<String>.from(titles);
    final output = <String>[];
    while (remaining.isNotEmpty) {
      var pick = 0;
      if (output.isNotEmpty && _isLowerHard(output.last)) {
        final safe = remaining.indexWhere((item) => !_isLowerHard(item));
        if (safe >= 0) pick = safe;
      }
      output.add(remaining.removeAt(pick));
    }
    return output;
  }

  static bool _isLowerHard(String title) {
    final value = title.toLowerCase();
    return value.contains('lower') ||
        value.contains('interval') ||
        value.contains('quality run') ||
        value.contains('tempo') ||
        value.contains('long run');
  }

  static List<String> _spreadTrainingDays(List<String> available, int count) {
    if (count >= available.length) return List<String>.from(available);
    if (count <= 1) return [available.first];
    final output = <String>[];
    for (var i = 0; i < count; i++) {
      final position = i * (available.length - 1) / (count - 1);
      final day = available[position.round()];
      if (!output.contains(day)) output.add(day);
    }
    for (final day in available) {
      if (output.length >= count) break;
      if (!output.contains(day)) output.add(day);
    }
    output.sort((a, b) => _dayIndex(a).compareTo(_dayIndex(b)));
    return output;
  }

  static String _locationForSession(
    String title,
    Set<String> locations, {
    required Set<String> homeEquipment,
    required String gymAccess,
    required int sessionIndex,
  }) {
    if (_isRunningSession(title)) {
      if (locations.contains('Outside')) return 'Outside';
      if (locations.contains('Gym')) return 'Gym';
      return 'Home';
    }
    final cardio = title.contains('Cardio') || title.contains('Conditioning');
    if (cardio && locations.contains('Outside')) return 'Outside';

    // A user who explicitly saved both an equipped home setup and a gym should
    // actually see both environments represented in a strength programme.
    if (locations.contains('Gym') &&
        locations.contains('Home') &&
        _homeStrengthScore(homeEquipment) > 0) {
      return sessionIndex.isEven ? 'Gym' : 'Home';
    }
    if (locations.contains('Gym')) return 'Gym';
    if (locations.contains('Home')) return 'Home';
    return locations.first;
  }

  static bool _isRunningSession(String title) => const {
        'Run-Walk Easy',
        'Easy Run',
        'Long Easy Run',
        'Recovery Run',
        'Intervals',
        'Tempo Run',
        'Long Run',
        'Quality Run',
      }.contains(title);

  static String _focus(String title, List<String> goals) {
    if (_isRunningSession(title)) return 'Running development';
    if (title.contains('Cardio')) return 'Cardiorespiratory fitness';
    if (title.contains('Mobility')) return 'Mobility and trunk control';
    if (title.contains('Upper')) return 'Upper-body strength and muscle';
    if (title.contains('Lower')) return 'Lower-body strength and muscle';
    if (title.contains('Runner Strength')) return 'Running support strength';
    return _wantsStrength(goals) ? 'Strength and muscle' : 'Balanced conditioning';
  }

  static String _intensity(
    String title, {
    required String experience,
    required String fitnessLevel,
  }) {
    if (title.contains('Recovery') ||
        title.contains('Mobility') ||
        title.contains('Easy')) {
      return 'Easy to moderate';
    }
    if (title.contains('Intervals') ||
        title.contains('Quality') ||
        title.contains('Tempo')) {
      return fitnessLevel == 'Low' ? 'Moderate' : 'Hard';
    }
    return experience == 'Beginner' ? 'Moderate' : 'Moderate to hard';
  }

  static String _note(
    String title, {
    required String experience,
    required String sessionLength,
    required bool hasLimitation,
    required List<String> goals,
  }) {
    final multi = goals.length > 1
        ? ' Part of a concurrent ${goals.join(' + ')} plan.'
        : '';
    final safety = hasLimitation
        ? ' LeanIt safety substitutions remain active for this session.'
        : '';
    return '$experience session fitted to about $sessionLength.$multi$safety';
  }

  static String _singleGoalStructure(String goal, String experience) {
    if (goal.contains('Running')) return '$experience running programme';
    if (goal == 'Build Muscle' || goal == 'Gain Weight') {
      return '$experience progressive resistance programme';
    }
    if (goal == 'Lose Body Fat') {
      return '$experience strength + conditioning programme';
    }
    return '$experience balanced fitness programme';
  }

  static bool _wantsStrength(List<String> goals) => goals.any(
        (goal) =>
            goal == 'Build Muscle' ||
            goal == 'Gain Weight' ||
            goal == 'Improve General Fitness',
      );

  static bool _wantsRunning(List<String> goals) => goals.any(
        (goal) =>
            goal == 'Start Running' || goal == 'Improve Running Performance',
      );

  static bool _hasRunningLocation(Set<String> locations) =>
      locations.contains('Outside') || locations.contains('Gym');

  static int _homeStrengthScore(Set<String> equipment) {
    var score = 0;
    for (final item in equipment) {
      final value = item.toLowerCase();
      if (value.contains('dumbbell') ||
          value.contains('barbell') ||
          value.contains('kettlebell') ||
          value.contains('band') ||
          value.contains('pull-up')) {
        score++;
      }
    }
    return score;
  }

  static List<String> _fill(List<String> base, int count, String fallback) {
    final output = <String>[];
    for (final item in base) {
      if (output.length >= count) break;
      output.add(item);
    }
    while (output.length < count) output.add(fallback);
    return output;
  }

  static int _dayIndex(String day) {
    final index = _weekOrder.indexOf(day);
    return index < 0 ? _weekOrder.length : index;
  }
}
