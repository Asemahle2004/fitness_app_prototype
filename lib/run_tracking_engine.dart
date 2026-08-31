import 'run_tracking_store.dart';

enum RunProgressMetric { distance, pace }

class RunProgressPoint {
  final DateTime date;
  final double value;

  const RunProgressPoint({required this.date, required this.value});
}

class RunSummary {
  final int runs;
  final double distanceMeters;
  final int durationSeconds;

  const RunSummary({
    required this.runs,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  double get distanceKm => distanceMeters / 1000;
}

class RunTrackingEngine {
  static double? paceSecondsPerKm({
    required double distanceMeters,
    required int durationSeconds,
  }) {
    if (distanceMeters <= 0 || durationSeconds <= 0) return null;
    return durationSeconds / (distanceMeters / 1000);
  }

  static String formatPace(double? secondsPerKm) {
    if (secondsPerKm == null || !secondsPerKm.isFinite || secondsPerKm <= 0) {
      return '--:-- /km';
    }
    final totalSeconds = secondsPerKm.round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
  }

  static String formatDuration(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final hours = safe ~/ 3600;
    final minutes = (safe % 3600) ~/ 60;
    final seconds = safe % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static RunSummary summary(Iterable<RunRecord> runs) {
    var count = 0;
    var distance = 0.0;
    var duration = 0;
    for (final run in runs) {
      count += 1;
      distance += run.distanceMeters;
      duration += run.durationSeconds;
    }
    return RunSummary(
      runs: count,
      distanceMeters: distance,
      durationSeconds: duration,
    );
  }

  static List<RunRecord> since(
    Iterable<RunRecord> runs,
    DateTime startInclusive,
  ) {
    return runs
        .where((run) => !run.startedAt.isBefore(startInclusive))
        .toList(growable: false);
  }

  static RunRecord? bestPace(Iterable<RunRecord> runs) {
    RunRecord? best;
    for (final run in runs) {
      final pace = run.averagePaceSecondsPerKm;
      if (pace == null || run.distanceMeters < 500) continue;
      final currentBest = best?.averagePaceSecondsPerKm;
      if (currentBest == null || pace < currentBest) best = run;
    }
    return best;
  }

  static RunRecord? longestRun(Iterable<RunRecord> runs) {
    RunRecord? longest;
    for (final run in runs) {
      if (longest == null || run.distanceMeters > longest.distanceMeters) {
        longest = run;
      }
    }
    return longest;
  }

  static List<RunProgressPoint> seriesFor(
    Iterable<RunRecord> runs,
    RunProgressMetric metric,
  ) {
    final sorted = runs.toList(growable: false)
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final points = <RunProgressPoint>[];
    for (final run in sorted) {
      if (metric == RunProgressMetric.distance) {
        if (run.distanceMeters <= 0) continue;
        points.add(RunProgressPoint(
          date: run.startedAt,
          value: run.distanceKm,
        ));
      } else {
        final pace = run.averagePaceSecondsPerKm;
        if (pace == null || run.distanceMeters < 500) continue;
        points.add(RunProgressPoint(
          date: run.startedAt,
          value: pace / 60,
        ));
      }
    }
    return points;
  }
}
