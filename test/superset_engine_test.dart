import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/custom_workout_store.dart';
import 'package:fitness_app_prototype/superset_engine.dart';
import 'package:fitness_app_prototype/workout_engine.dart';

ExercisePrescription exercise(String name, {int sets = 3}) {
  return ExercisePrescription(
    name: name,
    sets: sets,
    reps: '8–12',
    rest: '75 sec',
    equipment: 'Dumbbells',
    target: 'Strength',
  );
}

void main() {
  test('pairWithNext creates an adjacent A/B superset', () {
    final paired = SupersetEngine.pairWithNext(
      [exercise('Bench Press'), exercise('Row'), exercise('Squat')],
      0,
      groupId: 'ss_test',
    );

    expect(paired[0].supersetId, 'ss_test');
    expect(paired[1].supersetId, 'ss_test');
    expect(paired[2].supersetId, isNull);
    expect(SupersetEngine.positionLabel(paired, 0), 'A');
    expect(SupersetEngine.positionLabel(paired, 1), 'B');
    expect(SupersetEngine.partnerName(paired, 0), 'Row');
  });

  test('normalize breaks a pair when members are no longer adjacent', () {
    final broken = [
      exercise('Bench Press').copyWith(supersetId: 'ss_test'),
      exercise('Squat'),
      exercise('Row').copyWith(supersetId: 'ss_test'),
    ];

    final normalized = SupersetEngine.normalize(broken);
    expect(normalized[0].supersetId, isNull);
    expect(normalized[2].supersetId, isNull);
  });

  test('superset sequencing alternates A then B before rest', () {
    final paired = SupersetEngine.pairWithNext(
      [exercise('Bench Press'), exercise('Row')],
      0,
      groupId: 'ss_test',
    );
    final completed = [1, 0];

    expect(
      SupersetEngine.immediateNextAfterSet(
        exercises: paired,
        completedSets: completed,
        currentIndex: 0,
      ),
      1,
    );

    completed[1] = 1;
    expect(
      SupersetEngine.nextRoundMember(
        exercises: paired,
        completedSets: completed,
        currentIndex: 1,
      ),
      0,
    );
  });

  test('unequal set counts gracefully finish the remaining member', () {
    final paired = SupersetEngine.pairWithNext(
      [exercise('Bench Press', sets: 2), exercise('Row', sets: 3)],
      0,
      groupId: 'ss_test',
    );
    final completed = [2, 2];

    expect(
      SupersetEngine.nextRoundMember(
        exercises: paired,
        completedSets: completed,
        currentIndex: 1,
      ),
      1,
    );
  });

  test('custom workout serialization preserves superset IDs', () {
    final paired = SupersetEngine.pairWithNext(
      [exercise('Bench Press'), exercise('Row')],
      0,
      groupId: 'ss_saved',
    );
    final now = DateTime(2026, 8, 31, 19);
    final workout = CustomWorkout(
      id: 'workout-1',
      name: 'Push Pull Superset',
      createdAt: now,
      updatedAt: now,
      exercises: paired,
    );

    final restored = CustomWorkout.fromJson(workout.toJson());
    expect(restored.exercises[0].supersetId, 'ss_saved');
    expect(restored.exercises[1].supersetId, 'ss_saved');
  });
}
