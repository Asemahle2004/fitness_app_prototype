import 'dart:math' as math;

import 'master_exercise_catalogue.dart';
import 'training_profile_context.dart';
import 'workout_engine.dart';

class ExercisePrescriptionGuidance {
  final String exerciseName;
  final String role;
  final String difficulty;
  final String startingLoadGuidance;
  final int estimatedSeconds;
  final List<String> alternatives;

  const ExercisePrescriptionGuidance({
    required this.exerciseName,
    required this.role,
    required this.difficulty,
    required this.startingLoadGuidance,
    required this.estimatedSeconds,
    required this.alternatives,
  });
}

class ExerciseIntelligenceEngine {
  const ExerciseIntelligenceEngine._();

  static final Map<String, ExercisePrescriptionGuidance> _latestGuidance = {};

  static ExercisePrescriptionGuidance? guidanceFor(String exerciseName) =>
      _latestGuidance[MasterExerciseCatalogue.normalize(exerciseName)];

  static GeneratedWorkout generate({
    required String sessionTitle,
    required String location,
    required String? sessionDuration,
    Set<String> homeEquipment = const <String>{},
    String? gymAccess,
    TrainingProfileContext? profile,
  }) {
    final context = profile ?? TrainingProfileContext.current;
    final experience = context?.experience ?? 'Beginner';
    final goals = context?.goals ?? const <String>['Improve General Fitness'];
    final targetMinutes =
        _minutes(sessionDuration ?? context?.sessionLength ?? '45 min');
    final slots = _slotsFor(sessionTitle, goals);
    final selected = <MasterExerciseDefinition>[];

    for (final slot in slots) {
      final candidate = _bestCandidate(
        slot: slot,
        location: location,
        homeEquipment: homeEquipment,
        gymAccess: gymAccess,
        experience: experience,
        alreadySelected: selected,
      );
      if (candidate != null) selected.add(candidate);
    }

    if (selected.isEmpty) {
      return WorkoutEngine.generate(
        sessionTitle: sessionTitle,
        location: location,
        homeEquipment: homeEquipment,
        gymAccess: gymAccess,
        sessionDuration: sessionDuration,
      );
    }

    var prescriptions = selected
        .map(
          (definition) => _prescribe(
            definition,
            experience: experience,
            goals: goals,
            sessionTitle: sessionTitle,
            location: location,
            homeEquipment: homeEquipment,
            gymAccess: gymAccess,
          ),
        )
        .toList(growable: true);

    prescriptions = _fitToRealDuration(
      prescriptions,
      targetMinutes: targetMinutes,
      experience: experience,
    );

    _rememberGuidance(
      prescriptions,
      selected,
      experience: experience,
      goals: goals,
      location: location,
      homeEquipment: homeEquipment,
      gymAccess: gymAccess,
    );

    return GeneratedWorkout(title: sessionTitle, exercises: prescriptions);
  }

  static int estimateWorkoutSeconds(List<ExercisePrescription> exercises) {
    if (exercises.isEmpty) return 0;
    var seconds = 0;
    for (var index = 0; index < exercises.length; index++) {
      final exercise = exercises[index];
      seconds += estimateExerciseSeconds(exercise);
      if (index < exercises.length - 1) seconds += 30;
    }
    return seconds + 90;
  }

  static int estimateExerciseSeconds(ExercisePrescription exercise) {
    if (exercise.isSingleDurationBlock) {
      return _durationSeconds(exercise.reps).clamp(60, 60 * 60);
    }
    final rest = _restSeconds(exercise.rest);
    final perSet = _workSeconds(exercise.reps);
    final setup = _setupSeconds(exercise.name, exercise.equipment);
    return setup +
        (perSet * exercise.sets) +
        (rest * math.max(0, exercise.sets - 1));
  }

