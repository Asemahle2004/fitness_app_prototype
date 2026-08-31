import 'package:fitness_app_prototype/body_progress_engine.dart';
import 'package:fitness_app_prototype/body_progress_store.dart';
import 'package:flutter_test/flutter_test.dart';

BodyProgressEntry entry({
  required String id,
  required DateTime date,
  double? weight,
  double? waist,
  double? bodyFat,
}) {
  return BodyProgressEntry(
    id: id,
    recordedAt: date,
    weightKg: weight,
    waistCm: waist,
    bodyFatPercent: bodyFat,
  );
}

void main() {
  test('available metrics only include values that were logged', () {
    final entries = [
      entry(
        id: 'a',
        date: DateTime(2026, 8, 1),
        weight: 80,
        waist: 90,
      ),
    ];

    expect(
      BodyProgressEngine.availableMetrics(entries),
      [BodyMetric.weight, BodyMetric.waist],
    );
  });

  test('series uses latest measurement when same metric is logged twice in a day', () {
    final entries = [
      entry(id: 'a', date: DateTime(2026, 8, 1, 8), weight: 80),
      entry(id: 'b', date: DateTime(2026, 8, 1, 19), weight: 79.5),
      entry(id: 'c', date: DateTime(2026, 8, 8, 8), weight: 79),
    ];

    final points = BodyProgressEngine.seriesFor(entries, BodyMetric.weight);

    expect(points.length, 2);
    expect(points.first.value, 79.5);
    expect(points.last.value, 79);
  });

  test('absolute and percent change compare first and latest training dates', () {
    final points = [
      BodyProgressPoint(date: DateTime(2026, 8, 1), value: 100),
      BodyProgressPoint(date: DateTime(2026, 8, 15), value: 95),
    ];

    expect(BodyProgressEngine.absoluteChange(points), -5);
    expect(BodyProgressEngine.percentChange(points), -5);
  });

  test('latestWithMetric ignores newer entries without that metric', () {
    final entries = [
      entry(id: 'a', date: DateTime(2026, 8, 1), waist: 90),
      entry(id: 'b', date: DateTime(2026, 8, 5), weight: 80),
      entry(id: 'c', date: DateTime(2026, 8, 3), waist: 88),
    ];

    final latest = BodyProgressEngine.latestWithMetric(
      entries,
      BodyMetric.waist,
    );

    expect(latest?.id, 'c');
    expect(latest?.waistCm, 88);
  });
}
