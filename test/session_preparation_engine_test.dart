import 'package:fitness_app_prototype/session_preparation_engine.dart';
import 'package:fitness_app_prototype/workout_engine.dart';
import 'package:flutter_test/flutter_test.dart';

ExercisePrescription exercise(String name, String target) {
  return ExercisePrescription(
    name: name,
    sets: 3,
    reps: '8–12',
    rest: '60 sec',
    equipment: 'Bodyweight',
    target: target,
  );
}

void main() {
  test('running sessions receive running-specific preparation and recovery', () {
    final workout = GeneratedWorkout(
      title: 'Easy Run',
      exercises: [exercise('Easy Run', 'Aerobic endurance')],
    );

    final plan = SessionPreparationEngine.forWorkout(workout);

    expect(plan.warmUp.any((step) => step.name.contains('walk')), isTrue);
    expect(plan.warmUp.any((step) => step.name.contains('Ankle')), isTrue);
    expect(plan.coolDown.any((step) => step.name.contains('Calf')), isTrue);
    expect(plan.coolDown.last.type, SessionStepType.breathing);
  });

  test('upper-body workout receives shoulder and upper-back preparation', () {
    final workout = GeneratedWorkout(
      title: 'Upper Body Strength',
      exercises: [
        exercise('Dumbbell Bench Press', 'Chest, triceps'),
        exercise('One-Arm Dumbbell Row', 'Back, biceps'),
      ],
    );

    final plan = SessionPreparationEngine.forWorkout(workout);

    expect(plan.warmUp.any((step) => step.target.contains('Shoulders')), isTrue);
    expect(plan.coolDown.any((step) => step.name.contains('Chest')), isTrue);
  });

  test('lower-body workout receives ankle hip and glute preparation', () {
    final workout = GeneratedWorkout(
      title: 'Lower Body Strength',
      exercises: [
        exercise('Goblet Squat', 'Quads, glutes'),
        exercise('Romanian Deadlift', 'Hamstrings, glutes'),
      ],
    );

    final plan = SessionPreparationEngine.forWorkout(workout);

    expect(plan.warmUp.any((step) => step.name.contains('Ankle')), isTrue);
    expect(plan.warmUp.any((step) => step.name.contains('Glute')), isTrue);
    expect(plan.coolDown.any((step) => step.name.contains('Quad')), isTrue);
  });

  test('mixed workout receives full-body preparation', () {
    final workout = GeneratedWorkout(
      title: 'Full Body Strength',
      exercises: [
        exercise('Goblet Squat', 'Quads, glutes'),
        exercise('Push-Up', 'Chest, triceps'),
      ],
    );

    final plan = SessionPreparationEngine.forWorkout(workout);

    expect(plan.warmUp.any((step) => step.name.contains('greatest')), isTrue);
    expect(plan.coolDown.any((step) => step.name.contains('Upper-body')), isTrue);
  });

  test('plans stay short enough to support rather than replace the main workout', () {
    final workout = GeneratedWorkout(
      title: 'Lower Body Strength',
      exercises: [exercise('Squat', 'Quads, glutes')],
    );

    final plan = SessionPreparationEngine.forWorkout(workout);

    expect(plan.warmUpSeconds, lessThanOrEqualTo(300));
    expect(plan.coolDownSeconds, lessThanOrEqualTo(300));
  });
}
