import 'package:fitness_app_prototype/exercise_performance_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('set performance round-trips through local JSON format', () {
    final original = ExerciseSetPerformance(
      workoutTitle: 'Upper A',
      exerciseName: 'Dumbbell Bench Press',
      setNumber: 2,
      reps: 10,
      weightKg: 22.5,
      durationSeconds: null,
      performedAt: DateTime.parse('2026-08-31T12:00:00Z'),
    );

    final restored = ExerciseSetPerformance.fromMap(original.toJson());

    expect(restored.workoutTitle, 'Upper A');
    expect(restored.exerciseName, 'Dumbbell Bench Press');
    expect(restored.setNumber, 2);
    expect(restored.reps, 10);
    expect(restored.weightKg, 22.5);
    expect(restored.durationSeconds, isNull);
    expect(restored.performedAt.toUtc(), original.performedAt.toUtc());
    expect(restored.summary, '22.5 kg × 10 reps');
    expect(restored.volumeKg, 225);
  });

  test('progression suggestion adds a rep before load', () {
    final performance = ExerciseSetPerformance(
      exerciseName: 'Dumbbell Bench Press',
      setNumber: 1,
      reps: 10,
      weightKg: 20,
      durationSeconds: null,
      performedAt: DateTime.parse('2026-08-31T12:00:00Z'),
    );

    expect(performance.nextTargetSuggestion, contains('20 kg × 11 reps'));
  });

  test('progression suggestion increases load after twelve reps', () {
    final performance = ExerciseSetPerformance(
      exerciseName: 'Dumbbell Bench Press',
      setNumber: 1,
      reps: 12,
      weightKg: 20,
      durationSeconds: null,
      performedAt: DateTime.parse('2026-08-31T12:00:00Z'),
    );

    expect(performance.nextTargetSuggestion, contains('22.5 kg × 10 reps'));
  });

  test('timed exercise progression uses a small duration increase', () {
    final performance = ExerciseSetPerformance(
      exerciseName: 'Plank',
      setNumber: 1,
      reps: null,
      weightKg: null,
      durationSeconds: 45,
      performedAt: DateTime.parse('2026-08-31T12:00:00Z'),
    );

    expect(performance.summary, '45s');
    expect(performance.nextTargetSuggestion, contains('50s'));
  });
}
