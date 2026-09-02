import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/training_context_engine.dart';
import 'package:fitness_app_prototype/workout_engine.dart';

GeneratedWorkout workout() => const GeneratedWorkout(
      title: 'Test Session',
      exercises: [
        ExercisePrescription(
          name: 'Jump Squat',
          sets: 4,
          reps: '8',
          rest: '60 sec',
          equipment: 'Bodyweight',
          target: 'Quads, glutes',
        ),
        ExercisePrescription(
          name: 'Dumbbell Bench Press',
          sets: 4,
          reps: '10',
          rest: '75 sec',
          equipment: 'Dumbbells, Bench',
          target: 'Chest, triceps',
          supersetId: 'A',
        ),
        ExercisePrescription(
          name: 'Goblet Squat',
          sets: 4,
          reps: '10',
          rest: '75 sec',
          equipment: 'Dumbbell',
          target: 'Quads, glutes',
          dropSetCount: 1,
        ),
      ],
    );

void main() {
  test('quiet mode removes impact-heavy movements', () {
    final result = TrainingContextEngine.adapt(
      workout(),
      mode: TrainingContextMode.quiet,
    );
    expect(
      result.workout.exercises.any(
        (item) => item.name.toLowerCase().contains('jump'),
      ),
      isFalse,
    );
  });

  test('no-equipment mode removes dumbbell-dependent movements', () {
    final result = TrainingContextEngine.adapt(
      workout(),
      mode: TrainingContextMode.noEquipment,
    );
    expect(
      result.workout.exercises.any(
        (item) => item.equipment.toLowerCase().contains('dumbbell'),
      ),
      isFalse,
    );
  });

  test('travel mode trims sets and removes intensity techniques', () {
    final result = TrainingContextEngine.adapt(
      workout(),
      mode: TrainingContextMode.travel,
    );
    expect(result.workout.exercises.first.sets, lessThan(4));
    expect(
      result.workout.exercises.every((item) => item.dropSetCount == 0),
      isTrue,
    );
    expect(
      result.workout.exercises.every((item) => item.supersetId == null),
      isTrue,
    );
  });

  test('not feeling 100 with low readiness becomes recovery first', () {
    final result = TrainingContextEngine.adapt(
      workout(),
      mode: TrainingContextMode.notFeeling100,
      readinessScore: 35,
    );
    expect(result.recoveryPreferred, isTrue);
    expect(result.workout.exercises.first.sets, lessThanOrEqualTo(2));
  });
}
