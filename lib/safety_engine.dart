import 'deload_workout_engine.dart';
import 'strength_adaptation_cache.dart';
import 'superset_engine.dart';
import 'workout_engine.dart';

enum SafetyStatus { normal, modified, medicalReview }

class SafetyProfile {
  final bool hasLimitation;
  final Set<String> affectedAreas;
  final Set<String> warningSigns;
  final String notes;

  const SafetyProfile({
    required this.hasLimitation,
    this.affectedAreas = const {},
    this.warningSigns = const {},
    this.notes = '',
  });

  bool get needsMedicalReview => warningSigns.isNotEmpty;
}

class SafetyAdaptation {
  final GeneratedWorkout workout;
  final SafetyStatus status;
  final bool blocksTraining;
  final String title;
  final String guidance;
  final List<String> removedExercises;
  final List<String> evidenceLabels;

  const SafetyAdaptation({
    required this.workout,
    required this.status,
    required this.blocksTraining,
    required this.title,
    required this.guidance,
    required this.removedExercises,
    required this.evidenceLabels,
  });
}

/// Conservative exercise modification for a fitness app.
///
/// Safety filtering always happens before fatigue/deload adaptation. LeanIt
/// never keeps a contraindicated movement merely because it is in a deload.
class SafetyEngine {
  static const Map<String, List<String>> _restrictedKeywords = {
    'Knee': [
      'run', 'sprint', 'jump', 'lunge', 'squat', 'leg press', 'step-up',
      'step up', 'burpee', 'mountain climber', 'high knees', 'skipping',
    ],
    'Ankle / Foot': [
      'run', 'sprint', 'jump', 'skipping', 'calf raise', 'burpee', 'high knees',
    ],
    'Hip': [
      'run', 'sprint', 'jump', 'deep squat', 'lunge', 'split squat',
      'hip thrust', 'heavy hinge',
    ],
    'Shoulder': [
      'shoulder press', 'overhead', 'bench press', 'chest press', 'push-up',
      'push up', 'pulldown', 'pull-up', 'pull up', 'row', 'lateral raise',
      'face pull',
    ],
    'Elbow': [
      'curl', 'triceps', 'press', 'push-up', 'push up', 'row', 'pull',
    ],
    'Wrist / Hand': [
      'push-up', 'push up', 'plank', 'dumbbell', 'barbell', 'kettlebell',
      'curl', 'row', 'press', 'carry',
    ],
    'Back': [
      'deadlift', 'good morning', 'heavy hinge', 'back extension',
      'loaded carry', 'burpee', 'jump',
    ],
    'Neck': [
      'overhead', 'shoulder press', 'shrug', 'loaded carry',
    ],
    'Other': [
      'sprint', 'jump', 'burpee', 'max effort',
    ],
  };

  static const Map<String, List<String>> _evidenceByArea = {
    'Knee': ['APTA / ChoosePT', 'NHS', 'ACSM'],
    'Ankle / Foot': ['NHS', 'ACSM'],
    'Hip': ['ACSM'],
    'Shoulder': ['ACSM'],
    'Elbow': ['ACSM'],
    'Wrist / Hand': ['ACSM'],
    'Back': ['NICE', 'ACSM'],
    'Neck': ['ACSM'],
    'Other': ['ACSM'],
  };

  static GeneratedWorkout _applyFatigue(GeneratedWorkout workout) =>
      DeloadWorkoutEngine.adapt(workout, StrengthAdaptationCache.current);

