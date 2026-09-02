import 'dart:math' as math;

import 'adaptive_strength_engine.dart';
import 'exercise_performance_store.dart';
import 'muscle_intelligence_engine.dart';
import 'set_effort_store.dart';

enum AdvancedProgressionAction {
  buildBaseline,
  progressReps,
  progressLoad,
  hold,
  reduce,
  resetPlateau,
}

class AdvancedProgressionRecommendation {
  final AdvancedProgressionAction action;
  final String headline;
  final String explanation;
  final double? targetWeightKg;
  final int? targetReps;
  final int? backOffSets;
  final double? backOffLoadMultiplier;
  final double? estimatedOneRepMaxKg;
  final int exposuresAnalysed;
  final bool plateauDetected;
  final List<String> reasons;

  const AdvancedProgressionRecommendation({
    required this.action,
    required this.headline,
    required this.explanation,
    required this.targetWeightKg,
    required this.targetReps,
    required this.backOffSets,
    required this.backOffLoadMultiplier,
    required this.estimatedOneRepMaxKg,
    required this.exposuresAnalysed,
    required this.plateauDetected,
    required this.reasons,
  });
}

class AdvancedStrengthProgressionEngine {
  const AdvancedStrengthProgressionEngine._();

  static AdvancedProgressionRecommendation recommend({
    required String exerciseName,
    required List<ExerciseSetPerformance> history,
    List<SetEffortRecord> efforts = const <SetEffortRecord>[],
    StrengthAdaptationRecommendation? globalAdaptation,
    MuscleIntelligenceReport? muscleReport,
    int repFloor = 6,
    int repCeiling = 12,
  }) {
    final key = exerciseName.trim().toLowerCase();
    final sets = history
        .where((item) =>
            !item.isDropSet && item.exerciseName.trim().toLowerCase() == key)
        .toList(growable: false)
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    if (sets.isEmpty) {
      return _result(
        action: AdvancedProgressionAction.buildBaseline,
        headline: 'Log a baseline before progressing',
        explanation:
            'LeanIt needs repeated controlled sets for this exercise before it changes load automatically.',
        exposures: 0,
        reasons: const ['No working-set history is available for this exercise yet.'],
      );
    }

    final exposures = _groupExposures(sets);
    final latest = exposures.first;
    final latestBest = _bestWeightedSet(latest);
    final latestEffort = _latestEffortFor(exerciseName, efforts);
    final hardEffort = latestEffort != null &&
        (latestEffort.estimatedRpe >= 9.5 || latestEffort.estimatedRir <= 0);
    final nearLimit = latestEffort != null &&
        (latestEffort.estimatedRpe >= 9 || latestEffort.estimatedRir <= 1);

    final muscles = MuscleIntelligenceEngine.musclesForExercise(exerciseName);
    MuscleTrainingStatus? leastRecovered;
    if (muscleReport != null && muscles.isNotEmpty) {
      final candidates = muscles
          .map(muscleReport.statusFor)
          .toList(growable: false)
        ..sort((a, b) => a.recoveryPercent.compareTo(b.recoveryPercent));
      leastRecovered = candidates.first;
    }

    if (globalAdaptation?.action == StrengthAdaptationAction.deload ||
        leastRecovered != null && leastRecovered.recoveryPercent < 45) {
      final weight = latestBest?.weightKg;
      return _result(
        action: AdvancedProgressionAction.reduce,
        headline: 'Reduce the target while recovery catches up',
        explanation:
            'Global fatigue or local muscle recovery is too low for a progression attempt.',
        weight: weight == null ? null : _roundLoad(weight * 0.90),
        reps: latestBest?.reps == null
            ? null
            : math.max(repFloor, latestBest!.reps! - 1),
        exposures: exposures.length,
        oneRm: _estimated1Rm(latestBest),
        backOffSets: 2,
        backOffMultiplier: 0.85,
        reasons: [
          if (globalAdaptation?.action == StrengthAdaptationAction.deload)
            'The whole-programme fatigue engine is currently in deload mode.',
          if (leastRecovered != null)
            '${leastRecovered.muscle.label} recovery is ${leastRecovered.recoveryPercent.round()}%.',
        ],
      );
    }

    if (hardEffort) {
      return _result(
        action: AdvancedProgressionAction.hold,
        headline: 'Hold this load',
        explanation:
            'The last set was at or very near failure. LeanIt will not reward a maximal effort with another automatic load increase.',
        weight: latestBest?.weightKg,
        reps: latestBest?.reps,
        exposures: exposures.length,
        oneRm: _estimated1Rm(latestBest),
        reasons: [
          'Latest effort was approximately RPE ${latestEffort!.estimatedRpe.toStringAsFixed(1)} / RIR ${latestEffort.estimatedRir}.',
        ],
      );
    }

    final plateau = _plateauDetected(exposures);
    if (plateau && exposures.length >= 3) {
      final weight = latestBest?.weightKg;
      return _result(
        action: AdvancedProgressionAction.resetPlateau,
        headline: 'Reset the plateau instead of forcing weight',
        explanation:
            'Several exposures have repeated nearly the same performance. LeanIt recommends a small reset with cleaner reps, then rebuilding.',
        weight: weight == null ? null : _roundLoad(weight * 0.925),
        reps: latestBest?.reps == null
            ? null
            : math.max(repFloor, latestBest!.reps! - 1),
        exposures: exposures.length,
        oneRm: _estimated1Rm(latestBest),
        plateau: true,
        backOffSets: 2,
        backOffMultiplier: 0.90,
        reasons: const [
          'Three or more recent exposures show no meaningful estimated-strength improvement.',
          'A small reset is safer than repeatedly grinding the same stalled target.',
        ],
      );
    }

    if (globalAdaptation != null && !globalAdaptation.allowsProgression) {
      return _result(
        action: globalAdaptation.protectsRecovery
            ? AdvancedProgressionAction.reduce
            : AdvancedProgressionAction.hold,
        headline: globalAdaptation.protectsRecovery
            ? 'Back off this exercise today'
            : 'Hold the current target',
        explanation: globalAdaptation.explanation,
        weight: latestBest?.weightKg == null || !globalAdaptation.protectsRecovery
            ? latestBest?.weightKg
            : _roundLoad(
                latestBest!.weightKg! * globalAdaptation.suggestedLoadMultiplier,
              ),
        reps: latestBest?.reps,
        exposures: exposures.length,
        oneRm: _estimated1Rm(latestBest),
        reasons: globalAdaptation.reasons,
      );
    }

    if (exposures.length < 2 || latestBest == null) {
      return _result(
        action: AdvancedProgressionAction.buildBaseline,
        headline: 'Repeat once more before progressing',
        explanation:
            'One exposure is not enough evidence for a reliable automatic strength increase.',
        weight: latestBest?.weightKg,
        reps: latestBest?.reps,
        exposures: exposures.length,
        oneRm: _estimated1Rm(latestBest),
        reasons: const ['LeanIt requires repeated exposure, not one unusually good set.'],
      );
    }

    final priorBest = _bestWeightedSet(exposures[1]);
    final latestSignal = _estimated1Rm(latestBest) ?? latestBest.volumeKg;
    final priorSignal = _estimated1Rm(priorBest) ?? priorBest?.volumeKg ?? 0;
    final repeatedSuccess = priorSignal > 0 && latestSignal >= priorSignal * 0.99;
    final recovered = leastRecovered == null || leastRecovered.recoveryPercent >= 65;

    if (!repeatedSuccess || !recovered || nearLimit) {
      return _result(
        action: AdvancedProgressionAction.hold,
        headline: 'Repeat the current target cleanly',
        explanation:
            'Progression is waiting for another controlled exposure with enough recovery and effort left in reserve.',
        weight: latestBest.weightKg,
        reps: latestBest.reps,
        exposures: exposures.length,
        oneRm: _estimated1Rm(latestBest),
        reasons: [
          if (!repeatedSuccess) 'The previous exposure does not yet confirm repeatable performance.',
          if (!recovered && leastRecovered != null)
            '${leastRecovered.muscle.label} recovery is only ${leastRecovered.recoveryPercent.round()}%.',
          if (nearLimit && latestEffort != null)
            'Latest effort was RPE ${latestEffort.estimatedRpe.toStringAsFixed(1)} / RIR ${latestEffort.estimatedRir}.',
        ],
      );
    }

    final reps = latestBest.reps;
    final load = latestBest.weightKg;
    if (reps != null && reps >= repCeiling && load != null) {
      final increment = load < 30 ? 1.0 : (load < 80 ? 2.5 : 5.0);
      return _result(
        action: AdvancedProgressionAction.progressLoad,
        headline: 'Increase load and reset reps',
        explanation:
            'The top of the rep range has been repeated with acceptable recovery, so LeanIt can make a small load increase.',
        weight: _roundLoad(load + increment),
        reps: math.max(repFloor, repCeiling - 3),
        exposures: exposures.length,
        oneRm: _estimated1Rm(latestBest),
        backOffSets: 2,
        backOffMultiplier: 0.90,
        reasons: [
          'Latest set reached $reps reps at ${load.toStringAsFixed(1)} kg.',
          'Repeated performance supports a measured load increase rather than a large jump.',
        ],
      );
    }

    if (reps != null) {
      return _result(
        action: AdvancedProgressionAction.progressReps,
        headline: 'Add one rep before adding weight',
        explanation:
            'LeanIt uses double progression: build reps within the range first, then increase load after the top is controlled.',
        weight: load,
        reps: math.min(repCeiling, reps + 1),
        exposures: exposures.length,
        oneRm: _estimated1Rm(latestBest),
        reasons: const ['Recovery and repeatability support a small progression step.'],
      );
    }

    return _result(
      action: AdvancedProgressionAction.hold,
      headline: 'Hold the current prescription',
      explanation: 'LeanIt does not have a valid reps-and-load signal to progress.',
      exposures: exposures.length,
      reasons: const ['The recent set format cannot support a safe load recommendation.'],
    );
  }

