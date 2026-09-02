import 'dart:math' as math;

import 'exercise_performance_store.dart';
import 'set_effort_store.dart';

enum TrainingMuscle {
  chest('Chest'),
  back('Back / Lats'),
  shoulders('Shoulders'),
  biceps('Biceps'),
  triceps('Triceps'),
  quads('Quads'),
  hamstrings('Hamstrings'),
  glutes('Glutes'),
  calves('Calves'),
  core('Core');

  final String label;
  const TrainingMuscle(this.label);
}

enum MuscleLoadStatus { undertrained, productive, high, recoveryFirst }

class MuscleTrainingStatus {
  final TrainingMuscle muscle;
  final int currentWeekSets;
  final int previousWeekSets;
  final double currentWeekVolumeKg;
  final double previousWeekVolumeKg;
  final double recoveryPercent;
  final DateTime? latestStimulusAt;
  final double averageRecentRpe;
  final MuscleLoadStatus loadStatus;

  const MuscleTrainingStatus({
    required this.muscle,
    required this.currentWeekSets,
    required this.previousWeekSets,
    required this.currentWeekVolumeKg,
    required this.previousWeekVolumeKg,
    required this.recoveryPercent,
    required this.latestStimulusAt,
    required this.averageRecentRpe,
    required this.loadStatus,
  });

  bool get readyForHardTraining => recoveryPercent >= 70;
}

class MuscleIntelligenceReport {
  final List<MuscleTrainingStatus> muscles;
  final DateTime generatedAt;

  const MuscleIntelligenceReport({
    required this.muscles,
    required this.generatedAt,
  });

  MuscleTrainingStatus statusFor(TrainingMuscle muscle) =>
      muscles.firstWhere((item) => item.muscle == muscle);

  List<MuscleTrainingStatus> get leastRecovered {
    final copy = List<MuscleTrainingStatus>.from(muscles)
      ..sort((a, b) => a.recoveryPercent.compareTo(b.recoveryPercent));
    return copy;
  }
}

class MuscleIntelligenceEngine {
  const MuscleIntelligenceEngine._();

