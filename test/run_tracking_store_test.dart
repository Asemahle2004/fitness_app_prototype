import 'dart:convert';

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

  test('guided metadata and perceived effort survive persistence', () async {
    final record = RunRecord(
      id: 'guided-a',
      startedAt: DateTime(2026, 9, 1, 18),
      durationSeconds: 1800,
      distanceMeters: 3200,
      source: 'gps_guided',
      guidedPlanId: 'run_walk_foundation',
      guidedPlannedSeconds: 1800,
      guidedCompleted: true,
      perceivedEffort: 'right',
    );

    await RunTrackingStore.save(record);
    final loaded = (await RunTrackingStore.load()).single;

    expect(loaded.isGuided, isTrue);
    expect(loaded.guidedPlanId, 'run_walk_foundation');
    expect(loaded.guidedPlannedSeconds, 1800);
    expect(loaded.guidedCompleted, isTrue);
    expect(loaded.perceivedEffort, 'right');
    expect(loaded.guidedCompletionRatio, 1);
  });

  test('old run JSON without adaptive fields remains readable', () {
    final old = RunRecord.fromJson(
      jsonDecode(
        '{"id":"old","started_at":"2026-08-20T07:00:00.000","duration_seconds":1200,"distance_meters":2500,"source":"gps"}',
      ) as Map<String, dynamic>,
    );

    expect(old.id, 'old');
    expect(old.guidedPlanId, isNull);
    expect(old.guidedCompleted, isNull);
    expect(old.perceivedEffort, isNull);
    expect(old.isGuided, isFalse);
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
