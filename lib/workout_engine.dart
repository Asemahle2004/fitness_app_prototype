class ExercisePrescription {
  final String name;
  final int sets;
  final String reps;
  final String rest;
  final String equipment;
  final String target;
  final String? visualAsset;
  final String? metricLabel;
  final String? supersetId;
  final int dropSetCount;
  final int dropSetReductionPercent;

  const ExercisePrescription({
    required this.name,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.equipment,
    required this.target,
    this.visualAsset,
    this.metricLabel,
    this.supersetId,
    this.dropSetCount = 0,
    this.dropSetReductionPercent = 20,
  });

  ExercisePrescription copyWith({
    String? name,
    int? sets,
    String? reps,
    String? rest,
    String? equipment,
    String? target,
    String? visualAsset,
    String? metricLabel,
    String? supersetId,
    int? dropSetCount,
    int? dropSetReductionPercent,
    bool clearSuperset = false,
    bool clearDropSet = false,
  }) {
    return ExercisePrescription(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      rest: rest ?? this.rest,
      equipment: equipment ?? this.equipment,
      target: target ?? this.target,
      visualAsset: visualAsset ?? this.visualAsset,
      metricLabel: metricLabel ?? this.metricLabel,
      supersetId: clearSuperset ? null : (supersetId ?? this.supersetId),
      dropSetCount: clearDropSet ? 0 : (dropSetCount ?? this.dropSetCount),
      dropSetReductionPercent: clearDropSet
          ? 20
          : (dropSetReductionPercent ?? this.dropSetReductionPercent),
    );
  }

  bool get isSingleDurationBlock {
    if (sets != 1) return false;
    final value = reps.toLowerCase();
    return value.contains('min') ||
        value.contains('km') ||
        value.contains('walk') ||
        value.contains('easy');
  }

  String get summary {
    if (isSingleDurationBlock) return reps;
    return '$sets sets × $reps';
  }

  String get setsLabel => isSingleDurationBlock ? 'BLOCKS' : 'SETS';
  String get repsLabel => metricLabel ?? (isSingleDurationBlock ? 'TARGET' : 'REPS');
}

class GeneratedWorkout {
  final String title;
  final List<ExercisePrescription> exercises;

  const GeneratedWorkout({
    required this.title,
    required this.exercises,
  });
}

class WorkoutEngine {
  static GeneratedWorkout generate({
    required String sessionTitle,
    required String location,
    Set<String> homeEquipment = const {},
    String? gymAccess,
    String? sessionDuration,
  }) {
    final effectiveLocation = _normaliseLocation(location);
    final workout = _buildWorkout(
      sessionTitle: sessionTitle,
      location: effectiveLocation,
      homeEquipment: homeEquipment,
      gymAccess: gymAccess,
    );
    return _fitToDuration(workout, sessionDuration);
  }

  static GeneratedWorkout _buildWorkout({
    required String sessionTitle,
    required String location,
    required Set<String> homeEquipment,
    required String? gymAccess,
  }) {
    if (_runningTitles.contains(sessionTitle)) {
      return _runningWorkout(sessionTitle, location);
    }

    switch (sessionTitle) {
      case 'Cardio Base':
      case 'Home Cardio Base':
        return _cardioBase(sessionTitle, location);

      case 'Cardio Intervals':
        return _cardioIntervals(sessionTitle, location);

      case 'Mobility + Core':
        return _mobilityCore(sessionTitle, location);

      case 'Runner Strength':
        return _runnerStrength(
          sessionTitle,
          location,
          homeEquipment,
          gymAccess,
        );

      case 'Full Body Conditioning':
      case 'Full Body Strength + Conditioning':
      case 'Mixed Conditioning':
        return _conditioning(
          sessionTitle,
          location,
          homeEquipment,
          gymAccess,
        );

      case 'Push':
        return _push(
          sessionTitle,
          location,
          homeEquipment,
          gymAccess,
        );

      case 'Pull':
        return _pull(
          sessionTitle,
          location,
          homeEquipment,
          gymAccess,
        );

      default:
        if (sessionTitle.contains('Upper Body')) {
          return _upper(
            sessionTitle,
            location,
            homeEquipment,
            gymAccess,
          );
        }

        if (sessionTitle.contains('Lower Body')) {
          return _lower(
            sessionTitle,
            location,
            homeEquipment,
            gymAccess,
          );
        }

        return _fullBody(
          sessionTitle,
          location,
          homeEquipment,
          gymAccess,
        );
    }
  }

