import 'package:fitness_app_prototype/run_tracking_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save and reload preserves run details', () async {
    final record = RunRecord(
      id: 'run-a',
      startedAt: DateTime(2026, 8, 31, 7, 30),
      durationSeconds: 1800,
      distanceMeters: 5000,
      source: 'gps',
      notes: 'Easy run',
    );

    await RunTrackingStore.save(record);
    final loaded = await RunTrackingStore.load();

    expect(loaded.length, 1);
    expect(loaded.first.id, 'run-a');
    expect(loaded.first.distanceMeters, 5000);
    expect(loaded.first.durationSeconds, 1800);
    expect(loaded.first.source, 'gps');
    expect(loaded.first.notes, 'Easy run');
  });

  test('saving same id replaces record instead of duplicating it', () async {
    final original = RunRecord(
      id: 'run-a',
      startedAt: DateTime(2026, 8, 31),
      durationSeconds: 1200,
      distanceMeters: 3000,
    );
    await RunTrackingStore.save(original);
    await RunTrackingStore.save(original.copyWith(distanceMeters: 3200));

    final loaded = await RunTrackingStore.load();
    expect(loaded.length, 1);
    expect(loaded.first.distanceMeters, 3200);
  });

  test('delete removes a saved run', () async {
    await RunTrackingStore.save(RunRecord(
      id: 'run-a',
      startedAt: DateTime(2026, 8, 31),
      durationSeconds: 1200,
      distanceMeters: 3000,
    ));

    await RunTrackingStore.delete('run-a');
    expect(await RunTrackingStore.load(), isEmpty);
  });
}