  static List<_Slot> _slotsFor(String title, List<String> goals) {
    final value = title.toLowerCase();
    if (value.contains('mobility')) {
      return const [
        _Slot(pattern: 'Mobility / Stretching'),
        _Slot(groups: ['Core & Obliques']),
        _Slot(groups: ['Outer Hip / Abductors']),
        _Slot(groups: ['Rotator Cuff & Shoulder Stability']),
      ];
    }
    if (value.contains('cardio') || value.contains('conditioning')) {
      return const [
        _Slot(groups: ['Full Body']),
        _Slot(groups: ['Whole Lower Body']),
        _Slot(groups: ['Core & Obliques']),
        _Slot(groups: ['Cardio']),
      ];
    }
    if (value.contains('runner strength')) {
      return const [
        _Slot(pattern: 'Squat / Knee Dominant'),
        _Slot(pattern: 'Hip Hinge / Hip Extension'),
        _Slot(pattern: 'Lunge / Single-Leg'),
        _Slot(groups: ['Calves']),
        _Slot(groups: ['Shins / Tibialis']),
        _Slot(groups: ['Core & Obliques']),
      ];
    }
    if (value.contains('push')) {
      return const [
        _Slot(pattern: 'Horizontal Push'),
        _Slot(pattern: 'Vertical Push'),
        _Slot(groups: ['Shoulders']),
        _Slot(groups: ['Triceps']),
        _Slot(groups: ['Chest']),
      ];
    }
    if (value.contains('pull')) {
      return const [
        _Slot(pattern: 'Vertical Pull'),
        _Slot(pattern: 'Horizontal Pull'),
        _Slot(groups: ['Lats']),
        _Slot(groups: ['Biceps']),
        _Slot(groups: ['Forearms & Grip']),
      ];
    }
    if (value.contains('upper')) {
      return const [
        _Slot(pattern: 'Horizontal Push'),
        _Slot(pattern: 'Vertical Pull'),
        _Slot(pattern: 'Vertical Push'),
        _Slot(pattern: 'Horizontal Pull'),
        _Slot(groups: ['Biceps']),
        _Slot(groups: ['Triceps']),
      ];
    }
    if (value.contains('lower')) {
      return const [
        _Slot(pattern: 'Squat / Knee Dominant'),
        _Slot(pattern: 'Hip Hinge / Hip Extension'),
        _Slot(pattern: 'Lunge / Single-Leg'),
        _Slot(groups: ['Glutes']),
        _Slot(groups: ['Hamstrings']),
        _Slot(groups: ['Calves']),
        _Slot(groups: ['Core & Obliques']),
      ];
    }
    return const [
      _Slot(pattern: 'Squat / Knee Dominant'),
      _Slot(pattern: 'Horizontal Push'),
      _Slot(pattern: 'Vertical Pull'),
      _Slot(pattern: 'Hip Hinge / Hip Extension'),
      _Slot(pattern: 'Vertical Push'),
      _Slot(pattern: 'Horizontal Pull'),
      _Slot(groups: ['Core & Obliques']),
    ];
  }

