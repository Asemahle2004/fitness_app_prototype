import 'body_progress_store.dart';

class BodyProgressPoint {
  final DateTime date;
  final double value;

  const BodyProgressPoint({required this.date, required this.value});
}

class BodyProgressEngine {
  static List<BodyMetric> availableMetrics(
    Iterable<BodyProgressEntry> entries,
  ) {
    return BodyMetric.values
        .where(
          (metric) => entries.any((entry) => entry.valueFor(metric) != null),
        )
        .toList(growable: false);
  }

  static List<BodyProgressPoint> seriesFor(
    Iterable<BodyProgressEntry> entries,
    BodyMetric metric,
  ) {
    final byDay = <DateTime, BodyProgressEntry>{};
    for (final entry in entries) {
      if (entry.valueFor(metric) == null) continue;
      final day = DateTime(
        entry.recordedAt.year,
        entry.recordedAt.month,
        entry.recordedAt.day,
      );
      final existing = byDay[day];
      if (existing == null || entry.recordedAt.isAfter(existing.recordedAt)) {
        byDay[day] = entry;
      }
    }

    final days = byDay.keys.toList()..sort();
    return days
        .map(
          (day) => BodyProgressPoint(
            date: day,
            value: byDay[day]!.valueFor(metric)!,
          ),
        )
        .toList(growable: false);
  }

  static double? absoluteChange(List<BodyProgressPoint> points) {
    if (points.length < 2) return null;
    return points.last.value - points.first.value;
  }

  static double? percentChange(List<BodyProgressPoint> points) {
    if (points.length < 2 || points.first.value == 0) return null;
    return ((points.last.value - points.first.value) / points.first.value) * 100;
  }

  static BodyProgressEntry? latestWithMetric(
    Iterable<BodyProgressEntry> entries,
    BodyMetric metric,
  ) {
    final matches = entries
        .where((entry) => entry.valueFor(metric) != null)
        .toList(growable: false)
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return matches.isEmpty ? null : matches.first;
  }
}