  static GeneratedWorkout _fitToDuration(
    GeneratedWorkout workout,
    String? sessionDuration,
  ) {
    if (sessionDuration == null || workout.exercises.length <= 3) {
      return workout;
    }

    int maxExercises;
    switch (sessionDuration) {
      case '15 min':
      case '20 min':
        maxExercises = 3;
        break;
      case '30 min':
        maxExercises = 4;
        break;
      case '45 min':
        maxExercises = 5;
        break;
      case '60 min':
        maxExercises = 6;
        break;
      default:
        maxExercises = workout.exercises.length;
    }

    if (workout.exercises.length <= maxExercises) return workout;

    return GeneratedWorkout(
      title: workout.title,
      exercises: workout.exercises.take(maxExercises).toList(growable: false),
    );
  }

  static const Set<String> _runningTitles = {
    'Run-Walk Easy',
    'Easy Run',
    'Long Easy Run',
    'Recovery Run',
    'Intervals',
    'Tempo Run',
    'Long Run',
    'Quality Run',
  };

  static String _normaliseLocation(String location) {
    if (location.contains('Outside')) return 'Outside';
    if (location.contains('Home')) return 'Home';
    return 'Gym';
  }

  static String? _localAsset(String name) {
    switch (name) {
      case 'Push-Up':
        return 'assets/exercises/push_up.png';
      case 'Dumbbell Bench Press':
        return 'assets/exercises/dumbbell_bench_press.png';
      default:
        return null;
    }
  }

  static ExercisePrescription _e(
    String name, {
    int sets = 3,
    String reps = '8–12',
    String rest = '75 sec',
    String equipment = 'Bodyweight',
    String target = 'General fitness',
    String? metricLabel,
  }) {
    return ExercisePrescription(
      name: name,
      sets: sets,
      reps: reps,
      rest: rest,
      equipment: equipment,
      target: target,
      visualAsset: _localAsset(name),
      metricLabel: metricLabel,
    );
  }

  static bool _has(Set<String> equipment, String item) {
    return equipment.contains(item);
  }

  static bool _basicGym(String? gymAccess) {
    return gymAccess == 'Basic gym' || gymAccess == "I'm not sure";
  }

  static GeneratedWorkout _fullBody(
    String title,
    String location,
    Set<String> homeEquipment,
    String? gymAccess,
  ) {
    if (location == 'Outside') {
      return GeneratedWorkout(
        title: '$title — Outside',
        exercises: [
          _e('Bodyweight Squat', reps: '12–20', target: 'Quads, glutes'),
          _e('Push-Up', reps: '8–15', target: 'Chest, triceps'),
          _e('Reverse Lunge', reps: '8–12 each leg', target: 'Quads, glutes'),
          _e('Bird Dog', reps: '8–12 each side', target: 'Core, back'),
          _e('Glute Bridge', reps: '12–20', target: 'Glutes'),
          _e('Plank', reps: '30–60 sec', rest: '60 sec', target: 'Core'),
        ],
      );
    }

    if (location == 'Home') {
      final hasDumbbells = _has(homeEquipment, 'Dumbbells');
      final hasBench = _has(homeEquipment, 'Bench');
      final hasBands = _has(homeEquipment, 'Resistance bands');
      final hasBarbell = _has(homeEquipment, 'Barbell');

      final press = hasDumbbells && hasBench
          ? _e(
              'Dumbbell Bench Press',
              equipment: 'Dumbbells + Bench',
              target: 'Chest, triceps',
            )
          : hasDumbbells
              ? _e(
                  'Dumbbell Floor Press',
                  equipment: 'Dumbbells',
                  target: 'Chest, triceps',
                )
              : _e('Push-Up', reps: '8–15', target: 'Chest, triceps');

      final pull = hasDumbbells
          ? _e(
              'One-Arm Dumbbell Row',
              equipment: 'Dumbbell',
              target: 'Back, biceps',
            )
          : hasBands
              ? _e(
                  'Band Row',
                  reps: '10–15',
                  equipment: 'Resistance band',
                  target: 'Back, biceps',
                )
              : _e(
                  'Bird Dog',
                  reps: '8–12 each side',
                  target: 'Core, back',
                );

      final hinge = hasDumbbells
          ? _e(
              'Dumbbell Romanian Deadlift',
              equipment: 'Dumbbells',
              target: 'Hamstrings, glutes',
            )
          : hasBarbell
              ? _e(
                  'Romanian Deadlift',
                  equipment: 'Barbell',
                  target: 'Hamstrings, glutes',
                )
              : hasBands
                  ? _e(
                      'Band Romanian Deadlift',
                      reps: '10–15',
                      equipment: 'Resistance band',
                      target: 'Hamstrings, glutes',
                    )
                  : _e(
                      'Glute Bridge',
                      reps: '12–20',
                      target: 'Glutes, hamstrings',
                    );

      final squat = hasDumbbells
          ? _e(
              'Goblet Squat',
              equipment: 'Dumbbell',
              target: 'Quads, glutes',
            )
          : hasBands
              ? _e(
                  'Banded Squat',
                  reps: '10–15',
                  equipment: 'Resistance band',
                  target: 'Quads, glutes',
                )
              : _e(
                  'Bodyweight Squat',
                  reps: '12–20',
                  target: 'Quads, glutes',
                );

      return GeneratedWorkout(
        title: '$title — Home',
        exercises: [
          squat,
          press,
          pull,
          hinge,
          _e('Reverse Lunge', reps: '8–12 each leg', target: 'Quads, glutes'),
          _e('Plank', reps: '30–60 sec', rest: '60 sec', target: 'Core'),
        ],
      );
    }

    if (_basicGym(gymAccess)) {
      return GeneratedWorkout(
        title: title,
        exercises: [
          _e('Goblet Squat', equipment: 'Dumbbell', target: 'Quads, glutes'),
          _e('Dumbbell Bench Press', equipment: 'Dumbbells + Bench', target: 'Chest, triceps'),
          _e('One-Arm Dumbbell Row', equipment: 'Dumbbell + Bench', target: 'Back, biceps'),
          _e('Dumbbell Romanian Deadlift', equipment: 'Dumbbells', target: 'Hamstrings, glutes'),
          _e('Dumbbell Shoulder Press', equipment: 'Dumbbells', target: 'Shoulders, triceps'),
          _e('Plank', reps: '30–60 sec', rest: '60 sec', target: 'Core'),
        ],
      );
    }

    return GeneratedWorkout(
      title: title,
      exercises: [
        _e('Leg Press', reps: '10–15', equipment: 'Leg Press Machine', target: 'Quads, glutes'),
        _e('Dumbbell Bench Press', equipment: 'Dumbbells + Bench', target: 'Chest, triceps'),
        _e('Lat Pulldown', equipment: 'Lat Pulldown Machine', target: 'Back, biceps'),
        _e('Romanian Deadlift', equipment: 'Barbell or Dumbbells', target: 'Hamstrings, glutes'),
        _e('Seated Dumbbell Shoulder Press', equipment: 'Dumbbells + Bench', target: 'Shoulders, triceps'),
        _e('Plank', reps: '30–60 sec', rest: '60 sec', target: 'Core'),
      ],
    );
  }

