import 'package:flutter_test/flutter_test.dart';

import '../lib/exercise_repository.dart';

OnlineExercise exercise(String name) => OnlineExercise(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      category: 'Strength',
      primaryMuscles: const ['Chest'],
      secondaryMuscles: const [],
      equipment: const ['Barbell'],
      difficulty: 'Beginner',
      movementPattern: 'Push',
      locations: const ['Gym'],
      instructions: const [],
      commonMistakes: const [],
      imagePath: 'https://example.com/image.jpg',
      videoPath: null,
      maleImagePath: null,
      femaleImagePath: null,
      maleVideoPath: null,
      femaleVideoPath: null,
      maleImageReviewed: false,
      femaleImageReviewed: false,
      mediaSource: 'test',
      mediaLicense: 'test',
      mediaReviewNotes: '[reference-generic]',
    );

void main() {
  group('ExerciseRepository.closestNameMatch', () {
    test('prefers the catalogue variant that starts with the programme name', () {
      final result = ExerciseRepository.closestNameMatch(
        'Barbell Bench Press',
        [
          exercise('Wide-Grip Barbell Bench Press'),
          exercise('Barbell Bench Press - Medium Grip'),
          exercise('Close-Grip Barbell Bench Press'),
        ],
      );

      expect(result?.name, 'Barbell Bench Press - Medium Grip');
    });

    test('allows a small qualifier inserted inside the same movement name', () {
      final result = ExerciseRepository.closestNameMatch(
        'Machine Shoulder Press',
        [exercise('Machine Shoulder (Military) Press')],
      );

      expect(result?.name, 'Machine Shoulder (Military) Press');
    });

    test('allows a small descriptive qualifier for cable lateral raise', () {
      final result = ExerciseRepository.closestNameMatch(
        'Cable Lateral Raise',
        [exercise('Cable Seated Lateral Raise')],
      );

      expect(result?.name, 'Cable Seated Lateral Raise');
    });

    test('does not invent a picture for an abstract warm-up block', () {
      final result = ExerciseRepository.closestNameMatch(
        'Dynamic Warm-Up',
        [
          exercise('Barbell Bench Press - Medium Grip'),
          exercise('Jumping Jack'),
          exercise('Arm Circles'),
        ],
      );

      expect(result, isNull);
    });
  });
}
