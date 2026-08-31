import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_app_prototype/custom_workout_store.dart';
import 'package:fitness_app_prototype/exercise_performance_store.dart';
import 'package:fitness_app_prototype/workout_engine.dart';

void main() {
  test('custom workout JSON preserves drop set settings', () {
    final now = DateTime.utc(2026, 8, 31, 19);
    final workout = CustomWorkout(
      id: 'drop-day',
      name: 'Drop Day',
      createdAt: now,
      updatedAt: now,
      exercises: const [
        ExercisePrescription(
          name: 'Dumbbell Bench Press',
          sets: 3,
          reps: '8–12',
          rest: '90 sec',
          equipment: 'Dumbbells + Bench',
          target: 'Chest, triceps',
          dropSetCount: 2,
          dropSetReductionPercent: 20,
        ),
      ],
    );

    final restored = CustomWorkout.fromJson(workout.toJson());
    expect(restored.exercises.single.dropSetCount, 2);
    expect(restored.exercises.single.dropSetReductionPercent, 20);
  });

  test('drop set performance record keeps its local metadata', () {
    final record = ExerciseSetPerformance(
      exerciseName: 'Cable Curl',
      setNumber: 3,
      reps: 10,
      weightKg: 15,
      durationSeconds: null,
      setType: 'drop',
      dropNumber: 2,
      performedAt: DateTime.utc(2026, 8, 31, 19, 30),
    );

    final restored = ExerciseSetPerformance.fromMap(record.toJson());
    expect(restored.isDropSet, isTrue);
    expect(restored.dropNumber, 2);
    expect(restored.setLabel, 'Drop 2');
    expect(restored.summary, '15 kg × 10 reps');
    expect(restored.nextTargetSuggestion, isNull);
  });
}