  static SafetyAdaptation adaptWorkout(
    GeneratedWorkout baseWorkout,
    SafetyProfile profile, {
    String location = 'Flexible',
  }) {
    if (profile.needsMedicalReview) {
      return SafetyAdaptation(
        workout: baseWorkout,
        status: SafetyStatus.medicalReview,
        blocksTraining: true,
        title: 'Pause training for a safety review',
        guidance:
            'Your answers include a warning sign that should not be handled by an exercise app. '
            'Do not use LeanIt to decide whether it is safe to train. Seek appropriate medical advice; '
            'urgent or emergency symptoms need urgent care.',
        removedExercises: const [],
        evidenceLabels: const ['ACSM', 'NHS'],
      );
    }

    if (!profile.hasLimitation || profile.affectedAreas.isEmpty) {
      return SafetyAdaptation(
        workout: _applyFatigue(baseWorkout),
        status: SafetyStatus.normal,
        blocksTraining: false,
        title: 'Standard training plan',
        guidance: 'No current exercise-limiting pain or injury was reported.',
        removedExercises: const [],
        evidenceLabels: const ['ACSM'],
      );
    }

    final kept = <ExercisePrescription>[];
    final removed = <String>[];

    for (final exercise in baseWorkout.exercises) {
      if (_isRestricted(exercise, profile.affectedAreas)) {
        removed.add(exercise.name);
      } else {
        kept.add(exercise);
      }
    }

    final desiredCount = baseWorkout.exercises.length < 3
        ? 3
        : baseWorkout.exercises.length;

    for (final replacement in _replacementPool(profile.affectedAreas, location)) {
      if (kept.length >= desiredCount) break;
      if (_isRestricted(replacement, profile.affectedAreas)) continue;
      if (kept.any((item) => item.name == replacement.name)) continue;
      kept.add(replacement);
    }

    if (kept.isEmpty) {
      kept.addAll([
        _p(
          'Dead Bug',
          sets: 2,
          reps: '8–10 each side',
          target: 'Core control',
        ),
        _p(
          'Breathing + Gentle Mobility',
          sets: 1,
          reps: '5–10 min comfortable',
          rest: 'As needed',
          target: 'Gentle movement',
          metricLabel: 'TARGET',
        ),
      ].where((e) => !_isRestricted(e, profile.affectedAreas)));
    }

    final areas = profile.affectedAreas.join(', ');
    final evidence = <String>{};
    for (final area in profile.affectedAreas) {
      evidence.addAll(_evidenceByArea[area] ?? const ['ACSM']);
    }

    final safetyWorkout = GeneratedWorkout(
      title: '${baseWorkout.title} — Modified',
      exercises: SupersetEngine.normalize(kept),
    );

    return SafetyAdaptation(
      workout: _applyFatigue(safetyWorkout),
      status: SafetyStatus.modified,
      blocksTraining: false,
      title: 'Modified for: $areas',
      guidance:
          removed.isEmpty
              ? 'No clearly conflicting movement was found in this session. Keep every movement comfortable and stop if symptoms increase.'
              : 'LeanIt removed ${removed.join(', ')} because those movements may load the area you reported. '
                    'The replacements are conservative training options, not treatment for a diagnosed injury. '
                    'Use a comfortable range and stop if symptoms increase.',
      removedExercises: removed,
      evidenceLabels: evidence.toList(growable: false),
    );
  }

  static bool exerciseAllowed(
    ExercisePrescription exercise,
    SafetyProfile profile,
  ) {
    if (profile.needsMedicalReview) return false;
    if (!profile.hasLimitation) return true;
    return !_isRestricted(exercise, profile.affectedAreas);
  }

  static bool exerciseNameAllowed(
    String name,
    SafetyProfile profile, {
    String target = '',
    String equipment = '',
  }) {
    return exerciseAllowed(
      _p(name, target: target, equipment: equipment),
      profile,
    );
  }

  static bool _isRestricted(
    ExercisePrescription exercise,
    Set<String> affectedAreas,
  ) {
    final text = '${exercise.name} ${exercise.target} ${exercise.equipment}'
        .toLowerCase();

    for (final area in affectedAreas) {
      final keywords = _restrictedKeywords[area] ?? const <String>[];
      for (final keyword in keywords) {
        if (text.contains(keyword)) return true;
      }
    }
    return false;
  }

