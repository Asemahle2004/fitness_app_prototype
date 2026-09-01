import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_app_prototype/exercise_preference_ranking.dart';
import 'package:fitness_app_prototype/exercise_preference_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('records repeated dislikes as a strong avoid signal', () async {
    const store = ExercisePreferenceStore(userScope: 'tester');

    await store.recordDislike('Bulgarian Split Squat');
    await store.recordDislike('Bulgarian Split Squat');

    final record = (await store.load()).forExercise('bulgarian   split squat');
    expect(record, isNotNull);
    expect(record!.dislikeCount, 2);
    expect(record.stronglyAvoided, isTrue);
    expect(record.score, lessThanOrEqualTo(-45));
  });

  test('selected alternatives become preferred over time', () async {
    const store = ExercisePreferenceStore(userScope: 'tester');

    await store.recordSelectedAlternative('Lat Pulldown');
    await store.recordSelectedAlternative('Lat Pulldown');

    final record = (await store.load()).forExercise('Lat Pulldown');
    expect(record, isNotNull);
    expect(record!.selectedAlternativeCount, 2);
    expect(record.preferred, isTrue);
    expect(record.score, 16);
  });

  test('rejected suggestions are remembered independently', () async {
    const store = ExercisePreferenceStore(userScope: 'tester');

    await store.recordRejectedSuggestion('Pike Push-Up');
    final record = (await store.load()).forExercise('Pike Push-Up');

    expect(record, isNotNull);
    expect(record!.rejectedSuggestionCount, 1);
    expect(record.dislikeCount, 0);
    expect(record.score, -10);
  });

  test('favourite and positive history increase ranking', () {
    const record = ExercisePreferenceRecord(
      exerciseName: 'Cable Row',
      score: 16,
      dislikeCount: 0,
      rejectedSuggestionCount: 0,
      selectedAlternativeCount: 2,
    );

    final adjustment = ExercisePreferenceRanking.adjustment(
      record: record,
      favorite: true,
    );

    expect(adjustment.scoreDelta, greaterThan(20));
    expect(adjustment.reasons, contains('one of your favourites'));
    expect(adjustment.reasons, contains('matches your past choices'));
  });

  test('strongly avoided exercises get a substantial ranking penalty', () {
    const record = ExercisePreferenceRecord(
      exerciseName: 'Bulgarian Split Squat',
      score: -56,
      dislikeCount: 2,
      rejectedSuggestionCount: 0,
      selectedAlternativeCount: 0,
    );

    final adjustment = ExercisePreferenceRanking.adjustment(record: record);

    expect(adjustment.scoreDelta, lessThanOrEqualTo(-40));
    expect(adjustment.reasons, contains('you usually avoid this'));
  });
}