  static MasterExerciseDefinition? _bestCandidate({
    required _Slot slot,
    required String location,
    required Set<String> homeEquipment,
    required String? gymAccess,
    required String experience,
    required List<MasterExerciseDefinition> alreadySelected,
  }) {
    MasterExerciseDefinition? best;
    var bestScore = -100000;
    final used = alreadySelected
        .map((item) => MasterExerciseCatalogue.normalize(item.name))
        .toSet();

    for (final definition in MasterExerciseCatalogue.definitions) {
      if (definition.exerciseType != 'Strength & Muscle' &&
          !slot.groups.contains('Cardio') &&
          slot.pattern != 'Mobility / Stretching') {
        continue;
      }
      if (used.contains(MasterExerciseCatalogue.normalize(definition.name))) {
        continue;
      }
      final equipment = MasterExerciseCatalogue.inferredEquipment(
        definition.name,
        definition.exerciseType,
      );
      final locations = MasterExerciseCatalogue.inferredLocations(
        definition.name,
        definition.exerciseType,
        equipment,
      );
      if (!locations.contains(_normaliseLocation(location))) continue;
      if (!_equipmentAllowed(equipment, location, homeEquipment, gymAccess)) {
        continue;
      }

      final pattern = MasterExerciseCatalogue.inferredMovementPattern(
        definition.name,
        definition.exerciseType,
      );
      var score = 0;
      if (slot.pattern != null) {
        if (pattern == slot.pattern) {
          score += 120;
        } else {
          continue;
        }
      }
      if (slot.groups.isNotEmpty) {
        final overlap = definition.groups.where(slot.groups.contains).length;
        if (overlap == 0) continue;
        score += overlap * 100;
      }

      final difficulty = MasterExerciseCatalogue.inferredDifficulty(
        definition.name,
        definition.exerciseType,
      );
      score += _difficultyScore(difficulty, experience);
      score += _stabilityScore(definition.name, experience);
      score -= MasterExerciseCatalogue.sectionIndex(definition.section);

      if (score > bestScore) {
        best = definition;
        bestScore = score;
      }
    }
    return best;
  }

  static ExercisePrescription _prescribe(
    MasterExerciseDefinition definition, {
    required String experience,
    required List<String> goals,
    required String sessionTitle,
    required String location,
    required Set<String> homeEquipment,
    required String? gymAccess,
  }) {
    final pattern = MasterExerciseCatalogue.inferredMovementPattern(
      definition.name,
      definition.exerciseType,
    );
    final equipment = MasterExerciseCatalogue.inferredEquipment(
      definition.name,
      definition.exerciseType,
    );
    final compound = _isCompound(pattern);
    final buildMuscle =
        goals.contains('Build Muscle') || goals.contains('Gain Weight');
    final strengthBiased = sessionTitle.toLowerCase().contains('strength');

    int sets;
    String reps;
    String rest;
    if (experience == 'Beginner') {
      sets = 2;
      reps = compound ? '8–12' : '10–15';
      rest = compound ? '120 sec' : '75 sec';
    } else if (experience == 'Advanced') {
      sets = compound ? (strengthBiased ? 4 : 3) : 3;
      reps = compound
          ? (strengthBiased
              ? '5–8'
              : (buildMuscle ? '6–10' : '6–12'))
          : '10–20';
      rest = compound ? (strengthBiased ? '180 sec' : '150 sec') : '75 sec';
    } else {
      sets = 3;
      reps = compound ? (buildMuscle ? '6–12' : '8–12') : '10–15';
      rest = compound ? '120 sec' : '75 sec';
    }

    final muscles =
        MasterExerciseCatalogue.primaryMusclesFor(definition.section);
    return ExercisePrescription(
      name: definition.name,
      sets: sets,
      reps: reps,
      rest: rest,
      equipment: equipment.join(' + '),
      target: muscles.join(', '),
    );
  }

  static List<ExercisePrescription> _fitToRealDuration(
    List<ExercisePrescription> source, {
    required int targetMinutes,
    required String experience,
  }) {
    if (source.isEmpty) return source;
    final targetSeconds = math.max(10, targetMinutes) * 60;
    final prepReserve = targetMinutes <= 20
        ? 4 * 60
        : (targetMinutes <= 45 ? 6 * 60 : 8 * 60);
    final workBudget = math.max(5 * 60, targetSeconds - prepReserve);
    final result = <ExercisePrescription>[];

    for (final exercise in source) {
      final trial = [...result, exercise];
      if (estimateWorkoutSeconds(trial) <= workBudget || result.length < 3) {
        result.add(exercise);
      }
    }

    while (estimateWorkoutSeconds(result) > workBudget && result.length > 3) {
      result.removeLast();
    }

    var index = 0;
    while (result.isNotEmpty &&
        estimateWorkoutSeconds(result) < workBudget - 4 * 60 &&
        index < result.length * 2) {
      final protectedCount = result.length < 3 ? result.length : 3;
      final target = index % protectedCount;
      final exercise = result[target];
      if (exercise.sets < (experience == 'Beginner' ? 3 : 5)) {
        final expanded = exercise.copyWith(sets: exercise.sets + 1);
        final trial = [...result]..[target] = expanded;
        if (estimateWorkoutSeconds(trial) <= workBudget) {
          result[target] = expanded;
        }
      }
      index++;
    }
    return result;
  }

