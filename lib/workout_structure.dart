import 'workout_engine.dart';

/// Adds the session pieces that make a generated exercise list feel like a
/// complete workout rather than only the main working sets.
class WorkoutStructureEnhancer {
  static GeneratedWorkout enhance(
    GeneratedWorkout base, {
    required String sessionDuration,
    required String location,
  }) {
    if (base.exercises.isEmpty || _alreadyStructured(base.title)) return base;

    final minutes = _minutes(sessionDuration);
    if (minutes <= 15) return base;

    final result = <ExercisePrescription>[];
    result.add(_warmUp(location, minutes));
    result.addAll(base.exercises);

    if (minutes >= 45) {
      result.add(_coolDown(location));
    }

    return GeneratedWorkout(title: base.title, exercises: result);
  }

  static bool _alreadyStructured(String title) {
    final value = title.toLowerCase();
    return value.contains('run') ||
        value.contains('cardio') ||
        value.contains('mobility') ||
        value.contains('conditioning');
  }

  static int _minutes(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    if (match == null) return 60;
    return int.tryParse(match.group(0) ?? '') ?? 60;
  }

  static ExercisePrescription _warmUp(String location, int minutes) {
    final duration = minutes >= 60 ? '7 min' : '5 min';
    return ExercisePrescription(
      name: location == 'Outside' ? 'Warm-Up Walk' : 'Dynamic Warm-Up',
      sets: 1,
      reps: duration,
      rest: 'None',
      equipment: location == 'Outside' ? 'None' : 'Bodyweight',
      target: 'Warm-up, mobility, gradual heart-rate increase',
      metricLabel: 'TIME',
    );
  }

  static ExercisePrescription _coolDown(String location) {
    return ExercisePrescription(
      name: location == 'Outside' ? 'Easy Walk' : 'Gentle Mobility Flow',
      sets: 1,
      reps: '5 min',
      rest: 'None',
      equipment: 'Bodyweight',
      target: 'Cool-down and easy movement',
      metricLabel: 'TIME',
    );
  }
}