  static GeneratedWorkout _upper(
    String title,
    String location,
    Set<String> homeEquipment,
    String? gymAccess,
  ) {
    if (location == 'Outside') {
      return GeneratedWorkout(
        title: '$title — Outside',
        exercises: [
          _e('Push-Up', reps: '8–15', target: 'Chest, triceps'),
          _e('Close-Grip Push-Up', reps: '8–15', target: 'Chest, triceps'),
          _e('Prone Y-T Raise', reps: '8–12', target: 'Upper back, rear shoulders'),
          _e('Plank Shoulder Tap', reps: '8–12 each side', target: 'Shoulders, core'),
          _e('Plank', reps: '30–60 sec', target: 'Core'),
        ],
      );
    }

    if (location == 'Home') {
      final hasDumbbells = _has(homeEquipment, 'Dumbbells');
      final hasBench = _has(homeEquipment, 'Bench');
      final hasBands = _has(homeEquipment, 'Resistance bands');
      final hasPullup = _has(homeEquipment, 'Pull-up bar');

      final chest = hasDumbbells && hasBench
          ? _e('Dumbbell Bench Press', equipment: 'Dumbbells + Bench', target: 'Chest, triceps')
          : hasDumbbells
              ? _e('Dumbbell Floor Press', equipment: 'Dumbbells', target: 'Chest, triceps')
              : _e('Push-Up', reps: '8–15', target: 'Chest, triceps');

      final back = hasPullup
          ? _e('Pull-Up', reps: '5–10', equipment: 'Pull-up bar', target: 'Back, biceps')
          : hasDumbbells
              ? _e('One-Arm Dumbbell Row', equipment: 'Dumbbell', target: 'Back, biceps')
              : hasBands
                  ? _e('Band Row', reps: '10–15', equipment: 'Resistance band', target: 'Back, biceps')
                  : _e('Bird Dog', reps: '8–12 each side', target: 'Core, back');

      final shoulders = hasDumbbells
          ? _e('Dumbbell Shoulder Press', equipment: 'Dumbbells', target: 'Shoulders, triceps')
          : hasBands
              ? _e('Band Pull-Apart', reps: '12–20', equipment: 'Resistance band', target: 'Rear shoulders, upper back')
              : _e('Pike Push-Up', reps: '6–12', target: 'Shoulders, triceps');

      final biceps = hasDumbbells
          ? _e('Dumbbell Curl', reps: '10–15', equipment: 'Dumbbells', target: 'Biceps')
          : hasBands
              ? _e('Band Biceps Curl', reps: '10–15', equipment: 'Resistance band', target: 'Biceps')
              : hasPullup
                  ? _e('Chin-Up', reps: '5–10', equipment: 'Pull-up bar', target: 'Back, biceps')
                  : _e('Prone Y-T Raise', reps: '8–12', target: 'Upper back, rear shoulders');

      final triceps = hasDumbbells
          ? _e('Overhead Triceps Extension', reps: '10–15', equipment: 'Dumbbell', target: 'Triceps')
          : _e('Diamond Push-Up', reps: '6–12', target: 'Triceps, chest');

      return GeneratedWorkout(
        title: '$title — Home',
        exercises: [chest, back, shoulders, biceps, triceps],
      );
    }

    if (_basicGym(gymAccess)) {
      return GeneratedWorkout(
        title: title,
        exercises: [
          _e('Dumbbell Bench Press', equipment: 'Dumbbells + Bench', target: 'Chest, triceps'),
          _e('One-Arm Dumbbell Row', equipment: 'Dumbbell + Bench', target: 'Back, biceps'),
          _e('Dumbbell Shoulder Press', equipment: 'Dumbbells', target: 'Shoulders, triceps'),
          _e('Lateral Raise', reps: '12–15', equipment: 'Dumbbells', target: 'Shoulders'),
          _e('Hammer Curl', reps: '10–15', equipment: 'Dumbbells', target: 'Biceps'),
          _e('Overhead Triceps Extension', reps: '10–15', equipment: 'Dumbbell', target: 'Triceps'),
        ],
      );
    }

    final variantB = title.endsWith('B');
    return GeneratedWorkout(
      title: title,
      exercises: variantB
          ? [
              _e('Incline Dumbbell Press', equipment: 'Dumbbells + Bench', target: 'Chest, shoulders'),
              _e('Seated Cable Row', equipment: 'Cable Machine', target: 'Back, biceps'),
              _e('Machine Chest Press', equipment: 'Chest Press Machine', target: 'Chest, triceps'),
              _e('Lat Pulldown', equipment: 'Lat Pulldown Machine', target: 'Back, biceps'),
              _e('Lateral Raise', reps: '12–15', equipment: 'Dumbbells', target: 'Shoulders'),
              _e('Hammer Curl', reps: '10–15', equipment: 'Dumbbells', target: 'Biceps'),
            ]
          : [
              _e('Dumbbell Bench Press', equipment: 'Dumbbells + Bench', target: 'Chest, triceps'),
              _e('Lat Pulldown', equipment: 'Lat Pulldown Machine', target: 'Back, biceps'),
              _e('Seated Dumbbell Shoulder Press', equipment: 'Dumbbells + Bench', target: 'Shoulders, triceps'),
              _e('Seated Cable Row', equipment: 'Cable Machine', target: 'Back, biceps'),
              _e('Dumbbell Curl', reps: '10–15', equipment: 'Dumbbells', target: 'Biceps'),
              _e('Triceps Pushdown', reps: '10–15', equipment: 'Cable Machine', target: 'Triceps'),
            ],
    );
  }