  static void _rememberGuidance(
    List<ExercisePrescription> prescriptions,
    List<MasterExerciseDefinition> selected, {
    required String experience,
    required List<String> goals,
    required String location,
    required Set<String> homeEquipment,
    required String? gymAccess,
  }) {
    for (final exercise in prescriptions) {
      final definition = selected.firstWhere(
        (item) =>
            MasterExerciseCatalogue.normalize(item.name) ==
            MasterExerciseCatalogue.normalize(exercise.name),
      );
      final difficulty = MasterExerciseCatalogue.inferredDifficulty(
        definition.name,
        definition.exerciseType,
      );
      final pattern = MasterExerciseCatalogue.inferredMovementPattern(
        definition.name,
        definition.exerciseType,
      );
      final alternatives = MasterExerciseCatalogue.definitions
          .where((candidate) => candidate.name != definition.name)
          .where(
            (candidate) =>
                MasterExerciseCatalogue.inferredMovementPattern(
                  candidate.name,
                  candidate.exerciseType,
                ) ==
                pattern,
          )
          .where((candidate) {
            final equipment = MasterExerciseCatalogue.inferredEquipment(
              candidate.name,
              candidate.exerciseType,
            );
            final locations = MasterExerciseCatalogue.inferredLocations(
              candidate.name,
              candidate.exerciseType,
              equipment,
            );
            return locations.contains(_normaliseLocation(location)) &&
                _equipmentAllowed(
                  equipment,
                  location,
                  homeEquipment,
                  gymAccess,
                );
          })
          .take(5)
          .map((item) => item.name)
          .toList(growable: false);

      _latestGuidance[MasterExerciseCatalogue.normalize(exercise.name)] =
          ExercisePrescriptionGuidance(
        exerciseName: exercise.name,
        role: pattern,
        difficulty: difficulty,
        startingLoadGuidance:
            _startingLoadGuidance(experience, exercise.equipment),
        estimatedSeconds: estimateExerciseSeconds(exercise),
        alternatives: alternatives,
      );
    }
  }

  static String _startingLoadGuidance(String experience, String equipment) {
    final weighted = !equipment.toLowerCase().contains('bodyweight');
    if (!weighted) {
      return experience == 'Beginner'
          ? 'Start with controlled bodyweight reps and stop with about 3 reps still possible.'
          : 'Use the prescribed variation and keep about 1–3 reps in reserve unless the programme says otherwise.';
    }
    if (experience == 'Beginner') {
      return 'Begin conservatively. Choose a load that lets you finish the target with about 3 reps in reserve; LeanIt learns the real working weight from logged sets.';
    }
    return 'Use a recent comfortable working weight when known. Otherwise start light enough to keep about 2 reps in reserve and let logged performance drive progression.';
  }