  static List<List<ExerciseSetPerformance>> _groupExposures(
    List<ExerciseSetPerformance> sorted,
  ) {
    final groups = <String, List<ExerciseSetPerformance>>{};
    for (final set in sorted) {
      final local = set.performedAt.toLocal();
      final key = '${local.year}-${local.month}-${local.day}-${set.workoutTitle}';
      groups.putIfAbsent(key, () => <ExerciseSetPerformance>[]).add(set);
    }
    final values = groups.values.toList(growable: false)
      ..sort((a, b) => b.first.performedAt.compareTo(a.first.performedAt));
    return values;
  }

  static ExerciseSetPerformance? _bestWeightedSet(
    List<ExerciseSetPerformance>? exposure,
  ) {
    if (exposure == null || exposure.isEmpty) return null;
    final weighted = exposure
        .where((set) =>
            set.weightKg != null && set.weightKg! > 0 && set.reps != null && set.reps! > 0)
        .toList(growable: false);
    if (weighted.isEmpty) return exposure.first;
    weighted.sort((a, b) {
      final as = _estimated1Rm(a) ?? a.volumeKg;
      final bs = _estimated1Rm(b) ?? b.volumeKg;
      return bs.compareTo(as);
    });
    return weighted.first;
  }

  static double? _estimated1Rm(ExerciseSetPerformance? set) {
    if (set?.weightKg == null || set?.reps == null) return null;
    final reps = set!.reps!;
    if (reps < 1 || reps > 15 || set.weightKg! <= 0) return null;
    return set.weightKg! * (1 + reps / 30.0);
  }

