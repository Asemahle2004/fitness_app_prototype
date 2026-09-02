import 'adaptive_strength_engine.dart';
import 'workout_engine.dart';

class RestTimerRecommendation {
  final int seconds;
  final String reason;

  const RestTimerRecommendation({required this.seconds, required this.reason});
}

class RestTimerCoach {
  const RestTimerCoach._();

  static RestTimerRecommendation recommend({
    required ExercisePrescription exercise,
    StrengthAdaptationRecommendation? adaptation,
    int? baseSeconds,
  }) {
    final parsedBase = baseSeconds ?? parseSeconds(exercise.rest);
    final target = exercise.target.toLowerCase();
    final name = exercise.name.toLowerCase();
    final reps = RegExp(r'\d+')
        .allMatches(exercise.reps)
        .map((match) => int.tryParse(match.group(0) ?? ''))
        .whereType<int>()
        .toList(growable: false);
    final upperReps = reps.isEmpty ? null : reps.last;

    final compound = target.contains('chest') ||
        target.contains('back') ||
        target.contains('legs') ||
        target.contains('glute') ||
        name.contains('squat') ||
        name.contains('deadlift') ||
        name.contains('press') ||
        name.contains('row') ||
        name.contains('pull-up') ||
        name.contains('chin-up');

    var seconds = parsedBase <= 0 ? 60 : parsedBase;
    var reason = 'Using the exercise prescription as the baseline.';

    if (compound && upperReps != null && upperReps <= 6) {
      seconds = seconds < 150 ? 150 : seconds;
      reason = 'Heavy compound work gets longer recovery to protect output and technique.';
    } else if (compound) {
      seconds = seconds < 90 ? 90 : seconds;
      reason = 'Compound work gets enough recovery to keep later sets productive.';
    } else if (seconds < 60) {
      seconds = 60;
      reason = 'Short accessory work uses at least a one-minute recovery baseline.';
    }

    final action = adaptation?.action;
    if (action == StrengthAdaptationAction.deload) {
      seconds = (seconds + 30).clamp(60, 210);
      reason = 'Deload mode adds recovery time while total working volume is reduced.';
    } else if (action == StrengthAdaptationAction.reduce) {
      seconds = (seconds + 15).clamp(60, 195);
      reason = 'Reduced-load mode gives slightly more recovery between working sets.';
    } else if (action == StrengthAdaptationAction.progress && compound) {
      seconds = (seconds + 15).clamp(60, 195);
      reason = 'Progression mode protects the quality of the heavier or higher-rep target.';
    }

    return RestTimerRecommendation(seconds: seconds, reason: reason);
  }

  static int parseSeconds(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('none')) return 0;
    final match = RegExp(r'\d+').firstMatch(lower);
    if (match == null) return lower.contains('needed') ? 30 : 60;
    final number = int.tryParse(match.group(0) ?? '') ?? 60;
    return lower.contains('min') ? number * 60 : number;
  }

  static String formatSeconds(int seconds) {
    if (seconds <= 0) return 'None';
    if (seconds % 60 == 0) {
      final minutes = seconds ~/ 60;
      return minutes == 1 ? '60 sec' : '$minutes min';
    }
    return '$seconds sec';
  }
}