  static GeneratedWorkout _lower(
    String title,
    String location,
    Set<String> homeEquipment,
    String? gymAccess,
  ) {
    if (location == 'Outside') {
      return GeneratedWorkout(
        title: '$title — Outside',
        exercises: [
          _e('Bodyweight Squat', reps: '12–20', target: 'Quads, glutes'),
          _e('Reverse Lunge', reps: '8–12 each leg', target: 'Quads, glutes'),
          _e('Step-Up', reps: '8–12 each leg', equipment: 'Stable step or bench', target: 'Quads, glutes'),
          _e('Glute Bridge', reps: '12–20', target: 'Glutes'),
          _e('Standing Calf Raise', reps: '12–20', target: 'Calves'),
          _e('Side Plank', reps: '20–45 sec each side', rest: '45 sec', target: 'Core'),
        ],
      );
    }

    if (location == 'Home') {
      final hasDumbbells = _has(homeEquipment, 'Dumbbells');
      final hasBands = _has(homeEquipment, 'Resistance bands');
      final hasBarbell = _has(homeEquipment, 'Barbell');

      final squat = hasDumbbells
          ? _e('Goblet Squat', equipment: 'Dumbbell', target: 'Quads, glutes')
          : hasBands
              ? _e('Banded Squat', reps: '10–15', equipment: 'Resistance band', target: 'Quads, glutes')
              : _e('Bodyweight Squat', reps: '12–20', target: 'Quads, glutes');

      final hinge = hasDumbbells
          ? _e('Dumbbell Romanian Deadlift', equipment: 'Dumbbells', target: 'Hamstrings, glutes')
          : hasBarbell
              ? _e('Romanian Deadlift', equipment: 'Barbell', target: 'Hamstrings, glutes')
              : hasBands
                  ? _e('Band Romanian Deadlift', reps: '10–15', equipment: 'Resistance band', target: 'Hamstrings, glutes')
                  : _e('Glute Bridge', reps: '12–20', target: 'Glutes, hamstrings');

      return GeneratedWorkout(
        title: '$title — Home',
        exercises: [
          squat,
          hinge,
          _e('Reverse Lunge', reps: '8–12 each leg', target: 'Quads, glutes'),
          _e('Glute Bridge', reps: '12–20', target: 'Glutes'),
          _e('Standing Calf Raise', reps: '12–20', target: 'Calves'),
          _e('Dead Bug', reps: '8–12 each side', rest: '60 sec', target: 'Core'),
        ],
      );
    }

    if (_basicGym(gymAccess)) {
      return GeneratedWorkout(
        title: title,
        exercises: [
          _e('Goblet Squat', equipment: 'Dumbbell', target: 'Quads, glutes'),
          _e('Dumbbell Romanian Deadlift', equipment: 'Dumbbells', target: 'Hamstrings, glutes'),
          _e('Split Squat', reps: '8–12 each leg', equipment: 'Bodyweight or Dumbbells', target: 'Quads, glutes'),
          _e('Hip Thrust', reps: '8–12', equipment: 'Bench + Weight', target: 'Glutes'),
          _e('Standing Calf Raise', reps: '12–20', target: 'Calves'),
          _e('Dead Bug', reps: '8–12 each side', rest: '60 sec', target: 'Core'),
        ],
      );
    }

    final variantB = title.endsWith('B');
    return GeneratedWorkout(
      title: title,
      exercises: variantB
          ? [
              _e('Hip Thrust', equipment: 'Bench + Weight', target: 'Glutes'),
              _e('Bulgarian Split Squat', reps: '8–12 each leg', equipment: 'Bench + Dumbbells', target: 'Quads, glutes'),
              _e('Romanian Deadlift', equipment: 'Barbell or Dumbbells', target: 'Hamstrings, glutes'),
              _e('Seated Leg Curl', reps: '10–15', equipment: 'Leg Curl Machine', target: 'Hamstrings'),
              _e('Seated Calf Raise', reps: '10–15', equipment: 'Calf Raise Machine', target: 'Calves'),
              _e('Dead Bug', reps: '8–12 each side', rest: '60 sec', target: 'Core'),
            ]
          : [
              _e('Leg Press', reps: '10–15', equipment: 'Leg Press Machine', target: 'Quads, glutes'),
              _e('Romanian Deadlift', equipment: 'Barbell or Dumbbells', target: 'Hamstrings, glutes'),
              _e('Split Squat', reps: '8–12 each leg', equipment: 'Bodyweight or Dumbbells', target: 'Quads, glutes'),
              _e('Leg Curl', reps: '10–15', equipment: 'Leg Curl Machine', target: 'Hamstrings'),
              _e('Calf Raise', reps: '10–15', equipment: 'Machine or Free Weight', target: 'Calves'),
              _e('Plank', reps: '30–60 sec', rest: '60 sec', target: 'Core'),
            ],
    );
  }

