import 'exercise_performance_store.dart';
import 'run_tracking_store.dart';

enum PersonalRecordMetric {
  heaviestLoad,
  mostReps,
  setVolume,
  timedDuration,
  longestRun,
  fastestPace,
}

extension PersonalRecordMetricDetails on PersonalRecordMetric {
  String get label {
    switch (this) {
      case PersonalRecordMetric.heaviestLoad:
        return 'Heaviest load';
      case PersonalRecordMetric.mostReps:
        return 'Most reps';
      case PersonalRecordMetric.setVolume:
        return 'Best set volume';
      case PersonalRecordMetric.timedDuration:
        return 'Longest timed set';
      case PersonalRecordMetric.longestRun:
        return 'Longest run';
      case PersonalRecordMetric.fastestPace:
        return 'Fastest average pace';
    }
  }

  bool get isRunning =>
      this == PersonalRecordMetric.longestRun ||
      this == PersonalRecordMetric.fastestPace;

  bool get lowerIsBetter => this == PersonalRecordMetric.fastestPace;
}

class PersonalRecordAchievement {
  final PersonalRecordMetric metric;
  final String subject;
  final double value;
  final double? previousValue;
  final DateTime achievedAt;
  final String detail;
  final String sourceId;

  const PersonalRecordAchievement({
    required this.metric,
    required this.subject,
    required this.value,
    required this.previousValue,
    required this.achievedAt,
    required this.detail,
    required this.sourceId,
  });

  String get key => '${subject.trim().toLowerCase()}|${metric.name}';
  bool get isRunning => metric.isRunning;
  bool get isBaseline => previousValue == null;
  String get displayValue => PersonalRecordEngine.formatValue(metric, value);

  String get previousLabel => previousValue == null
      ? 'First benchmark'
      : 'Previous ${PersonalRecordEngine.formatValue(metric, previousValue!)}';
}

class PersonalRecordEngine {
  static const double _epsilon = 0.000001;

  static List<PersonalRecordAchievement> currentRecords({
    required Iterable<ExerciseSetPerformance> sets,
    required Iterable<RunRecord> runs,
  }) {
    final history = recordHistory(sets: sets, runs: runs);
    final current = <String, PersonalRecordAchievement>{};
    for (final record in history) {
      current.putIfAbsent(record.key, () => record);
    }
    final records = current.values.toList(growable: false)
      ..sort(_currentRecordSort);
    return records;
  }

  static List<PersonalRecordAchievement> recordHistory({
    required Iterable<ExerciseSetPerformance> sets,
    required Iterable<RunRecord> runs,
  }) {
    final events = <PersonalRecordAchievement>[];
    final best = <String, double>{};

    final sortedSets = sets.where((set) => !set.isDropSet).toList(growable: false)
      ..sort((a, b) => a.performedAt.compareTo(b.performedAt));

    for (final set in sortedSets) {
      final subject = set.exerciseName.trim().isEmpty
          ? 'Exercise'
          : set.exerciseName.trim();
      final sourceId = _setSourceId(set);
      final detail = '${set.workoutTitle} • ${set.summary}';

      final weight = set.weightKg;
      if (weight != null && weight > 0) {
        _recordHigher(
          events: events,
          best: best,
          metric: PersonalRecordMetric.heaviestLoad,
          subject: subject,
          value: weight,
          achievedAt: set.performedAt,
          detail: detail,
          sourceId: sourceId,
        );
      }

      final reps = set.reps;
      if (reps != null && reps > 0) {
        _recordHigher(
          events: events,
          best: best,
          metric: PersonalRecordMetric.mostReps,
          subject: subject,
          value: reps.toDouble(),
          achievedAt: set.performedAt,
          detail: detail,
          sourceId: sourceId,
        );
      }

      final volume = set.volumeKg;
      if (volume > 0) {
        _recordHigher(
          events: events,
          best: best,
          metric: PersonalRecordMetric.setVolume,
          subject: subject,
          value: volume,
          achievedAt: set.performedAt,
          detail: detail,
          sourceId: sourceId,
        );
      }

      final duration = set.durationSeconds;
      if (duration != null && duration > 0) {
        _recordHigher(
          events: events,
          best: best,
          metric: PersonalRecordMetric.timedDuration,
          subject: subject,
          value: duration.toDouble(),
          achievedAt: set.performedAt,
          detail: detail,
          sourceId: sourceId,
        );
      }
    }

    final sortedRuns = runs.toList(growable: false)
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    for (final run in sortedRuns) {
      final sourceId = 'run|${run.id}';
      final detail =
          '${run.source == 'gps' ? 'GPS run' : 'Logged run'} • ${_formatDuration(run.durationSeconds)}';

      if (run.distanceMeters > 0) {
        _recordHigher(
          events: events,
          best: best,
          metric: PersonalRecordMetric.longestRun,
          subject: 'Running',
          value: run.distanceMeters,
          achievedAt: run.startedAt,
          detail: detail,
          sourceId: sourceId,
        );
      }

      final pace = run.averagePaceSecondsPerKm;
      if (pace != null && pace > 0 && run.distanceMeters >= 500) {
        _recordLower(
          events: events,
          best: best,
          metric: PersonalRecordMetric.fastestPace,
          subject: 'Running',
          value: pace,
          achievedAt: run.startedAt,
          detail: detail,
          sourceId: sourceId,
        );
      }
    }

    events.sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
    return events;
  }

