import 'package:fitness_app_prototype/run_tracking_engine.dart';
import 'package:fitness_app_prototype/run_tracking_store.dart';
import 'package:flutter_test/flutter_test.dart';

RunRecord run({
  required String id,
  required DateTime date,
  required double meters,
  required int seconds,
}) {
  return RunRecord(
    id: id,
    startedAt: date,
    distanceMeters: meters,
    durationSeconds: seconds,
  );
}

void main() {
  test('pace calculation returns seconds per kilometre', () {
    expect(
      RunTrackingEngine.paceSecondsPerKm(
        distanceMeters: 5000,
        durationSeconds: 1500,
      ),
      300,
    );
    expect(RunTrackingEngine.formatPace(300), '5:00 /km');
  });

  test('summary totals runs distance and duration', () {
    final summary = RunTrackingEngine.summary([
      run(
        id: 'a',
        date: DateTime(2026, 8, 1),
        meters: 5000,
        seconds: 1500,
      ),
      run(
        id: 'b',
        date: DateTime(2026, 8, 2),
        meters: 3000,
        seconds: 1000,
      ),
    ]);

    expect(summary.runs, 2);
    expect(summary.distanceMeters, 8000);
    expect(summary.durationSeconds, 2500);
  });

  test('best pace ignores very short runs', () {
    final best = RunTrackingEngine.bestPace([
      run(
        id: 'short',
        date: DateTime(2026, 8, 1),
        meters: 100,
        seconds: 20,
      ),
      run(
        id: 'five',
        date: DateTime(2026, 8, 2),
        meters: 5000,
        seconds: 1500,
      ),
      run(
        id: 'three',
        date: DateTime(2026, 8, 3),
        meters: 3000,
        seconds: 840,
      ),
    ]);

    expect(best?.id, 'three');
  });

  test('distance and pace series are chronological', () {
    final runs = [
      run(
        id: 'later',
        date: DateTime(2026, 8, 10),
        meters: 6000,
        seconds: 1800,
      ),
      run(
        id: 'earlier',
        date: DateTime(2026, 8, 1),
        meters: 5000,
        seconds: 1500,
      ),
    ];

    final distance = RunTrackingEngine.seriesFor(
      runs,
      RunProgressMetric.distance,
    );
    final pace = RunTrackingEngine.seriesFor(
      runs,
      RunProgressMetric.pace,
    );

    expect(distance.first.date, DateTime(2026, 8, 1));
    expect(distance.last.value, 6);
    expect(pace.first.value, 5);
  });
}