  static GeneratedWorkout _push(
    String title,
    String location,
    Set<String> homeEquipment,
    String? gymAccess,
  ) {
    if (location != 'Gym') {
      return _upper(title, location, homeEquipment, gymAccess);
    }

    if (_basicGym(gymAccess)) {
      return GeneratedWorkout(
        title: title,
        exercises: [
          _e('Dumbbell Bench Press', equipment: 'Dumbbells + Bench', target: 'Chest, triceps'),
          _e('Incline Dumbbell Press', equipment: 'Dumbbells + Bench', target: 'Chest, shoulders'),
          _e('Dumbbell Shoulder Press', equipment: 'Dumbbells', target: 'Shoulders, triceps'),
          _e('Lateral Raise', reps: '12–15', equipment: 'Dumbbells', target: 'Shoulders'),
          _e('Overhead Triceps Extension', reps: '10–15', equipment: 'Dumbbell', target: 'Triceps'),
        ],
      );
    }

    return GeneratedWorkout(
      title: title,
      exercises: [
        _e('Barbell Bench Press', reps: '6–10', equipment: 'Barbell + Bench', target: 'Chest, triceps'),
        _e('Incline Dumbbell Press', equipment: 'Dumbbells + Bench', target: 'Chest, shoulders'),
        _e('Machine Shoulder Press', equipment: 'Shoulder Press Machine', target: 'Shoulders, triceps'),
        _e('Cable Lateral Raise', reps: '12–15', equipment: 'Cable Machine', target: 'Shoulders'),
        _e('Triceps Pushdown', reps: '10–15', equipment: 'Cable Machine', target: 'Triceps'),
        _e('Cable Overhead Extension', reps: '10–15', equipment: 'Cable Machine', target: 'Triceps'),
      ],
    );
  }