  static List<PersonalRecordAchievement> newSetRecords({
    required ExerciseSetPerformance current,
    required Iterable<ExerciseSetPerformance> previous,
  }) {
    if (current.isDropSet) return const <PersonalRecordAchievement>[];

    final subject = current.exerciseName.trim().isEmpty
        ? 'Exercise'
        : current.exerciseName.trim();
    final lower = subject.toLowerCase();
    final comparable = previous.where(
      (set) => !set.isDropSet && set.exerciseName.trim().toLowerCase() == lower,
    );

    double? bestLoad;
    double? bestReps;
    double? bestVolume;
    double? bestDuration;
    for (final set in comparable) {
      final weight = set.weightKg;
      if (weight != null && weight > 0) {
        bestLoad = bestLoad == null || weight > bestLoad ? weight : bestLoad;
      }
      final reps = set.reps;
      if (reps != null && reps > 0) {
        final value = reps.toDouble();
        bestReps = bestReps == null || value > bestReps ? value : bestReps;
      }
      final volume = set.volumeKg;
      if (volume > 0) {
        bestVolume = bestVolume == null || volume > bestVolume
            ? volume
            : bestVolume;
      }
      final duration = set.durationSeconds;
      if (duration != null && duration > 0) {
        final value = duration.toDouble();
        bestDuration = bestDuration == null || value > bestDuration
            ? value
            : bestDuration;
      }
    }

    final sourceId = _setSourceId(current);
    final detail = '${current.workoutTitle} • ${current.summary}';
    final achievements = <PersonalRecordAchievement>[];

    final weight = current.weightKg;
    if (weight != null &&
        weight > 0 &&
        (bestLoad == null || weight > bestLoad + _epsilon)) {
      achievements.add(PersonalRecordAchievement(
        metric: PersonalRecordMetric.heaviestLoad,
        subject: subject,
        value: weight,
        previousValue: bestLoad,
        achievedAt: current.performedAt,
        detail: detail,
        sourceId: sourceId,
      ));
    }

    final reps = current.reps;
    if (reps != null && reps > 0) {
      final value = reps.toDouble();
      if (bestReps == null || value > bestReps + _epsilon) {
        achievements.add(PersonalRecordAchievement(
          metric: PersonalRecordMetric.mostReps,
          subject: subject,
          value: value,
          previousValue: bestReps,
          achievedAt: current.performedAt,
          detail: detail,
          sourceId: sourceId,
        ));
      }
    }

    final volume = current.volumeKg;
    if (volume > 0 &&
        (bestVolume == null || volume > bestVolume + _epsilon)) {
      achievements.add(PersonalRecordAchievement(
        metric: PersonalRecordMetric.setVolume,
        subject: subject,
        value: volume,
        previousValue: bestVolume,
        achievedAt: current.performedAt,
        detail: detail,
        sourceId: sourceId,
      ));
    }

    final duration = current.durationSeconds;
    if (duration != null && duration > 0) {
      final value = duration.toDouble();
      if (bestDuration == null || value > bestDuration + _epsilon) {
        achievements.add(PersonalRecordAchievement(
          metric: PersonalRecordMetric.timedDuration,
          subject: subject,
          value: value,
          previousValue: bestDuration,
          achievedAt: current.performedAt,
          detail: detail,
          sourceId: sourceId,
        ));
      }
    }

    return achievements;
  }