  static MuscleIntelligenceReport analyse({
    required List<ExerciseSetPerformance> sets,
    List<SetEffortRecord> efforts = const <SetEffortRecord>[],
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final weekStart = _weekStart(reference);
    final priorStart = weekStart.subtract(const Duration(days: 7));
    final futureTolerance = reference.add(const Duration(minutes: 5));

    final output = <MuscleTrainingStatus>[];
    for (final muscle in TrainingMuscle.values) {
      final relevant = sets.where((set) {
        if (set.isDropSet || set.performedAt.isAfter(futureTolerance)) return false;
        return musclesForExercise(set.exerciseName).contains(muscle);
      }).toList(growable: false);

      final current = relevant
          .where((set) => !set.performedAt.isBefore(weekStart))
          .toList(growable: false);
      final previous = relevant
          .where((set) =>
              !set.performedAt.isBefore(priorStart) &&
              set.performedAt.isBefore(weekStart))
          .toList(growable: false);

      DateTime? latest;
      for (final set in relevant) {
        if (latest == null || set.performedAt.isAfter(latest)) {
          latest = set.performedAt;
        }
      }

      final recentEfforts = efforts.where((effort) {
        if (effort.recordedAt.isBefore(reference.subtract(const Duration(days: 7))) ||
            effort.recordedAt.isAfter(futureTolerance)) {
          return false;
        }
        return musclesForExercise(effort.exerciseName).contains(muscle);
      }).toList(growable: false);
      final averageRpe = recentEfforts.isEmpty
          ? 7.5
          : recentEfforts
                  .map((item) => item.estimatedRpe)
                  .reduce((a, b) => a + b) /
              recentEfforts.length;

      final recovery = _recoveryPercent(
        relevant: relevant,
        efforts: recentEfforts,
        reference: reference,
        latest: latest,
      );
      final loadStatus = _loadStatus(
        currentSets: current.length,
        previousSets: previous.length,
        recoveryPercent: recovery,
        averageRpe: averageRpe,
      );

      output.add(
        MuscleTrainingStatus(
          muscle: muscle,
          currentWeekSets: current.length,
          previousWeekSets: previous.length,
          currentWeekVolumeKg:
              current.fold<double>(0, (sum, item) => sum + item.volumeKg),
          previousWeekVolumeKg:
              previous.fold<double>(0, (sum, item) => sum + item.volumeKg),
          recoveryPercent: recovery,
          latestStimulusAt: latest,
          averageRecentRpe: averageRpe,
          loadStatus: loadStatus,
        ),
      );
    }

    return MuscleIntelligenceReport(
      muscles: List<MuscleTrainingStatus>.unmodifiable(output),
      generatedAt: reference,
    );
  }

  static double _recoveryPercent({
    required List<ExerciseSetPerformance> relevant,
    required List<SetEffortRecord> efforts,
    required DateTime reference,
    required DateTime? latest,
  }) {
    if (latest == null) return 100;
    final hours = math.max(0, reference.difference(latest).inMinutes / 60.0);
    final recent48h = relevant.where((set) {
      return set.performedAt.isAfter(reference.subtract(const Duration(hours: 48))) &&
          !set.performedAt.isAfter(reference);
    }).length;
    final recent72h = relevant.where((set) {
      return set.performedAt.isAfter(reference.subtract(const Duration(hours: 72))) &&
          !set.performedAt.isAfter(reference);
    }).length;

    var recovery = (hours / 60.0 * 100).clamp(12.0, 100.0).toDouble();
    recovery -= math.min(30, recent48h * 3.0);
    recovery -= math.min(12, math.max(0, recent72h - recent48h) * 1.5);

    if (efforts.isNotEmpty) {
      final hard = efforts.where((item) => item.estimatedRpe >= 9).length;
      final failureLike = efforts.where((item) => item.estimatedRir <= 1).length;
      recovery -= math.min(18, hard * 3.0 + failureLike * 2.0);
    }

    if (hours >= 72 && recent48h == 0) recovery = math.max(recovery, 86);
    if (hours >= 96) recovery = math.max(recovery, 95);
    return recovery.clamp(0.0, 100.0).toDouble();
  }

  static MuscleLoadStatus _loadStatus({
    required int currentSets,
    required int previousSets,
    required double recoveryPercent,
    required double averageRpe,
  }) {
    if (recoveryPercent < 50 || (currentSets >= 10 && averageRpe >= 9)) {
      return MuscleLoadStatus.recoveryFirst;
    }
    if (currentSets >= 16 ||
        (previousSets >= 8 && currentSets > previousSets * 1.35)) {
      return MuscleLoadStatus.high;
    }
    if (currentSets <= 3) return MuscleLoadStatus.undertrained;
    return MuscleLoadStatus.productive;
  }

  static Set<TrainingMuscle> musclesForExercise(String name) {
    final text = name.trim().toLowerCase();
    final muscles = <TrainingMuscle>{};

    void add(TrainingMuscle muscle, List<String> keywords) {
      if (keywords.any(text.contains)) muscles.add(muscle);
    }

    add(TrainingMuscle.chest, const [
      'bench press', 'chest press', 'push-up', 'push up', 'pec', 'fly', 'press-up'
    ]);
    add(TrainingMuscle.back, const [
      'row', 'pulldown', 'pull-down', 'pull-up', 'pull up', 'chin-up',
      'chin up', 'lat ', 'face pull', 'reverse fly', 'bird dog'
    ]);
    add(TrainingMuscle.shoulders, const [
      'shoulder press', 'overhead press', 'lateral raise', 'front raise',
      'rear delt', 'face pull', 'arnold press', 'pike push'
    ]);
    add(TrainingMuscle.biceps, const ['curl', 'chin-up', 'chin up']);
    add(TrainingMuscle.triceps, const [
      'triceps', 'pushdown', 'push-down', 'dip', 'bench press', 'push-up',
      'push up', 'overhead press', 'shoulder press'
    ]);
    add(TrainingMuscle.quads, const [
      'squat', 'lunge', 'leg press', 'leg extension', 'step-up', 'step up',
      'split squat', 'wall sit', 'short arc quad'
    ]);
    add(TrainingMuscle.hamstrings, const [
      'romanian deadlift', 'rdl', 'leg curl', 'hamstring', 'good morning',
      'deadlift'
    ]);
    add(TrainingMuscle.glutes, const [
      'glute', 'hip thrust', 'bridge', 'squat', 'lunge', 'split squat',
      'romanian deadlift', 'rdl', 'deadlift', 'clamshell', 'hip abduction'
    ]);
    add(TrainingMuscle.calves, const ['calf', 'calves']);
    add(TrainingMuscle.core, const [
      'plank', 'dead bug', 'bird dog', 'crunch', 'sit-up', 'sit up',
      'leg raise', 'pallof', 'core', 'hollow', 'mountain climber'
    ]);

    if (muscles.isEmpty) {
      if (text.contains('run') || text.contains('sprint') || text.contains('walk')) {
        muscles.addAll(const {
          TrainingMuscle.quads,
          TrainingMuscle.hamstrings,
          TrainingMuscle.glutes,
          TrainingMuscle.calves,
        });
      }
    }
    return muscles;
  }

  static DateTime _weekStart(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }
}
