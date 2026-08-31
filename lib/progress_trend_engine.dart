import 'exercise_performance_store.dart';

enum ProgressMetric { load, reps, volume, time }

extension ProgressMetricLabel on ProgressMetric {
  String get label => switch (this) {
        ProgressMetric.load => 'Load',
        ProgressMetric.reps => 'Reps',
        ProgressMetric.volume => 'Volume',
        ProgressMetric.time => 'Time',
      };

  String get unit => switch (this) {
        ProgressMetric.load => 'kg',
        ProgressMetric.reps => 'reps',
        ProgressMetric.volume => 'kg·reps',
        ProgressMetric.time => 'sec',
      };
}

class ProgressPoint {
  final DateTime date;
  final double value;

  const ProgressPoint({required this.date, required this.value});
}

class ExerciseProgressSeries {
  final String exerciseName;
  final Map<ProgressMetric, List<ProgressPoint>> points;

  const ExerciseProgressSeries({
    required this.exerciseName,
    required this.points,
  });

  List<ProgressMetric> get availableMetrics => ProgressMetric.values
      .where((metric) => (points[metric] ?? const <ProgressPoint>[]).isNotEmpty)
      .toList(growable: false);

  List<ProgressPoint> forMetric(ProgressMetric metric) =>
      points[metric] ?? const <ProgressPoint>[];
}

class ProgressTrendEngine {
  static ExerciseProgressSeries build(
    String exerciseName,
    Iterable<ExerciseSetPerformance> source,
  ) {
    final lower = exerciseName.trim().toLowerCase();
    final records = source
        .where(
          (record) =>
              !record.isDropSet && record.exerciseName.trim().toLowerCase() == lower,
        )
        .toList(growable: false)
      ..sort((a, b) => a.performedAt.compareTo(b.performedAt));

    final days = <DateTime, List<ExerciseSetPerformance>>{};
    for (final record in records) {
      final local = record.performedAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      days.putIfAbsent(day, () => <ExerciseSetPerformance>[]).add(record);
    }

    final load = <ProgressPoint>[];
    final reps = <ProgressPoint>[];
    final volume = <ProgressPoint>[];
    final time = <ProgressPoint>[];

    final dates = days.keys.toList()..sort();
    for (final date in dates) {
      final dayRecords = days[date]!;

      final loads = dayRecords
          .map((record) => record.weightKg)
          .whereType<double>()
          .where((value) => value > 0)
          .toList(growable: false);
      if (loads.isNotEmpty) {
        load.add(ProgressPoint(date: date, value: loads.reduce(_max)));
      }

      final repValues = dayRecords
          .map((record) => record.reps)
          .whereType<int>()
          .where((value) => value > 0)
          .toList(growable: false);
      if (repValues.isNotEmpty) {
        reps.add(
          ProgressPoint(
            date: date,
            value: repValues.reduce((a, b) => a > b ? a : b).toDouble(),
          ),
        );
      }

      final dailyVolume = dayRecords.fold<double>(
        0,
        (sum, record) => sum + record.volumeKg,
      );
      if (dailyVolume > 0) {
        volume.add(ProgressPoint(date: date, value: dailyVolume));
      }

      final durations = dayRecords
          .map((record) => record.durationSeconds)
          .whereType<int>()
          .where((value) => value > 0)
          .toList(growable: false);
      if (durations.isNotEmpty) {
        time.add(
          ProgressPoint(
            date: date,
            value: durations.reduce((a, b) => a > b ? a : b).toDouble(),
          ),
        );
      }
    }

    return ExerciseProgressSeries(
      exerciseName: exerciseName,
      points: {
        ProgressMetric.load: load,
        ProgressMetric.reps: reps,
        ProgressMetric.volume: volume,
        ProgressMetric.time: time,
      },
    );
  }

  static double _max(double a, double b) => a > b ? a : b;

  static double? percentChange(List<ProgressPoint> points) {
    if (points.length < 2 || points.first.value == 0) return null;
    return ((points.last.value - points.first.value) / points.first.value) * 100;
  }
}
