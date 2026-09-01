import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_app_prototype/short_on_time_engine.dart';
import 'package:fitness_app_prototype/workout_engine.dart';

ExercisePrescription e(
  String name, {
  int sets = 3,
  String reps = '8–12',
  String rest = '75 sec',
  String target = 'Chest',
  String equipment = 'Dumbbells',
  String? supersetId,
}) {
  return ExercisePrescription(
    name: name,
    sets: sets,
    reps: reps,
    rest: rest,
    equipment: equipment,
    target: target,
    supersetId: supersetId,
  );
}

void main() {
  group('ShortOnTimeEngine', () {
    test('trims accessories before the current compound movement', () {
      final exercises = [
        e('Barbell Bench Press', sets: 4, equipment: 'Barbell, Bench'),
        e('Incline Dumbbell Press', sets: 3),
        e('Machine Shoulder Press', sets: 3, target: 'Shoulders'),
        e('Cable Lateral Raise', sets: 3, target: 'Shoulders', equipment: 'Cable'),
        e('Triceps Pushdown', sets: 3, target: 'Triceps', equipment: 'Cable'),
      ];

      final plan = ShortOnTimeEngine.adapt(
        exercises: exercises,
        completedSets: [1, 0, 0, 0, 0],
        currentIndex: 0,
        minutesRemaining: 12,
      );

      final bench = plan.exercises.firstWhere((x) => x.name == 'Barbell Bench Press');
      expect(bench.sets, greaterThanOrEqualTo(2));
      expect(plan.changed, isTrue);
      expect(
        plan.removedExercises.contains('Triceps Pushdown') ||
            plan.removedExercises.contains('Cable Lateral Raise') ||
            plan.reducedExercises.contains('Triceps Pushdown') ||
            plan.reducedExercises.contains('Cable Lateral Raise'),
        isTrue,
      );
    });

    test('never removes work that has already been completed', () {
      final exercises = [
        e('Barbell Bench Press'),
        e('Dumbbell Row', target: 'Back'),
        e('Biceps Curl', target: 'Biceps'),
      ];

      final plan = ShortOnTimeEngine.adapt(
        exercises: exercises,
        completedSets: [3, 2, 0],
        currentIndex: 1,
        minutesRemaining: 5,
      );

      final benchIndex = plan.exercises.indexWhere((x) => x.name == 'Barbell Bench Press');
      final rowIndex = plan.exercises.indexWhere((x) => x.name == 'Dumbbell Row');
      expect(benchIndex, isNonNegative);
      expect(rowIndex, isNonNegative);
      expect(plan.completedSets[benchIndex], 3);
      expect(plan.completedSets[rowIndex], 2);
      expect(plan.exercises[rowIndex].sets, greaterThanOrEqualTo(2));
    });

    test('keeps the active exercise with at least one remaining set', () {
      final exercises = [
        e('Leg Press', sets: 4, target: 'Quadriceps', equipment: 'Leg Press Machine'),
        e('Leg Extension', target: 'Quadriceps', equipment: 'Machine'),
        e('Calf Raise', target: 'Calves', equipment: 'Machine'),
      ];

      final plan = ShortOnTimeEngine.adapt(
        exercises: exercises,
        completedSets: [1, 0, 0],
        currentIndex: 0,
        minutesRemaining: 5,
      );

      final legPressIndex = plan.exercises.indexWhere((x) => x.name == 'Leg Press');
      expect(legPressIndex, isNonNegative);
      expect(plan.exercises[legPressIndex].sets, greaterThan(plan.completedSets[legPressIndex]));
    });

    test('reduces a superset as a pair instead of breaking one member', () {
      final exercises = [
        e('Dumbbell Bench Press'),
        e('Biceps Curl', supersetId: 'ss1', target: 'Biceps'),
        e('Triceps Pushdown', supersetId: 'ss1', target: 'Triceps', equipment: 'Cable'),
        e('Lateral Raise', target: 'Shoulders'),
      ];

      final plan = ShortOnTimeEngine.adapt(
        exercises: exercises,
        completedSets: [3, 0, 0, 0],
        currentIndex: 1,
        minutesRemaining: 7,
      );

      final a = plan.exercises.indexWhere((x) => x.name == 'Biceps Curl');
      final b = plan.exercises.indexWhere((x) => x.name == 'Triceps Pushdown');
      expect(a, isNonNegative);
      expect(b, isNonNegative);
      expect(plan.exercises[a].sets, plan.exercises[b].sets);
      expect(plan.exercises[a].supersetId, plan.exercises[b].supersetId);
    });

    test('does not expand a session when there is already enough time', () {
      final exercises = [
        e('Goblet Squat', sets: 2, target: 'Legs'),
        e('Dumbbell Row', sets: 2, target: 'Back'),
      ];

      final plan = ShortOnTimeEngine.adapt(
        exercises: exercises,
        completedSets: [0, 0],
        currentIndex: 0,
        minutesRemaining: 30,
      );

      expect(plan.exercises.length, 2);
      expect(plan.exercises[0].sets, 2);
      expect(plan.exercises[1].sets, 2);
      expect(plan.removedExercises, isEmpty);
    });
  });
}
