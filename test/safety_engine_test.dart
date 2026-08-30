import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/safety_engine.dart';
import 'package:fitness_app_prototype/workout_engine.dart';

void main() {
  test('knee limitation removes running and keeps a usable modified session', () {
    const base = GeneratedWorkout(
      title: 'Long Easy Run',
      exercises: [
        ExercisePrescription(
          name: 'Warm-Up Walk',
          sets: 1,
          reps: '8–10 min',
          rest: 'None',
          equipment: 'Running shoes',
          target: 'Warm-up',
        ),
        ExercisePrescription(
          name: 'Long Easy Run',
          sets: 1,
          reps: '30–50 min comfortable',
          rest: 'As needed',
          equipment: 'Running shoes',
          target: 'Aerobic endurance',
        ),
        ExercisePrescription(
          name: 'Brisk Walk',
          sets: 1,
          reps: '5–10 min easy',
          rest: 'None',
          equipment: 'Running shoes',
          target: 'Cool-down',
        ),
      ],
    );

    final result = SafetyEngine.adaptWorkout(
      base,
      const SafetyProfile(
        hasLimitation: true,
        affectedAreas: {'Knee'},
      ),
      location: 'Outside',
    );

    final names = result.workout.exercises.map((e) => e.name).toList();
    expect(result.status, SafetyStatus.modified);
    expect(result.blocksTraining, isFalse);
    expect(names, isNot(contains('Long Easy Run')));
    expect(names.length, greaterThanOrEqualTo(3));
    expect(result.removedExercises, contains('Long Easy Run'));
  });

  test('shoulder limitation removes pressing and pulling movements', () {
    const base = GeneratedWorkout(
      title: 'Upper Body',
      exercises: [
        ExercisePrescription(
          name: 'Dumbbell Bench Press',
          sets: 3,
          reps: '8–12',
          rest: '90 sec',
          equipment: 'Dumbbells + Bench',
          target: 'Chest, triceps',
        ),
        ExercisePrescription(
          name: 'Seated Cable Row',
          sets: 3,
          reps: '8–12',
          rest: '90 sec',
          equipment: 'Cable Machine',
          target: 'Back, biceps',
        ),
        ExercisePrescription(
          name: 'Dead Bug',
          sets: 3,
          reps: '8–12 each side',
          rest: '60 sec',
          equipment: 'Bodyweight',
          target: 'Core',
        ),
      ],
    );

    final result = SafetyEngine.adaptWorkout(
      base,
      const SafetyProfile(
        hasLimitation: true,
        affectedAreas: {'Shoulder'},
      ),
    );

    final names = result.workout.exercises.map((e) => e.name).toList();
    expect(names, isNot(contains('Dumbbell Bench Press')));
    expect(names, isNot(contains('Seated Cable Row')));
    expect(names, contains('Dead Bug'));
  });

  test('warning sign pauses app-directed training', () {
    const base = GeneratedWorkout(
      title: 'Workout',
      exercises: [
        ExercisePrescription(
          name: 'Plank',
          sets: 3,
          reps: '30 sec',
          rest: '60 sec',
          equipment: 'Bodyweight',
          target: 'Core',
        ),
      ],
    );

    final result = SafetyEngine.adaptWorkout(
      base,
      const SafetyProfile(
        hasLimitation: true,
        affectedAreas: {'Knee'},
        warningSigns: {'New numbness, tingling or unusual weakness'},
      ),
    );

    expect(result.status, SafetyStatus.medicalReview);
    expect(result.blocksTraining, isTrue);
  });

  test('no limitation leaves the workout unchanged', () {
    const base = GeneratedWorkout(
      title: 'Workout',
      exercises: [
        ExercisePrescription(
          name: 'Plank',
          sets: 3,
          reps: '30 sec',
          rest: '60 sec',
          equipment: 'Bodyweight',
          target: 'Core',
        ),
      ],
    );

    final result = SafetyEngine.adaptWorkout(
      base,
      const SafetyProfile(hasLimitation: false),
    );

    expect(result.status, SafetyStatus.normal);
    expect(result.blocksTraining, isFalse);
    expect(result.workout.exercises.single.name, 'Plank');
  });
}
