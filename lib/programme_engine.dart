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

    final effectiveLocations = locations.isEmpty ? <String>{'Home'} : locations;
    final sessionCount = _chooseSessionCount(
      goal: goal,
      experience: experience,
      fitnessLevel: fitnessLevel,
      activityLevel: activityLevel,
      availableDays: sortedDays.length,
      locations: effectiveLocations,
      homeEquipment: homeEquipment,
      sessionLength: sessionLength,
      hasLimitation: hasLimitation,
    );

    final selectedTrainingDays = _spreadTrainingDays(sortedDays, sessionCount);
    final titles = _titlesForGoal(
      goal: goal,
      experience: experience,
      fitnessLevel: fitnessLevel,
      activityLevel: activityLevel,
      sessionCount: sessionCount,
      locations: effectiveLocations,
      homeEquipment: homeEquipment,
      hasLimitation: hasLimitation,
    );

    final sessions = <PlannedSession>[];
    for (int i = 0; i < selectedTrainingDays.length; i++) {
      final title = titles[i % titles.length];
      final location = _locationForSession(
        title,
        effectiveLocations,
        homeEquipment: homeEquipment,
        gymAccess: gymAccess,
        sessionIndex: i,
      );
      sessions.add(
        PlannedSession(
          day: selectedTrainingDays[i],
          title: title,
          location: location,
          duration: sessionLength,
          focus: _focusForSession(title, goal),
          intensity: _intensityForSession(
            title: title,
            goal: goal,
            experience: experience,
            fitnessLevel: fitnessLevel,
          ),
          personalisationNote: _sessionNote(
            title: title,
            location: location,
            goal: goal,
            experience: experience,
            fitnessLevel: fitnessLevel,
            activityLevel: activityLevel,
            sessionLength: sessionLength,
            homeEquipment: homeEquipment,
            hasLimitation: hasLimitation,
          ),
        ),
      );
    }

    return GeneratedProgramme(
      goal: goal,
      structure: _structureName(goal, experience, sessionCount),
      explanation: _explanation(
        goal: goal,
        experience: experience,
        fitnessLevel: fitnessLevel,
        activityLevel: activityLevel,
        trainingDays: sortedDays.length,
        sessionCount: sessionCount,
        sessionLength: sessionLength,
        trainingTime: trainingTime,
        locations: effectiveLocations,
        homeEquipment: homeEquipment,
        hasLimitation: hasLimitation,
        affectedAreas: affectedAreas,
      ),
      sessions: sessions,
    );
  }

  static int _chooseSessionCount({
    required String goal,
    required String experience,
    required String fitnessLevel,
    required String activityLevel,
    required int availableDays,
    required Set<String> locations,
    required Set<String> homeEquipment,
    required String sessionLength,
    required bool hasLimitation,
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
        preferred = experience == 'Beginner'
            ? 3
            : experience == 'Intermediate'
                ? 4
                : 5;
        break;
      case 'Improve General Fitness':
        preferred = fitnessLevel == 'Low'
            ? 3
            : fitnessLevel == 'Moderate'
                ? 4
                : 5;
        break;
      case 'Start Running':
        preferred = availableDays >= 4 ? 4 : 3;
        if (fitnessLevel == 'Low' || activityLevel == 'Mostly sedentary') {
          preferred = 3;
        }
        break;
      case 'Improve Running Performance':
        preferred = availableDays >= 6
            ? 6
            : availableDays >= 5
                ? 5
                : 4;
        if (fitnessLevel == 'Low') preferred = preferred.clamp(1, 4);
        break;
      default:
        preferred = 3;
    }

    // A beginner with low current fitness gets a simpler starting frequency,
    // even when many days are technically available.
    if (experience == 'Beginner' && fitnessLevel == 'Low') {
      preferred = preferred.clamp(1, 3);
    }

    // People reporting a mostly sedentary baseline start with fewer hard
    // commitments for general fitness/fat-loss goals. They can still be active
    // on non-programme days without LeanIt prescribing another hard session.
    if (activityLevel == 'Mostly sedentary' &&
        (goal == 'Lose Body Fat' || goal == 'Improve General Fitness')) {
      preferred = preferred.clamp(1, 4);
    }

    // A home-only muscle-gain plan with very little resistance equipment uses
    // repeatable full-body work rather than pretending a high-frequency split
    // has the same loading options as a gym programme.
    if ((goal == 'Build Muscle' || goal == 'Gain Weight') &&
        locations.length == 1 &&
        locations.contains('Home') &&
        _homeStrengthScore(homeEquipment) < 2) {
      preferred = preferred.clamp(1, 3);
    }

    // Limitations do not get diagnosed here. We simply avoid escalating a low
    // fitness starting point; exercise-level exclusions remain SafetyEngine's job.
    if (hasLimitation && fitnessLevel == 'Low') {
      preferred = preferred.clamp(1, 3);
    }

    // Very short sessions are already trimmed by WorkoutEngine. Do not respond
    // by silently multiplying weekly frequency; respect the days the user chose.
    if (sessionLength == '20 min' && preferred > 5) preferred = 5;

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
      if (!result.contains(availableDays[index])) result.add(availableDays[index]);
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
    required String fitnessLevel,
    required String activityLevel,
    required int sessionCount,
    required Set<String> locations,
    required Set<String> homeEquipment,
    required bool hasLimitation,
  }) {
    final conservative = experience == 'Beginner' ||
        fitnessLevel == 'Low' ||
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

      case 'Lose Body Fat':
        if (conservative) {
          const base = [
            'Full Body Strength',
            'Cardio Base',
            'Full Body Conditioning',
            'Mobility + Core',
            'Cardio Base',
          ];
          return base.take(sessionCount).toList(growable: false);
        }
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
        if (conservative) {
          const base = [
            'Full Body Strength',
            'Cardio Base',
            'Mobility + Core',
            'Full Body Conditioning',
            'Cardio Base',
          ];
          return base.take(sessionCount).toList(growable: false);
        }
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
          const fallback = [
            'Home Cardio Base',
            'Runner Strength',
            'Mobility + Core',
            'Home Cardio Base',
          ];
          return fallback.take(sessionCount).toList(growable: false);
        }
        if (conservative) {
          const foundation = [
            'Run-Walk Easy',
            'Runner Strength',
            'Easy Run',
            'Long Easy Run',
          ];
          return foundation.take(sessionCount).toList(growable: false);
        }
        switch (sessionCount) {
          case 1:
            return ['Run-Walk Easy'];
          case 2:
            return ['Easy Run', 'Long Easy Run'];
          case 3:
            return ['Easy Run', 'Runner Strength', 'Long Easy Run'];
          default:
            return ['Easy Run', 'Runner Strength', 'Easy Run', 'Long Easy Run'];
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
          ].take(sessionCount).toList(growable: false);
        }
        if (fitnessLevel == 'Low') {
          return [
            'Easy Run',
            'Runner Strength',
            'Tempo Run',
            'Long Run',
          ].take(sessionCount).toList(growable: false);
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
      if (experience == 'Advanced') {
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

  static String _locationForSession(
    String title,
    Set<String> locations, {
    required Set<String> homeEquipment,
    required String gymAccess,
    required int sessionIndex,
  }) {
    final runSession = _isRunningSession(title);
    final cardioSession = title.contains('Cardio') ||
        title.contains('Conditioning') ||
        title == 'Mixed Conditioning';
    final strengthSession = title == 'Runner Strength' ||
        title.contains('Strength') ||
        title.contains('Body') ||
        title.contains('Upper') ||
        title.contains('Lower') ||
        title == 'Push' ||
        title == 'Pull';

    if (runSession) {
      if (locations.contains('Outside')) return 'Outside';
      if (locations.contains('Gym')) return 'Gym';
      return 'Home';
    }

    if (title == 'Mobility + Core') {
      if (locations.contains('Home')) return 'Home';
      if (locations.contains('Gym')) return 'Gym';
      if (locations.contains('Outside')) return 'Outside';
    }

    if (cardioSession) {
      if (locations.contains('Outside')) return 'Outside';
      if (locations.contains('Home') && homeEquipment.contains('Cardio machine')) {
        return 'Home';
      }
      if (locations.contains('Gym')) return 'Gym';
      if (locations.contains('Home')) return 'Home';
    }

    if (strengthSession) {
      final homeCapable = _homeStrengthScore(homeEquipment) >= 2;
      final hasHome = locations.contains('Home');
      final hasGym = locations.contains('Gym') && gymAccess.trim().isNotEmpty;
      if (hasHome && hasGym && homeCapable) {
        // When the profile supports both, alternate rather than ignoring one of
        // the locations the user explicitly selected.
        return sessionIndex.isEven ? 'Gym' : 'Home';
      }
      if (hasGym) return 'Gym';
      if (hasHome) return 'Home';
      if (locations.contains('Outside')) return 'Outside';
    }

    if (locations.contains('Gym')) return 'Gym';
    if (locations.contains('Home')) return 'Home';
    if (locations.contains('Outside')) return 'Outside';
    return 'Flexible';
  }

  static int _homeStrengthScore(Set<String> equipment) {
    var score = 0;
    if (equipment.contains('Dumbbells')) score += 2;
    if (equipment.contains('Kettlebell')) score += 2;
    if (equipment.contains('Barbell + plates')) score += 3;
    if (equipment.contains('Resistance bands')) score += 1;
    if (equipment.contains('Bench')) score += 1;
    if (equipment.contains('Pull-up bar')) score += 1;
    return score;
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

  static String _focusForSession(String title, String goal) {
    if (_isRunningSession(title)) {
      if (title.contains('Long')) return 'Aerobic endurance';
      if (title == 'Intervals' || title == 'Quality Run') return 'Speed + aerobic power';
      if (title == 'Tempo Run') return 'Sustained running strength';
      if (title == 'Recovery Run') return 'Easy aerobic recovery';
      return 'Aerobic foundation';
    }
    if (title == 'Mobility + Core') return 'Mobility + trunk control';
    if (title.contains('Cardio')) return 'Cardiovascular fitness';
    if (title.contains('Conditioning')) return 'Strength endurance + conditioning';
    if (title == 'Push') return 'Chest, shoulders + triceps';
    if (title == 'Pull') return 'Back + biceps';
    if (title.contains('Upper')) return 'Upper-body strength';
    if (title.contains('Lower')) return 'Lower-body strength';
    if (title == 'Runner Strength') return 'Running-support strength';
    if (goal == 'Build Muscle' || goal == 'Gain Weight') return 'Whole-body muscle development';
    return 'Whole-body strength';
  }

  static String _intensityForSession({
    required String title,
    required String goal,
    required String experience,
    required String fitnessLevel,
  }) {
    if (title == 'Mobility + Core' || title == 'Recovery Run' || title == 'Run-Walk Easy') {
      return 'Easy';
    }
    if (title == 'Intervals' || title == 'Cardio Intervals' || title == 'Quality Run') {
      return fitnessLevel == 'Low' ? 'Moderate' : 'Hard';
    }
    if (title == 'Tempo Run' || title.contains('Conditioning')) {
      return experience == 'Beginner' || fitnessLevel == 'Low' ? 'Moderate' : 'Moderate–Hard';
    }
    if (title.contains('Long')) return 'Easy–Moderate';
    if (goal == 'Build Muscle' || goal == 'Gain Weight') {
      return experience == 'Beginner' ? 'Moderate' : 'Moderate–Hard';
    }
    return 'Moderate';
  }

  static String _sessionNote({
    required String title,
    required String location,
    required String goal,
    required String experience,
    required String fitnessLevel,
    required String activityLevel,
    required String sessionLength,
    required Set<String> homeEquipment,
    required bool hasLimitation,
  }) {
    final reasons = <String>[];
    if (title == 'Mobility + Core') {
      reasons.add('balances harder training with mobility and trunk work');
    } else if (_isRunningSession(title)) {
      reasons.add('matches your $goal goal without stacking every run as a hard session');
    } else if (title.contains('Strength') ||
        title.contains('Body') ||
        title == 'Push' ||
        title == 'Pull') {
      reasons.add('supports your $goal goal with repeatable resistance training');
    } else if (title.contains('Cardio') || title.contains('Conditioning')) {
      reasons.add('adds cardiovascular work alongside the rest of your week');
    }

    if (experience == 'Beginner' || fitnessLevel == 'Low') {
      reasons.add('keeps the starting structure simple for your current level');
    }
    if (activityLevel == 'Mostly sedentary') {
      reasons.add('avoids making every available day a demanding session');
    }
    if (location == 'Home' && _homeStrengthScore(homeEquipment) >= 2) {
      reasons.add('uses the resistance equipment you have at home');
    } else if (location == 'Gym') {
      reasons.add('uses your gym access for broader loading options');
    } else if (location == 'Outside') {
      reasons.add('uses your outdoor access for cardio or running work');
    }
    if (sessionLength == '20 min' || sessionLength == '30 min') {
      reasons.add('fits the shorter session window you selected');
    }
    if (hasLimitation) {
      reasons.add('will still pass through LeanIt safety substitutions before training');
    }

    if (reasons.isEmpty) return 'Chosen from your training profile.';
    final sentence = reasons.join('; ');
    return '${sentence[0].toUpperCase()}${sentence.substring(1)}.';
  }

  static String _structureName(String goal, String experience, int sessionCount) {
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
    required String experience,
    required String fitnessLevel,
    required String activityLevel,
    required int trainingDays,
    required int sessionCount,
    required String sessionLength,
    required String trainingTime,
    required Set<String> locations,
    required Set<String> homeEquipment,
    required bool hasLimitation,
    required Set<String> affectedAreas,
  }) {
    final base =
        'LeanIt used your $goal goal, $experience experience, $fitnessLevel fitness level, '
        '$activityLevel activity baseline, $trainingDays available day(s), $sessionLength session window '
        'and $trainingTime training preference. It selected $sessionCount session(s) and spread them across your available days.';

    final equipmentText = locations.contains('Home')
        ? _homeStrengthScore(homeEquipment) >= 2
            ? ' Your home-equipment choices are strong enough for meaningful resistance sessions, so Home can be used when it fits the week.'
            : ' Your Home option has limited resistance equipment, so LeanIt keeps home strength work simpler and prefers gym loading when Gym is also available.'
        : '';

    final limitationText = hasLimitation
        ? ' Your saved limitation settings do not diagnose or redesign rehabilitation; each generated workout is still passed through the safety engine before training${affectedAreas.isEmpty ? '' : ' for the areas you selected'}.'
        : '';

    switch (goal) {
      case 'Build Muscle':
        return '$base Sessions prioritise repeatable resistance training and enough separation between major muscle groups.$equipmentText$limitationText';
      case 'Gain Weight':
        return '$base Resistance training supports muscle gain, while actual weight gain also depends on adequate food intake and recovery.$equipmentText$limitationText';
      case 'Lose Body Fat':
        return '$base The week combines resistance training and conditioning, with harder intervals reserved for profiles that are ready for them. Body-fat change also depends on overall nutrition and daily activity.$equipmentText$limitationText';
      case 'Improve General Fitness':
        return '$base The week balances strength, cardiovascular fitness, core work and mobility instead of repeating one training type.$equipmentText$limitationText';
      case 'Start Running':
        if (!_hasRunningLocation(locations)) {
          return '$base You did not select Outside or Gym, so LeanIt uses home cardio, runner strength and mobility preparation. Add Outside or Gym/treadmill access for running-specific sessions.$limitationText';
        }
        return '$base Running work starts with an aerobic foundation and separates harder work from recovery.$limitationText';
      case 'Improve Running Performance':
        if (!_hasRunningLocation(locations)) {
          return '$base You did not select Outside or Gym, so running-specific sessions cannot be scheduled. LeanIt uses home conditioning and runner-strength preparation instead.$limitationText';
        }
        return '$base The week separates easy running, quality work, supporting strength and the long run so demanding sessions are not all stacked together.$limitationText';
      default:
        return '$base$equipmentText$limitationText';
    }
  }
}