  static GeneratedWorkout _pull(
    String title,
    String location,
    Set<String> homeEquipment,
    String? gymAccess,
  ) {
    if (location != 'Gym') {
      return _upper(title, location, homeEquipment, gymAccess);
    }

    if (_basicGym(gymAccess)) {
      return GeneratedWorkout(
        title: title,
        exercises: [
          _e('One-Arm Dumbbell Row', equipment: 'Dumbbell + Bench', target: 'Back, biceps'),
          _e('Chest-Supported Dumbbell Row', equipment: 'Dumbbells + Bench', target: 'Back, biceps'),
          _e('Dumbbell Pullover', equipment: 'Dumbbell + Bench', target: 'Back, chest'),
          _e('Reverse Fly', reps: '12–15', equipment: 'Dumbbells', target: 'Rear shoulders, upper back'),
          _e('Dumbbell Curl', reps: '10–15', equipment: 'Dumbbells', target: 'Biceps'),
          _e('Hammer Curl', reps: '10–15', equipment: 'Dumbbells', target: 'Biceps'),
        ],
      );
    }

    return GeneratedWorkout(
      title: title,
      exercises: [
        _e('Lat Pulldown', equipment: 'Lat Pulldown Machine', target: 'Back, biceps'),
        _e('Seated Cable Row', equipment: 'Cable Machine', target: 'Back, biceps'),
        _e('T-Bar Row', equipment: 'T-Bar Row', target: 'Back, biceps'),
        _e('Face Pull', reps: '12–15', equipment: 'Cable Machine', target: 'Rear shoulders, upper back'),
        _e('EZ-Bar Curl', reps: '10–15', equipment: 'EZ-Bar', target: 'Biceps'),
        _e('Hammer Curl', reps: '10–15', equipment: 'Dumbbells', target: 'Biceps'),
      ],
    );
  }

  static GeneratedWorkout _conditioning(
    String title,
    String location,
    Set<String> homeEquipment,
    String? gymAccess,
  ) {
    final strength = _fullBody(
      title,
      location,
      homeEquipment,
      gymAccess,
    ).exercises;

    final finisher = location == 'Gym'
        ? _e(
            'Stationary Bike',
            sets: 1,
            reps: '8–12 min easy-to-moderate',
            rest: 'As needed',
            equipment: 'Stationary bike',
            target: 'Cardiovascular fitness',
            metricLabel: 'DURATION',
          )
        : location == 'Outside'
            ? _e(
                'Brisk Walk',
                sets: 1,
                reps: '10–20 min',
                rest: 'As needed',
                equipment: 'None',
                target: 'Cardiovascular fitness',
                metricLabel: 'DURATION',
              )
            : _e(
                'March in Place',
                sets: 1,
                reps: '8–12 min',
                rest: 'As needed',
                equipment: 'Bodyweight',
                target: 'Cardiovascular fitness',
                metricLabel: 'DURATION',
              );

    return GeneratedWorkout(
      title: "$title${location == 'Gym' ? '' : ' — $location'}",
      exercises: [...strength.take(5), finisher],
    );
  }

  static GeneratedWorkout _cardioBase(String title, String location) {
    if (location == 'Outside') {
      return GeneratedWorkout(
        title: '$title — Outside',
        exercises: [
          _e('Warm-Up Walk', sets: 1, reps: '5–10 min', rest: 'None', target: 'Warm-up', metricLabel: 'DURATION'),
          _e('Brisk Walk', sets: 1, reps: '20–40 min', rest: 'As needed', target: 'Cardiovascular fitness', metricLabel: 'DURATION'),
          _e('Calf Stretch', sets: 2, reps: '20–30 sec each side', rest: '30 sec', target: 'Calves'),
        ],
      );
    }

    if (location == 'Gym') {
      return GeneratedWorkout(
        title: '$title — Gym',
        exercises: [
          _e('Stationary Bike', sets: 1, reps: '20–35 min easy-to-moderate', rest: 'As needed', equipment: 'Stationary bike', target: 'Cardiovascular fitness', metricLabel: 'DURATION'),
          _e('Elliptical', sets: 1, reps: '10–20 min optional', rest: 'As needed', equipment: 'Elliptical machine', target: 'Cardiovascular fitness', metricLabel: 'DURATION'),
          _e('Hamstring Stretch', sets: 2, reps: '20–30 sec each side', rest: '30 sec', target: 'Hamstrings'),
        ],
      );
    }

    return GeneratedWorkout(
      title: '$title — Home',
      exercises: [
        _e('March in Place', sets: 1, reps: '5 min easy', rest: 'None', target: 'Warm-up', metricLabel: 'DURATION'),
        _e('High Knees', sets: 6, reps: '20–30 sec', rest: '30–45 sec', target: 'Cardiovascular fitness'),
        _e('Mountain Climber', sets: 4, reps: '20–30 sec', rest: '45 sec', target: 'Cardiovascular fitness, core'),
        _e('March in Place', sets: 1, reps: '5–10 min easy', rest: 'As needed', target: 'Cool-down', metricLabel: 'DURATION'),
      ],
    );
  }