  static List<PersonalRecordAchievement> newRunRecords({
    required RunRecord current,
    required Iterable<RunRecord> previous,
  }) {
    double? longestDistance;
    double? fastestPace;
    for (final run in previous) {
      if (run.distanceMeters > 0) {
        longestDistance = longestDistance == null ||
                run.distanceMeters > longestDistance
            ? run.distanceMeters
            : longestDistance;
      }
      final pace = run.averagePaceSecondsPerKm;
      if (pace != null && pace > 0 && run.distanceMeters >= 500) {
        fastestPace = fastestPace == null || pace < fastestPace
            ? pace
            : fastestPace;
      }
    }

    final sourceId = 'run|${current.id}';
    final detail =
        '${current.source == 'gps' ? 'GPS run' : 'Logged run'} • ${_formatDuration(current.durationSeconds)}';
    final achievements = <PersonalRecordAchievement>[];

    if (current.distanceMeters > 0 &&
        (longestDistance == null ||
            current.distanceMeters > longestDistance + _epsilon)) {
      achievements.add(PersonalRecordAchievement(
        metric: PersonalRecordMetric.longestRun,
        subject: 'Running',
        value: current.distanceMeters,
        previousValue: longestDistance,
        achievedAt: current.startedAt,
        detail: detail,
        sourceId: sourceId,
      ));
    }

    final pace = current.averagePaceSecondsPerKm;
    if (pace != null && pace > 0 && current.distanceMeters >= 500) {
      if (fastestPace == null || pace < fastestPace - _epsilon) {
        achievements.add(PersonalRecordAchievement(
          metric: PersonalRecordMetric.fastestPace,
          subject: 'Running',
          value: pace,
          previousValue: fastestPace,
          achievedAt: current.startedAt,
          detail: detail,
          sourceId: sourceId,
        ));
      }
    }

    return achievements;
  }

  static String formatValue(PersonalRecordMetric metric, double value) {
    switch (metric) {
      case PersonalRecordMetric.heaviestLoad:
        return '${_formatNumber(value)} kg';
      case PersonalRecordMetric.mostReps:
        return '${value.round()} reps';
      case PersonalRecordMetric.setVolume:
        return '${_formatNumber(value)} kg·reps';
      case PersonalRecordMetric.timedDuration:
        return _formatDuration(value.round());
      case PersonalRecordMetric.longestRun:
        return '${(value / 1000).toStringAsFixed(2)} km';
      case PersonalRecordMetric.fastestPace:
        return _formatPace(value);
    }
  }

  static void _recordHigher({
    required List<PersonalRecordAchievement> events,
    required Map<String, double> best,
    required PersonalRecordMetric metric,
    required String subject,
    required double value,
    required DateTime achievedAt,
    required String detail,
    required String sourceId,
  }) {
    final key = '${subject.trim().toLowerCase()}|${metric.name}';
    final previous = best[key];
    if (previous != null && value <= previous + _epsilon) return;
    events.add(PersonalRecordAchievement(
      metric: metric,
      subject: subject,
      value: value,
      previousValue: previous,
      achievedAt: achievedAt,
      detail: detail,
      sourceId: sourceId,
    ));
    best[key] = value;
  }

  static void _recordLower({
    required List<PersonalRecordAchievement> events,
    required Map<String, double> best,
    required PersonalRecordMetric metric,
    required String subject,
    required double value,
    required DateTime achievedAt,
    required String detail,
    required String sourceId,
  }) {
    final key = '${subject.trim().toLowerCase()}|${metric.name}';
    final previous = best[key];
    if (previous != null && value >= previous - _epsilon) return;
    events.add(PersonalRecordAchievement(
      metric: metric,
      subject: subject,
      value: value,
      previousValue: previous,
      achievedAt: achievedAt,
      detail: detail,
      sourceId: sourceId,
    ));
    best[key] = value;
  }

  static int _currentRecordSort(
    PersonalRecordAchievement a,
    PersonalRecordAchievement b,
  ) {
    if (a.isRunning != b.isRunning) return a.isRunning ? -1 : 1;
    final subject = a.subject.toLowerCase().compareTo(b.subject.toLowerCase());
    if (subject != 0) return subject;
    return a.metric.index.compareTo(b.metric.index);
  }

  static String _setSourceId(ExerciseSetPerformance set) {
    return [
      'set',
      set.exerciseName.trim().toLowerCase(),
      set.setNumber,
      set.reps,
      set.weightKg,
      set.durationSeconds,
      set.performedAt.toUtc().toIso8601String(),
    ].join('|');
  }

  static String _formatNumber(double value) {
    if ((value - value.round()).abs() < _epsilon) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  static String _formatDuration(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final hours = safe ~/ 3600;
    final minutes = (safe % 3600) ~/ 60;
    final seconds = safe % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String _formatPace(double secondsPerKm) {
    if (!secondsPerKm.isFinite || secondsPerKm <= 0) return '--:-- /km';
    final total = secondsPerKm.round();
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
  }
}
