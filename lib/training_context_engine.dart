import 'dart:math' as math;

import 'workout_engine.dart';

enum TrainingContextMode {
  normal,
  notFeeling100,
  quiet,
  smallSpace,
  hotelGym,
  travel,
  outdoorsOnly,
  noEquipment,
}

extension TrainingContextModeDetails on TrainingContextMode {
  String get label => switch (this) {
        TrainingContextMode.normal => 'Normal',
        TrainingContextMode.notFeeling100 => 'Not feeling 100%',
        TrainingContextMode.quiet => 'Quiet workout',
        TrainingContextMode.smallSpace => 'Small space',
        TrainingContextMode.hotelGym => 'Hotel gym',
        TrainingContextMode.travel => 'Travel day',
        TrainingContextMode.outdoorsOnly => 'Outdoors only',
        TrainingContextMode.noEquipment => 'No equipment',
      };
}

class TrainingContextResult {
  final GeneratedWorkout workout;
  final TrainingContextMode mode;
  final String headline;
  final List<String> changes;
  final bool recoveryPreferred;

  const TrainingContextResult({
    required this.workout,
    required this.mode,
    required this.headline,
    required this.changes,
    required this.recoveryPreferred,
  });
}

class TrainingContextEngine {
  const TrainingContextEngine._();

  static TrainingContextResult adapt(
    GeneratedWorkout workout, {
    required TrainingContextMode mode,
    int? readinessScore,
  }) {
    if (mode == TrainingContextMode.normal) {
      return TrainingContextResult(
        workout: workout,
        mode: mode,
        headline: 'Use the planned session',
        changes: const ['No temporary context changes were requested.'],
        recoveryPreferred: false,
      );
    }

    final changes = <String>[];
    var recoveryPreferred = false;
    final output = <ExercisePrescription>[];
    final readiness = readinessScore?.clamp(0, 100);

    for (final exercise in workout.exercises) {
      final text = '${exercise.name} ${exercise.equipment} ${exercise.target}'.toLowerCase();
      var keep = true;
      var next = exercise;

      switch (mode) {
        case TrainingContextMode.quiet:
          if (_containsAny(text, const [
            'jump', 'burpee', 'skipping', 'high knees', 'mountain climber',
            'sprint'
          ])) {
            keep = false;
          }
          break;
        case TrainingContextMode.smallSpace:
          if (_containsAny(text, const [
            'sprint', 'farmer', 'carry', 'walking lunge', 'shuttle', 'run'
          ])) {
            keep = false;
          }
          break;
        case TrainingContextMode.hotelGym:
          if (_containsAny(text, const [
            'barbell', 'rack', 'leg press', 'cable station', 'lat pulldown'
          ])) {
            keep = false;
          }
          break;
        case TrainingContextMode.outdoorsOnly:
          if (_containsAny(text, const [
            'machine', 'cable', 'bench press', 'barbell', 'dumbbell'
          ])) {
            keep = false;
          }
          break;
        case TrainingContextMode.noEquipment:
          if (!_isBodyweightLike(text)) keep = false;
          break;
        case TrainingContextMode.travel:
          next = exercise.copyWith(
            sets: math.max(1, (exercise.sets * 0.75).round()),
            clearDropSet: true,
            clearSuperset: true,
          );
          break;
        case TrainingContextMode.notFeeling100:
          final low = readiness != null && readiness < 45;
          recoveryPreferred = low;
          next = exercise.copyWith(
            sets: math.max(1, (exercise.sets * (low ? 0.50 : 0.70)).round()),
            rest: _addRest(exercise.rest, low ? 30 : 15),
            clearDropSet: true,
            clearSuperset: low,
          );
          break;
        case TrainingContextMode.normal:
          break;
      }

      if (keep) output.add(next);
    }

    if (output.isEmpty) {
      output.addAll(_safeFallback(mode));
      changes.add('The original session could not fit today’s constraint, so LeanIt rebuilt it from low-friction movements.');
    } else if (output.length < workout.exercises.length) {
      changes.add('${workout.exercises.length - output.length} incompatible movement(s) were removed for today only.');
    }

    switch (mode) {
      case TrainingContextMode.quiet:
        changes.add('Jumping and impact-heavy movements are avoided to keep the session quiet.');
        break;
      case TrainingContextMode.smallSpace:
        changes.add('Movements requiring distance or large floor space are avoided.');
        break;
      case TrainingContextMode.hotelGym:
        changes.add('The session assumes bodyweight, dumbbells and limited hotel equipment.');
        break;
      case TrainingContextMode.travel:
        changes.add('Working-set volume is trimmed and complex intensity techniques are removed.');
        break;
      case TrainingContextMode.outdoorsOnly:
        changes.add('Indoor machine-dependent exercises are removed for this session.');
        break;
      case TrainingContextMode.noEquipment:
        changes.add('Only bodyweight or no-equipment movements remain.');
        break;
      case TrainingContextMode.notFeeling100:
        changes.add(recoveryPreferred
            ? 'Low readiness makes recovery more important than completing the original workload.'
            : 'Volume is reduced and failure-style intensity techniques are removed.');
        break;
      case TrainingContextMode.normal:
        break;
    }

    return TrainingContextResult(
      workout: GeneratedWorkout(
        title: '${workout.title} — ${mode.label}',
        exercises: List<ExercisePrescription>.unmodifiable(output),
      ),
      mode: mode,
      headline: _headline(mode, recoveryPreferred),
      changes: List<String>.unmodifiable(changes),
      recoveryPreferred: recoveryPreferred,
    );
  }

