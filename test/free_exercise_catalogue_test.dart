import 'package:fitness_app_prototype/exercise_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps free-exercise-db records into LeanIt exercises', () {
    final exercise = OnlineExercise.fromFreeExerciseDb({
      'id': 'Barbell_Bench_Press_-_Medium_Grip',
      'name': 'Barbell Bench Press - Medium Grip',
      'force': 'push',
      'level': 'beginner',
      'mechanic': 'compound',
      'equipment': 'barbell',
      'primaryMuscles': ['chest'],
      'secondaryMuscles': ['shoulders', 'triceps'],
      'instructions': ['Lie on the bench.', 'Press the bar upward.'],
      'category': 'strength',
      'images': ['Barbell_Bench_Press_-_Medium_Grip/0.jpg'],
    });

    expect(exercise.id, 'barbell_bench_press_medium_grip');
    expect(exercise.name, 'Barbell Bench Press - Medium Grip');
    expect(exercise.category, 'Strength');
    expect(exercise.difficulty, 'Beginner');
    expect(exercise.primaryMuscles, ['Chest']);
    expect(exercise.secondaryMuscles, ['Shoulders', 'Triceps']);
    expect(exercise.equipment, ['Barbell']);
    expect(exercise.locations, ['Gym']);
    expect(exercise.movementPattern, 'Push • Compound');
    expect(exercise.instructions, hasLength(2));
    expect(exercise.mediaSource, 'yuhonas/free-exercise-db');
    expect(exercise.mediaLicense, contains('Unlicense'));
    expect(exercise.hasReferenceGenericImage, isTrue);
    expect(exercise.hasApprovedGenericImage, isFalse);
    expect(exercise.imagePath, contains('raw.githubusercontent.com'));
  });

  test('body-only free exercises are available at home, gym and outside', () {
    final exercise = OnlineExercise.fromFreeExerciseDb({
      'name': 'Pushups',
      'force': 'push',
      'level': 'beginner',
      'mechanic': 'compound',
      'equipment': 'body only',
      'primaryMuscles': ['chest'],
      'secondaryMuscles': ['triceps'],
      'instructions': ['Keep the body controlled.'],
      'category': 'strength',
      'images': ['Pushups/0.jpg'],
    });

    expect(exercise.equipment, ['Bodyweight']);
    expect(exercise.locations, ['Home', 'Gym', 'Outside']);
  });
}