  static bool _equipmentAllowed(
    List<String> required,
    String location,
    Set<String> homeEquipment,
    String? gymAccess,
  ) {
    final place = _normaliseLocation(location);
    final joined = required.join(' ').toLowerCase();
    if (joined.contains('bodyweight')) return true;
    if (place == 'Outside') {
      return joined.contains('bodyweight') || joined.contains('sled');
    }
    if (place == 'Gym') {
      if (gymAccess == 'Basic gym' || gymAccess == "I'm not sure") {
        return !joined.contains('machine') ||
            joined.contains('dumbbell') ||
            joined.contains('barbell');
      }
      return true;
    }
    final available =
        homeEquipment.map((item) => item.toLowerCase()).join(' ');
    if (available.isEmpty) return false;
    if (joined.contains('dumbbell') && available.contains('dumbbell')) {
      return true;
    }
    if (joined.contains('kettlebell') && available.contains('kettlebell')) {
      return true;
    }
    if (joined.contains('barbell') && available.contains('barbell')) return true;
    if (joined.contains('band') && available.contains('band')) return true;
    if (joined.contains('pull-up') && available.contains('pull-up')) return true;
    if (joined.contains('bench') && available.contains('bench')) return true;
    if (joined.contains('jump rope') &&
        (available.contains('rope') || available.contains('skipping'))) {
      return true;
    }
    return false;
  }

  static int _difficultyScore(String difficulty, String experience) {
    if (experience == 'Beginner') {
      return difficulty == 'Beginner'
          ? 80
          : (difficulty == 'Intermediate' ? 20 : -100);
    }
    if (experience == 'Advanced') {
      return difficulty == 'Advanced'
          ? 50
          : (difficulty == 'Intermediate' ? 45 : 20);
    }
    return difficulty == 'Intermediate' ? 70 : 35;
  }

  static int _stabilityScore(String name, String experience) {
    final value = name.toLowerCase();
    if (experience != 'Beginner') return 0;
    if (value.contains('machine') ||
        value.contains('leg press') ||
        value.contains('goblet')) {
      return 25;
    }
    if (value.contains('clean') ||
        value.contains('handstand') ||
        value.contains('sissy')) {
      return -80;
    }
    return 0;
  }

  static bool _isCompound(String pattern) => const {
        'Squat / Knee Dominant',
        'Hip Hinge / Hip Extension',
        'Lunge / Single-Leg',
        'Horizontal Push',
        'Vertical Push',
        'Horizontal Pull',
        'Vertical Pull',
        'Loaded Carry',
      }.contains(pattern);

  static int _setupSeconds(String name, String equipment) {
    final value = '${name.toLowerCase()} ${equipment.toLowerCase()}';
    if (value.contains('barbell')) return 90;
    if (value.contains('machine')) return 45;
    if (value.contains('dumbbell') || value.contains('kettlebell')) return 40;
    if (value.contains('cable')) return 45;
    return 20;
  }

  static int _workSeconds(String reps) {
    if (reps.toLowerCase().contains('sec')) return _durationSeconds(reps);
    final numbers = RegExp(r'\d+')
        .allMatches(reps)
        .map((match) => int.parse(match.group(0)!))
        .toList();
    final repsTarget = numbers.isEmpty ? 10 : numbers.last.clamp(1, 30);
    return (repsTarget * 3).clamp(20, 100);
  }

  static int _durationSeconds(String value) {
    final lower = value.toLowerCase();
    final match = RegExp(r'\d+').firstMatch(lower);
    final amount = int.tryParse(match?.group(0) ?? '') ?? 1;
    if (lower.contains('min')) return amount * 60;
    if (lower.contains('sec')) return amount;
    if (lower.contains('km')) return amount * 7 * 60;
    return amount * 60;
  }

  static int _restSeconds(String rest) {
    final lower = rest.toLowerCase();
    if (lower.contains('none')) return 0;
    if (lower.contains('as needed')) return 60;
    final match = RegExp(r'\d+').firstMatch(lower);
    final amount = int.tryParse(match?.group(0) ?? '') ?? 60;
    return lower.contains('min') ? amount * 60 : amount;
  }

  static int _minutes(String value) {
    final number = RegExp(r'\d+').firstMatch(value);
    return int.tryParse(number?.group(0) ?? '') ?? 45;
  }

  static String _normaliseLocation(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('home')) return 'Home';
    if (lower.contains('outside')) return 'Outside';
    return 'Gym';
  }
}

class _Slot {
  final String? pattern;
  final List<String> groups;
  const _Slot({this.pattern, this.groups = const <String>[]});
}