  static bool _containsAny(String text, List<String> terms) =>
      terms.any(text.contains);

  static bool _isBodyweightLike(String text) {
    return text.contains('bodyweight') ||
        text.contains('none') ||
        _containsAny(text, const [
          'push-up', 'push up', 'squat', 'lunge', 'plank', 'bridge',
          'dead bug', 'bird dog', 'calf raise', 'mobility', 'walk'
        ]);
  }

  static String _addRest(String rest, int extra) {
    final match = RegExp(r'\d+').firstMatch(rest);
    if (match == null) return rest;
    final seconds = int.tryParse(match.group(0) ?? '');
    if (seconds == null) return rest;
    return '${(seconds + extra).clamp(30, 300)} sec';
  }

  static String _headline(TrainingContextMode mode, bool recoveryPreferred) {
    if (mode == TrainingContextMode.notFeeling100 && recoveryPreferred) {
      return 'Recovery-first session';
    }
    return switch (mode) {
      TrainingContextMode.quiet => 'Quiet version ready',
      TrainingContextMode.smallSpace => 'Small-space version ready',
      TrainingContextMode.hotelGym => 'Hotel-gym version ready',
      TrainingContextMode.travel => 'Travel version ready',
      TrainingContextMode.outdoorsOnly => 'Outdoor version ready',
      TrainingContextMode.noEquipment => 'Bodyweight version ready',
      TrainingContextMode.notFeeling100 => 'Reduced-stress version ready',
      TrainingContextMode.normal => 'Use the planned session',
    };
  }

  static List<ExercisePrescription> _safeFallback(TrainingContextMode mode) {
    if (mode == TrainingContextMode.outdoorsOnly) {
      return const [
        ExercisePrescription(
          name: 'Brisk Walk',
          sets: 1,
          reps: '15–25 min comfortable',
          rest: 'As needed',
          equipment: 'None',
          target: 'Aerobic fitness',
          metricLabel: 'TARGET',
        ),
        ExercisePrescription(
          name: 'Bodyweight Squat',
          sets: 2,
          reps: '8–12',
          rest: '60 sec',
          equipment: 'Bodyweight',
          target: 'Quads, glutes',
        ),
      ];
    }
    return const [
      ExercisePrescription(
        name: 'Bodyweight Squat',
        sets: 2,
        reps: '8–12',
        rest: '75 sec',
        equipment: 'Bodyweight',
        target: 'Quads, glutes',
      ),
      ExercisePrescription(
        name: 'Glute Bridge',
        sets: 2,
        reps: '10–15',
        rest: '60 sec',
        equipment: 'Bodyweight',
        target: 'Glutes',
      ),
      ExercisePrescription(
        name: 'Dead Bug',
        sets: 2,
        reps: '8–10 each side',
        rest: '45 sec',
        equipment: 'Bodyweight',
        target: 'Core',
      ),
    ];
  }
}
