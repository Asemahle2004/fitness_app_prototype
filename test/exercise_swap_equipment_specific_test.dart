import 'package:fitness_app_prototype/exercise_repository.dart';
import 'package:fitness_app_prototype/exercise_swap_service.dart';
import 'package:fitness_app_prototype/workout_engine.dart';
import 'package:flutter_test/flutter_test.dart';

OnlineExercise _candidate(String name, String equipment) {
  return OnlineExercise.fromFreeExerciseDb({
    'name': name,
    'force': 'push',
    'level': 'beginner',
    'mechanic': 'compound',
    'equipment': equipment,
    'primaryMuscles': ['chest'],
    'secondaryMuscles': ['triceps'],
    'instructions': ['Controlled movement.'],
    'category': 'strength',
    'images': ['Example/0.jpg'],
  });
}

void main() {
  const current = ExercisePrescription(
    name: 'Dumbbell Bench Press',
    sets: 3,
    reps: '8–12',
    rest: '75 sec',
    equipment: 'Dumbbells + Bench',
    target: 'Chest, triceps',
  );

  test('specific bench outage can keep dumbbells when candidate avoids bench', () {
    final floorPress = _candidate('Dumbbell Floor Press', 'dumbbell');
    expect(
      ExerciseSwapRanker.isSuitableCandidate(
        current: current,
        candidate: floorPress,
        reason: ExerciseSwapReason.equipmentUnavailable,
        unavailableEquipment: {'bench'},
      ),
      isTrue,
    );
  });

  test('specific bench outage rejects another bench exercise', () {
    final benchPress = _candidate('Dumbbell Bench Press Neutral Grip', 'dumbbell');
    // The source metadata can omit a bench, so the candidate name also matters.
    final withBenchName = _candidate('Dumbbell Bench Press', 'dumbbell');
    expect(
      ExerciseSwapRanker.isSuitableCandidate(
        current: current,
        candidate: benchPress,
        reason: ExerciseSwapReason.equipmentUnavailable,
        unavailableEquipment: {'bench'},
      ),
      isFalse,
    );
    expect(
      ExerciseSwapRanker.isSuitableCandidate(
        current: current,
        candidate: withBenchName,
        reason: ExerciseSwapReason.equipmentUnavailable,
        unavailableEquipment: {'bench'},
      ),
      isFalse,
    );
  });
}
