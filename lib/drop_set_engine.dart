import 'workout_engine.dart';

class DropSetConfig {
  final int drops;
  final int reductionPercent;

  const DropSetConfig({
    required this.drops,
    required this.reductionPercent,
  });

  bool get enabled => drops > 0;
}

class DropSetEngine {
  static const int defaultReductionPercent = 20;
  static const int maxDrops = 3;

  static bool isTimed(ExercisePrescription exercise) {
    final value = exercise.reps.toLowerCase();
    return exercise.metricLabel == 'TIME' ||
        value.contains(' sec') ||
        value.contains(' min') ||
        value.contains('minute') ||
        value.contains('km') ||
        value.contains('walk');
  }

  static bool isLoadTrackedStrength(ExercisePrescription exercise) {
    if (isTimed(exercise)) return false;
    final equipment = exercise.equipment.toLowerCase();
    const tracked = [
      'barbell',
      'dumbbell',
      'kettlebell',
      'machine',
      'cable',
      'smith',
      'plate',
      'leg press',
    ];
    return tracked.any(equipment.contains);
  }

  static bool canConfigure(ExercisePrescription exercise) {
    return exercise.supersetId == null && isLoadTrackedStrength(exercise);
  }

  static bool hasDropSet(ExercisePrescription exercise) {
    return exercise.dropSetCount > 0;
  }

  static ExercisePrescription configure(
    ExercisePrescription exercise,
    DropSetConfig config,
  ) {
    if (!config.enabled) return clear(exercise);
    if (!canConfigure(exercise)) return exercise;
    return exercise.copyWith(
      dropSetCount: config.drops.clamp(1, maxDrops),
      dropSetReductionPercent: config.reductionPercent.clamp(10, 40),
    );
  }

  static ExercisePrescription clear(ExercisePrescription exercise) {
    return exercise.copyWith(clearDropSet: true);
  }

  static double? suggestedWeight({
    required double? workingWeightKg,
    required int reductionPercent,
    required int dropNumber,
  }) {
    if (workingWeightKg == null || workingWeightKg <= 0 || dropNumber <= 0) {
      return null;
    }
    final reduction = 1 - reductionPercent.clamp(10, 40) / 100;
    var result = workingWeightKg;
    for (var i = 0; i < dropNumber; i += 1) {
      result *= reduction;
    }
    return (result * 2).round() / 2;
  }

  static String badge(ExercisePrescription exercise) {
    if (!hasDropSet(exercise)) return '';
    final noun = exercise.dropSetCount == 1 ? 'drop' : 'drops';
    return '${exercise.dropSetCount} $noun • -${exercise.dropSetReductionPercent}%';
  }
}
