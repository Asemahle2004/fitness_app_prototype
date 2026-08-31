import 'exercise_performance_store.dart';
import 'workout_engine.dart';

class ProgressionSuggestion {
  final int? targetReps;
  final double? targetWeightKg;
  final int? targetDurationSeconds;
  final String headline;
  final String explanation;

  const ProgressionSuggestion({
    required this.targetReps,
    required this.targetWeightKg,
    required this.targetDurationSeconds,
    required this.headline,
    required this.explanation,
  });
}

class ProgressionEngine {
  static ProgressionSuggestion? suggest({
    required ExercisePrescription exercise,
    required ExerciseSetPerformance? previous,
  }) {
    if (previous == null) return null;

    if (previous.durationSeconds != null) {
      final prior = previous.durationSeconds!;
      final range = _numbers(exercise.reps);
      final upper = range.length >= 2 ? range[1] : null;
      final step = prior < 60 ? 5 : 10;
      final suggested = upper != null && prior < upper
          ? (prior + step).clamp(1, upper)
          : prior + step;
      return ProgressionSuggestion(
        targetReps: null,
        targetWeightKg: null,
        targetDurationSeconds: suggested,
        headline: 'Next target: ${_duration(suggested)}',
        explanation:
            'A small time increase is suggested only if the previous effort felt controlled and your technique stayed good.',
      );
    }

    final previousReps = previous.reps;
    if (previousReps == null) return null;

    final range = _numbers(exercise.reps);
    final lower = range.isEmpty ? previousReps : range.first;
    final upper = range.length >= 2 ? range[1] : range.firstOrNull ?? previousReps;
    final previousWeight = previous.weightKg;

    if (previousWeight != null && previousWeight > 0) {
      if (previousReps >= upper) {
        final increment = _loadIncrement(previousWeight);
        final nextWeight = _roundLoad(previousWeight + increment);
        return ProgressionSuggestion(
          targetReps: lower,
          targetWeightKg: nextWeight,
          targetDurationSeconds: null,
          headline: 'Next target: ${_weight(nextWeight)} kg × $lower reps',
          explanation:
              'You reached the top of the current rep range. LeanEat suggests a small load increase and returning to the lower end of the rep range.',
        );
      }

      final nextReps = (previousReps + 1).clamp(lower, upper);
      return ProgressionSuggestion(
        targetReps: nextReps,
        targetWeightKg: previousWeight,
        targetDurationSeconds: null,
        headline: 'Next target: ${_weight(previousWeight)} kg × $nextReps reps',
        explanation:
            'Keep the same load and add one controlled repetition before increasing the weight.',
      );
    }

    if (previousReps < upper) {
      final nextReps = (previousReps + 1).clamp(lower, upper);
      return ProgressionSuggestion(
        targetReps: nextReps,
        targetWeightKg: null,
        targetDurationSeconds: null,
        headline: 'Next target: $nextReps reps',
        explanation:
            'Add one controlled repetition while keeping the same exercise and good technique.',
      );
    }

    return ProgressionSuggestion(
      targetReps: upper,
      targetWeightKg: null,
      targetDurationSeconds: null,
      headline: 'Next target: maintain $upper clean reps',
      explanation:
          'You are already at the top of the rep range. Keep the reps controlled; a harder variation or added resistance can be considered later.',
    );
  }

  static List<int> _numbers(String value) {
    return RegExp(r'\d+')
        .allMatches(value)
        .map((match) => int.tryParse(match.group(0) ?? ''))
        .whereType<int>()
        .where((value) => value > 0)
        .take(2)
        .toList(growable: false);
  }

  static double _loadIncrement(double weight) {
    if (weight < 10) return 1;
    if (weight < 30) return 2;
    return 2.5;
  }

  static double _roundLoad(double value) => (value * 2).round() / 2;

  static String _weight(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

  static String _duration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return remainder == 0 ? '${minutes}m' : '${minutes}m ${remainder}s';
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