  static GeneratedWorkout _cardioIntervals(String title, String location) {
    if (location == 'Outside') {
      return GeneratedWorkout(
        title: '$title — Outside',
        exercises: [
          _e('Warm-Up Walk', sets: 1, reps: '8–10 min', rest: 'None', target: 'Warm-up', metricLabel: 'DURATION'),
          _e('Fartlek Run', sets: 6, reps: '1 min faster / 2 min easy', rest: 'Easy movement', target: 'Cardiovascular fitness'),
          _e('Brisk Walk', sets: 1, reps: '5–10 min easy', rest: 'None', target: 'Cool-down', metricLabel: 'DURATION'),
        ],
      );
    }

    if (location == 'Gym') {
      return GeneratedWorkout(
        title: '$title — Gym',
        exercises: [
          _e('Stationary Bike', sets: 1, reps: '8 min easy warm-up', rest: 'None', equipment: 'Stationary bike', target: 'Warm-up', metricLabel: 'DURATION'),
          _e('Treadmill Intervals', sets: 6, reps: '1 min faster / 2 min easy', rest: 'Easy movement', equipment: 'Treadmill', target: 'Cardiovascular fitness'),
          _e('Stationary Bike', sets: 1, reps: '5 min easy', rest: 'None', equipment: 'Stationary bike', target: 'Cool-down', metricLabel: 'DURATION'),
        ],
      );
    }

    return GeneratedWorkout(
      title: '$title — Home',
      exercises: [
        _e('March in Place', sets: 1, reps: '5 min easy', rest: 'None', target: 'Warm-up', metricLabel: 'DURATION'),
        _e('High Knees', sets: 8, reps: '20 sec', rest: '40 sec', target: 'Cardiovascular fitness'),
        _e('Mountain Climber', sets: 6, reps: '20 sec', rest: '40 sec', target: 'Cardiovascular fitness, core'),
        _e('March in Place', sets: 1, reps: '5 min easy', rest: 'None', target: 'Cool-down', metricLabel: 'DURATION'),
      ],
    );
  }

  static GeneratedWorkout _mobilityCore(String title, String location) {
    return GeneratedWorkout(
      title: '$title — $location',
      exercises: [
        _e('Cat-Cow', sets: 2, reps: '6–10 controlled', rest: '30 sec', target: 'Spine mobility'),
        _e('Thoracic Rotation', sets: 2, reps: '6–10 each side', rest: '30 sec', target: 'Upper-back mobility'),
        _e('Hip Flexor Stretch', sets: 2, reps: '20–30 sec each side', rest: '30 sec', target: 'Hip mobility'),
        _e('Dead Bug', sets: 3, reps: '8–12 each side', rest: '45 sec', target: 'Core'),
        _e('Bird Dog', sets: 3, reps: '8–12 each side', rest: '45 sec', target: 'Core, back'),
        _e('Side Plank', sets: 3, reps: '20–45 sec each side', rest: '45 sec', target: 'Core'),
      ],
    );
  }

  static GeneratedWorkout _runnerStrength(
    String title,
    String location,
    Set<String> homeEquipment,
    String? gymAccess,
  ) {
    if (location == 'Gym') {
      return GeneratedWorkout(
        title: '$title — Gym',
        exercises: [
          _e('Goblet Squat', reps: '8–12', equipment: 'Dumbbell', target: 'Quads, glutes'),
          _e('Romanian Deadlift', reps: '8–12', equipment: 'Barbell or Dumbbells', target: 'Hamstrings, glutes'),
          _e('Step-Up', reps: '8–12 each leg', equipment: 'Bench + Dumbbells', target: 'Quads, glutes'),
          _e('Standing Calf Raise', reps: '12–20', target: 'Calves'),
          _e('Dead Bug', reps: '8–12 each side', rest: '45 sec', target: 'Core'),
        ],
      );
    }

    return GeneratedWorkout(
      title: '$title — $location',
      exercises: [
        _e('Bodyweight Squat', reps: '12–20', target: 'Quads, glutes'),
        _e('Reverse Lunge', reps: '8–12 each leg', target: 'Quads, glutes'),
        _e('Glute Bridge', reps: '12–20', target: 'Glutes'),
        _e('Standing Calf Raise', reps: '12–20', target: 'Calves'),
        _e('Dead Bug', reps: '8–12 each side', rest: '45 sec', target: 'Core'),
      ],
    );
  }

