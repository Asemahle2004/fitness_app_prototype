import 'package:fitness_app_prototype/exercise_repository.dart';
import 'package:flutter_test/flutter_test.dart';

OnlineExercise exercise({
  String? malePath,
  String? femalePath,
  bool maleReviewed = false,
  bool femaleReviewed = false,
}) {
  return OnlineExercise(
    id: 'test',
    name: 'Test Exercise',
    category: 'Test',
    primaryMuscles: const [],
    secondaryMuscles: const [],
    equipment: const [],
    difficulty: 'Beginner',
    movementPattern: 'Test',
    locations: const ['Home'],
    instructions: const [],
    commonMistakes: const [],
    imagePath: null,
    videoPath: null,
    maleImagePath: malePath,
    femaleImagePath: femalePath,
    maleVideoPath: null,
    femaleVideoPath: null,
    maleImageReviewed: maleReviewed,
    femaleImageReviewed: femaleReviewed,
    mediaSource: null,
    mediaLicense: null,
    mediaReviewNotes: null,
  );
}

void main() {
  test('unreviewed photos are never selected for production display', () {
    final item = exercise(
      malePath: 'test/male.webp',
      femalePath: 'test/female.webp',
    );

    expect(item.reviewedImageForSex('Male'), isNull);
    expect(item.reviewedImageForSex('Female'), isNull);
    expect(item.hasCompleteReviewedImagePair, isFalse);
  });

  test('gender-matched reviewed image is preferred', () {
    final item = exercise(
      malePath: 'test/male.webp',
      femalePath: 'test/female.webp',
      maleReviewed: true,
      femaleReviewed: true,
    );

    expect(item.reviewedImageForSex('Male'), 'test/male.webp');
    expect(item.reviewedImageForSex('Female'), 'test/female.webp');
    expect(item.hasCompleteReviewedImagePair, isTrue);
  });

  test('reviewed opposite-sex image can be a fallback when preferred one is absent', () {
    final item = exercise(
      malePath: 'test/male.webp',
      maleReviewed: true,
    );

    expect(item.reviewedImageForSex('Female'), 'test/male.webp');
  });
}
