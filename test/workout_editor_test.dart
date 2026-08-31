import 'package:fitness_app_prototype/exercise_repository.dart';
import 'package:fitness_app_prototype/workout_editor_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a strength library exercise into a live prescription', () {
    final online = OnlineExercise(
      id: 'goblet_squat',
      name: 'Goblet Squat',
      category: 'Strength',
      primaryMuscles: const ['Quadriceps', 'Glutes'],
      secondaryMuscles: const ['Hamstrings'],
      equipment: const ['Dumbbell'],
      difficulty: 'Beginner',
      movementPattern: 'Squat',
      locations: const ['Home', 'Gym'],
      instructions: const [],
      commonMistakes: const [],
      imagePath: null,
      videoPath: null,
      maleImagePath: null,
      femaleImagePath: null,
      maleVideoPath: null,
      femaleVideoPath: null,
      maleImageReviewed: false,
      femaleImageReviewed: false,
      mediaSource: null,
      mediaLicense: null,
      mediaReviewNotes: null,
    );

    final prescription = WorkoutEditorMapper.fromOnlineExercise(online);

    expect(prescription.name, 'Goblet Squat');
    expect(prescription.sets, 3);
    expect(prescription.reps, '8–12');
    expect(prescription.rest, '75 sec');
    expect(prescription.equipment, 'Dumbbell');
    expect(prescription.target, contains('Quadriceps'));
  });

  test('maps cardio additions as a single timed block', () {
    final online = OnlineExercise(
      id: 'stationary_bike',
      name: 'Stationary Bike',
      category: 'Cardio',
      primaryMuscles: const ['Quadriceps'],
      secondaryMuscles: const ['Glutes'],
      equipment: const ['Machine'],
      difficulty: 'Beginner',
      movementPattern: 'Cardio',
      locations: const ['Gym'],
      instructions: const [],
      commonMistakes: const [],
      imagePath: null,
      videoPath: null,
      maleImagePath: null,
      femaleImagePath: null,
      maleVideoPath: null,
      femaleVideoPath: null,
      maleImageReviewed: false,
      femaleImageReviewed: false,
      mediaSource: null,
      mediaLicense: null,
      mediaReviewNotes: null,
    );

    final prescription = WorkoutEditorMapper.fromOnlineExercise(online);

    expect(prescription.sets, 1);
    expect(prescription.reps, '10 min');
    expect(prescription.metricLabel, 'TIME');
    expect(prescription.isSingleDurationBlock, isTrue);
  });
}