  static GeneratedWorkout _runningWorkout(String title, String location) {
    if (location == 'Home') {
      return _cardioBase('Home Cardio Base', 'Home');
    }

    final treadmill = location == 'Gym';
    final runEquipment = treadmill ? 'Treadmill' : 'Running shoes / safe route';

    switch (title) {
      case 'Run-Walk Easy':
        return GeneratedWorkout(
          title: '$title — $location',
          exercises: [
            _e('Warm-Up Walk', sets: 1, reps: '5–10 min', rest: 'None', equipment: runEquipment, target: 'Warm-up', metricLabel: 'DURATION'),
            _e(treadmill ? 'Treadmill Easy Run' : 'Run-Walk Intervals', sets: 8, reps: '1 min easy run / 2 min walk', rest: 'Walk segment', equipment: runEquipment, target: 'Running foundation'),
            _e('Brisk Walk', sets: 1, reps: '5–10 min easy', rest: 'None', equipment: runEquipment, target: 'Cool-down', metricLabel: 'DURATION'),
          ],
        );

      case 'Easy Run':
        return GeneratedWorkout(
          title: '$title — $location',
          exercises: [
            _e('Warm-Up Walk', sets: 1, reps: '5–10 min', rest: 'None', equipment: runEquipment, target: 'Warm-up', metricLabel: 'DURATION'),
            _e(treadmill ? 'Treadmill Easy Run' : 'Easy Run', sets: 1, reps: '20–40 min comfortable', rest: 'As needed', equipment: runEquipment, target: 'Aerobic endurance', metricLabel: 'DURATION'),
            _e('Calf Stretch', sets: 2, reps: '20–30 sec each side', rest: '30 sec', target: 'Calves'),
          ],
        );

      case 'Long Easy Run':
      case 'Long Run':
        return GeneratedWorkout(
          title: '$title — $location',
          exercises: [
            _e('Warm-Up Walk', sets: 1, reps: '8–10 min', rest: 'None', equipment: runEquipment, target: 'Warm-up', metricLabel: 'DURATION'),
            _e(treadmill ? 'Treadmill Easy Run' : 'Long Easy Run', sets: 1, reps: title == 'Long Run' ? '45–75 min controlled' : '30–50 min comfortable', rest: 'As needed', equipment: runEquipment, target: 'Aerobic endurance', metricLabel: 'DURATION'),
            _e('Brisk Walk', sets: 1, reps: '5–10 min easy', rest: 'None', equipment: runEquipment, target: 'Cool-down', metricLabel: 'DURATION'),
          ],
        );

      case 'Recovery Run':
        return GeneratedWorkout(
          title: '$title — $location',
          exercises: [
            _e(treadmill ? 'Treadmill Easy Run' : 'Recovery Run', sets: 1, reps: '20–35 min very easy', rest: 'As needed', equipment: runEquipment, target: 'Easy aerobic recovery', metricLabel: 'DURATION'),
            _e('Calf Stretch', sets: 2, reps: '20–30 sec each side', rest: '30 sec', target: 'Calves'),
          ],
        );

      case 'Intervals':
      case 'Quality Run':
        return GeneratedWorkout(
          title: '$title — $location',
          exercises: [
            _e('Warm-Up Walk', sets: 1, reps: '8–10 min', rest: 'None', equipment: runEquipment, target: 'Warm-up', metricLabel: 'DURATION'),
            _e(treadmill ? 'Treadmill Intervals' : 'Interval Run', sets: 6, reps: '2 min strong / 2 min easy', rest: 'Easy segment', equipment: runEquipment, target: 'Running speed and aerobic power'),
            _e('Brisk Walk', sets: 1, reps: '5–10 min easy', rest: 'None', equipment: runEquipment, target: 'Cool-down', metricLabel: 'DURATION'),
          ],
        );

      case 'Tempo Run':
        return GeneratedWorkout(
          title: '$title — $location',
          exercises: [
            _e('Warm-Up Walk', sets: 1, reps: '8–10 min', rest: 'None', equipment: runEquipment, target: 'Warm-up', metricLabel: 'DURATION'),
            _e('Tempo Run', sets: 1, reps: '15–25 min comfortably hard', rest: 'As needed', equipment: runEquipment, target: 'Sustained running performance', metricLabel: 'DURATION'),
            _e('Easy Run', sets: 1, reps: '5–10 min easy', rest: 'None', equipment: runEquipment, target: 'Cool-down', metricLabel: 'DURATION'),
          ],
        );

      default:
        return _cardioBase(title, location);
    }
  }
}
