import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/workout_engine.dart';
import 'package:fitness_app_prototype/workout_structure.dart';

void main() {
  test('60 minute strength session gets warm-up and cool-down', () {
    const base = GeneratedWorkout(
      title: 'Upper Body A',
      exercises: [
        ExercisePrescription(name: 'Dumbbell Bench Press', sets: 3, reps: '8–12', rest: '75 sec', equipment: 'Dumbbells + Bench', target: 'Chest'),
        ExercisePrescription(name: 'One-Arm Dumbbell Row', sets: 3, reps: '8–12', rest: '75 sec', equipment: 'Dumbbell + Bench', target: 'Back'),
        ExercisePrescription(name: 'Dumbbell Shoulder Press', sets: 3, reps: '8–12', rest: '75 sec', equipment: 'Dumbbells', target: 'Shoulders'),
        ExercisePrescription(name: 'Dumbbell Curl', sets: 3, reps: '10–15', rest: '60 sec', equipment: 'Dumbbells', target: 'Biceps'),
        ExercisePrescription(name: 'Triceps Pushdown', sets: 3, reps: '10–15', rest: '60 sec', equipment: 'Cable', target: 'Triceps'),
        ExercisePrescription(name: 'Lateral Raise', sets: 3, reps: '12–15', rest: '60 sec', equipment: 'Dumbbells', target: 'Shoulders'),
      ],
    );

    final result = WorkoutStructureEnhancer.enhance(
      base,
      sessionDuration: '60 min',
      location: 'Gym',
    );

    expect(result.exercises.length, 8);
    expect(result.exercises.first.name, 'Dynamic Warm-Up');
    expect(result.exercises.last.name, 'Gentle Mobility Flow');
  });

  test('running session is not padded with duplicate structure', () {
    const base = GeneratedWorkout(
      title: 'Long Easy Run',
      exercises: [
        ExercisePrescription(name: 'Warm-Up Walk', sets: 1, reps: '8 min', rest: 'None', equipment: 'None', target: 'Warm-up'),
        ExercisePrescription(name: 'Long Easy Run', sets: 1, reps: '40 min', rest: 'As needed', equipment: 'Running shoes', target: 'Aerobic endurance'),
        ExercisePrescription(name: 'Easy Walk', sets: 1, reps: '5 min', rest: 'None', equipment: 'None', target: 'Cool-down'),
      ],
    );

    final result = WorkoutStructureEnhancer.enhance(
      base,
      sessionDuration: '60 min',
      location: 'Outside',
    );

    expect(result.exercises.length, 3);
  });
}
