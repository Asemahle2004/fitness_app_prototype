import 'exercise_preference_store.dart';

class ExercisePreferenceAdjustment {
  final int scoreDelta;
  final List<String> reasons;

  const ExercisePreferenceAdjustment({
    required this.scoreDelta,
    required this.reasons,
  });
}

/// Applies preference only after programme-role, safety and equipment checks.
/// A favourite or frequently selected exercise can rise among otherwise valid
/// choices, while repeated dislikes/rejections lower it without inventing an
/// unsuitable replacement.
class ExercisePreferenceRanking {
  static ExercisePreferenceAdjustment adjustment({
    ExercisePreferenceRecord? record,
    bool favorite = false,
  }) {
    var delta = 0;
    final reasons = <String>[];

    if (favorite) {
      delta += 16;
      reasons.add('one of your favourites');
    }

    if (record != null) {
      final learned = record.score.clamp(-24, 18).toInt();
      delta += learned;

      if (record.stronglyAvoided) {
        delta -= 16;
        reasons.add('you usually avoid this');
      } else if (record.preferred || record.score >= 8) {
        reasons.add('matches your past choices');
      } else if (record.score <= -10) {
        reasons.add('lowered by your past choices');
      }
    }

    return ExercisePreferenceAdjustment(
      scoreDelta: delta,
      reasons: reasons.toSet().take(2).toList(growable: false),
    );
  }
}