  static List<ExercisePrescription> _replacementPool(
    Set<String> affectedAreas,
    String location,
  ) {
    final result = <ExercisePrescription>[];

    if (affectedAreas.contains('Knee')) {
      result.addAll([
        _p(
          'Clamshell',
          sets: 2,
          reps: '10–15 each side',
          rest: '45 sec',
          target: 'Glutes, hip control',
        ),
        _p(
          'Side-Lying Hip Abduction',
          sets: 2,
          reps: '10–15 each side',
          rest: '45 sec',
          target: 'Glutes, hip control',
        ),
        _p(
          'Straight Leg Raise',
          sets: 2,
          reps: '10–15 each side',
          rest: '45 sec',
          target: 'Quadriceps control',
        ),
        _p(
          'Short Arc Quad',
          sets: 2,
          reps: '10–15 each side',
          rest: '45 sec',
          target: 'Quadriceps control',
        ),
        _p('Glute Bridge', reps: '10–15', target: 'Glutes'),
        _p('Dead Bug', reps: '8–12 each side', target: 'Core'),
      ]);
    }

    if (affectedAreas.contains('Shoulder') ||
        affectedAreas.contains('Elbow') ||
        affectedAreas.contains('Wrist / Hand')) {
      result.addAll([
        _p('Glute Bridge', reps: '10–15', target: 'Glutes'),
        _p('Dead Bug', reps: '8–12 each side', target: 'Core'),
        _p('Standing Calf Raise', reps: '12–20', target: 'Calves'),
        _p(
          'Brisk Walk',
          sets: 1,
          reps: '10–20 min comfortable',
          rest: 'As needed',
          target: 'Aerobic fitness',
          metricLabel: 'TARGET',
        ),
      ]);
    }

    if (affectedAreas.contains('Back') || affectedAreas.contains('Neck')) {
      result.addAll([
        _p(
          'Easy Walk',
          sets: 1,
          reps: '10–20 min comfortable',
          rest: 'As needed',
          target: 'Gentle aerobic activity',
          metricLabel: 'TARGET',
        ),
        _p(
          'Gentle Mobility Flow',
          sets: 1,
          reps: '5–10 min comfortable',
          rest: 'As needed',
          target: 'Mobility',
          metricLabel: 'TARGET',
        ),
        _p(
          'Dead Bug',
          sets: 2,
          reps: '6–10 each side',
          target: 'Core control',
        ),
      ]);
    }

    if (affectedAreas.contains('Hip') ||
        affectedAreas.contains('Ankle / Foot')) {
      result.addAll([
        _p('Dead Bug', reps: '8–12 each side', target: 'Core'),
        _p('Bird Dog', reps: '8–12 each side', target: 'Core, back'),
        _p('Push-Up', reps: '8–15', target: 'Chest, triceps'),
        _p(
          'Seated Dumbbell Curl',
          reps: '10–15',
          equipment: 'Dumbbells',
          target: 'Biceps',
        ),
      ]);
    }

    if (affectedAreas.contains('Other')) {
      result.addAll([
        _p('Dead Bug', sets: 2, reps: '8–10 each side', target: 'Core'),
        _p(
          'Gentle Mobility Flow',
          sets: 1,
          reps: '5–10 min comfortable',
          rest: 'As needed',
          target: 'Mobility',
          metricLabel: 'TARGET',
        ),
      ]);
    }

    result.addAll([
      _p('Dead Bug', reps: '8–12 each side', target: 'Core'),
      _p('Bird Dog', reps: '8–12 each side', target: 'Core, back'),
      _p('Glute Bridge', reps: '10–15', target: 'Glutes'),
    ]);

    return result;
  }

  static ExercisePrescription _p(
    String name, {
    int sets = 3,
    String reps = '8–12',
    String rest = '60 sec',
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
      metricLabel: metricLabel,
    );
  }
}
