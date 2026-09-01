import 'package:fitness_app_prototype/exercise_repository.dart';
import 'package:fitness_app_prototype/exercise_swap_service.dart';
import 'package:fitness_app_prototype/workout_engine.dart';
import 'package:flutter_test/flutter_test.dart';

OnlineExercise _candidate({
  required String name,
  required String equipment,
  required List<String> primaryMuscles,
  String level = 'beginner',
  String force = 'push',
  String mechanic = 'compound',
}) {
  return OnlineExercise.fromFreeExerciseDb({
    'name': name,
    'force': force,
    'level': level,
    'mechanic': mechanic,
    'equipment': equipment,
    'primaryMuscles': primaryMuscles,
    'secondaryMuscles': <String>[],
    'instructions': <String>['Controlled movement.'],
    'category': 'strength',
    'images': <String>['Example/0.jpg'],
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

  test('same-target replacement ranks above unrelated exercise', () {
    final press = _candidate(
      name: 'Pushups',
      equipment: 'body only',
      primaryMuscles: ['chest'],
    );
    final curl = _candidate(
      name: 'Dumbbell Curl',
      equipment: 'dumbbell',
      primaryMuscles: ['biceps'],
      force: 'pull',
      mechanic: 'isolation',
    );

    final pressScore = ExerciseSwapRanker.score(
      current: current,
      candidate: press,
      reason: ExerciseSwapReason.variation,
    );
    final curlScore = ExerciseSwapRanker.score(
      current: current,
      candidate: curl,
      reason: ExerciseSwapReason.variation,
    );

    expect(pressScore.score, greaterThan(curlScore.score));
    expect(pressScore.reasons, contains('same target area'));
  });

  test('equipment unavailable gives bodyweight alternative a strong boost', () {
    final bodyweight = _candidate(
      name: 'Pushups',
      equipment: 'body only',
      primaryMuscles: ['chest'],
    );
    final dumbbell = _candidate(
      name: 'Dumbbell Floor Press',
      equipment: 'dumbbell',
      primaryMuscles: ['chest'],
    );

    final bodyweightScore = ExerciseSwapRanker.score(
      current: current,
      candidate: bodyweight,
      reason: ExerciseSwapReason.equipmentUnavailable,
    );
    final dumbbellScore = ExerciseSwapRanker.score(
      current: current,
      candidate: dumbbell,
      reason: ExerciseSwapReason.equipmentUnavailable,
    );

    expect(bodyweightScore.score, greaterThan(dumbbellScore.score));
    expect(bodyweightScore.reasons, contains('no equipment needed'));
  });

  test('equipment-unavailable filter rejects the same unavailable setup', () {
    final dumbbellFloorPress = _candidate(
      name: 'Dumbbell Floor Press',
      equipment: 'dumbbell',
      primaryMuscles: ['chest'],
    );
    final machinePress = _candidate(
      name: 'Machine Chest Press',
      equipment: 'machine',
      primaryMuscles: ['chest'],
    );

    expect(
      ExerciseSwapRanker.isSuitableCandidate(
        current: current,
        candidate: dumbbellFloorPress,
        reason: ExerciseSwapReason.equipmentUnavailable,
      ),
      isFalse,
    );
    expect(
      ExerciseSwapRanker.isSuitableCandidate(
        current: current,
        candidate: machinePress,
        reason: ExerciseSwapReason.equipmentUnavailable,
      ),
      isTrue,
    );
  });

  test('replacement must preserve the primary programme target', () {
    final reverseFly = _candidate(
      name: 'Reverse Fly',
      equipment: 'body only',
      primaryMuscles: ['shoulders'],
      force: 'pull',
      mechanic: 'isolation',
    );

    expect(
      ExerciseSwapRanker.isSuitableCandidate(
        current: current,
        candidate: reverseFly,
        reason: ExerciseSwapReason.equipmentUnavailable,
      ),
      isFalse,
    );
  });

  test('too difficult prefers beginner candidate over expert candidate', () {
    final beginner = _candidate(
      name: 'Pushups',
      equipment: 'body only',
      primaryMuscles: ['chest'],
      level: 'beginner',
    );
    final expert = _candidate(
      name: 'Advanced Chest Press',
      equipment: 'machine',
      primaryMuscles: ['chest'],
      level: 'expert',
    );

    final beginnerScore = ExerciseSwapRanker.score(
      current: current,
      candidate: beginner,
      reason: ExerciseSwapReason.tooDifficult,
    );
    final expertScore = ExerciseSwapRanker.score(
      current: current,
      candidate: expert,
      reason: ExerciseSwapReason.tooDifficult,
    );

    expect(beginnerScore.score, greaterThan(expertScore.score));
    expect(beginnerScore.reasons, contains('beginner-friendly'));
  });
}