  static SetEffortRecord? _latestEffortFor(
    String exerciseName,
    List<SetEffortRecord> efforts,
  ) {
    final key = exerciseName.trim().toLowerCase();
    final matches = efforts
        .where((item) => item.exerciseName.trim().toLowerCase() == key && item.hasEffort)
        .toList(growable: false)
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return matches.isEmpty ? null : matches.first;
  }

  static bool _plateauDetected(List<List<ExerciseSetPerformance>> exposures) {
    if (exposures.length < 3) return false;
    final signals = exposures.take(4).map((exposure) {
      final best = _bestWeightedSet(exposure);
      return _estimated1Rm(best) ?? best?.volumeKg ?? 0;
    }).where((value) => value > 0).toList(growable: false);
    if (signals.length < 3) return false;
    final maxSignal = signals.reduce(math.max);
    final minSignal = signals.reduce(math.min);
    return maxSignal <= minSignal * 1.015;
  }

  static double _roundLoad(double value) => (value * 2).round() / 2.0;

  static AdvancedProgressionRecommendation _result({
    required AdvancedProgressionAction action,
    required String headline,
    required String explanation,
    double? weight,
    int? reps,
    int? backOffSets,
    double? backOffMultiplier,
    double? oneRm,
    required int exposures,
    bool plateau = false,
    required List<String> reasons,
  }) {
    return AdvancedProgressionRecommendation(
      action: action,
      headline: headline,
      explanation: explanation,
      targetWeightKg: weight,
      targetReps: reps,
      backOffSets: backOffSets,
      backOffLoadMultiplier: backOffMultiplier,
      estimatedOneRepMaxKg: oneRm,
      exposuresAnalysed: exposures,
      plateauDetected: plateau,
      reasons: List<String>.unmodifiable(reasons),
    );
  }
}
