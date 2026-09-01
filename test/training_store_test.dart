import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app_prototype/training_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves and reloads completed workouts', () async {
    final completedAt = DateTime(2026, 8, 30, 8, 0);
    await TrainingStore.saveWorkout(
      WorkoutRecord(
        title: 'Upper Body A',
        completedAt: completedAt,
        durationSeconds: 2700,
        completedSets: 18,
        exercises: const ['Dumbbell Bench Press', 'Row'],
      ),
    );

    final records = await TrainingStore.loadWorkouts();
    expect(records, hasLength(1));
    expect(records.first.title, 'Upper Body A');
    expect(records.first.completedSets, 18);
    expect(records.first.exercises, contains('Dumbbell Bench Press'));
  });

  test('updates perceived effort without duplicating workout history', () async {
    final completedAt = DateTime(2026, 8, 30, 8, 0);
    await TrainingStore.saveWorkout(
      WorkoutRecord(
        title: 'Upper Body A',
        completedAt: completedAt,
        durationSeconds: 2700,
        completedSets: 18,
        exercises: const ['Dumbbell Bench Press', 'Row'],
      ),
    );

    await TrainingStore.updateWorkoutEffort(
      completedAt: completedAt,
      effort: 'hard',
    );
    final records = await TrainingStore.loadWorkouts();

    expect(records, hasLength(1));
    expect(records.first.perceivedEffort, 'hard');
  });

  test('readiness score gives lower recommendation when recovery is poor', () async {
    final record = ReadinessRecord(
      recordedAt: DateTime(2026, 8, 30),
      sleep: 1,
      energy: 1,
      soreness: 5,
      stress: 5,
    );
    await TrainingStore.saveReadiness(record);

    final records = await TrainingStore.loadReadiness();
    expect(records, hasLength(1));
    expect(records.first.score, lessThan(40));
    expect(records.first.recommendation.toLowerCase(), contains('recovery'));
  });
}
