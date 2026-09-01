import 'package:fitness_app_prototype/exercise_performance_store.dart';
import 'package:fitness_app_prototype/personal_record_engine.dart';
import 'package:fitness_app_prototype/run_tracking_store.dart';
import 'package:flutter_test/flutter_test.dart';

ExerciseSetPerformance setRecord({
  required String exercise,
  required DateTime at,
  int? reps,
  double? weight,
  int? duration,
  bool drop = false,
  int setNumber = 1,
}) {
  return ExerciseSetPerformance(
    workoutTitle: 'Test workout',
    exerciseName: exercise,
    setNumber: setNumber,
    reps: reps,
    weightKg: weight,
    durationSeconds: duration,
    setType: drop ? 'drop' : 'normal',
    dropNumber: drop ? 1 : null,
    performedAt: at,
  );
}

RunRecord runRecord({
  required String id,
  required DateTime at,
  required double km,
  required int minutes,
}) {
  return RunRecord(
    id: id,
    startedAt: at,
    durationSeconds: minutes * 60,
    distanceMeters: km * 1000,
  );
}

PersonalRecordAchievement recordFor(
  Iterable<PersonalRecordAchievement> records,
  PersonalRecordMetric metric,
  String subject,
) {
  return records.firstWhere(
    (record) =>
        record.metric == metric &&
        record.subject.toLowerCase() == subject.toLowerCase(),
  );
}

void main() {
  test('current strength records keep best load reps and set volume', () {
    final sets = [
      setRecord(
        exercise: 'Bench Press',
        at: DateTime(2026, 8, 1),
        reps: 8,
        weight: 50,
      ),
      setRecord(
        exercise: 'Bench Press',
        at: DateTime(2026, 8, 5),
        reps: 10,
        weight: 50,
      ),
      setRecord(
        exercise: 'Bench Press',
        at: DateTime(2026, 8, 10),
        reps: 6,
        weight: 55,
      ),
    ];

    final records = PersonalRecordEngine.currentRecords(sets: sets, runs: const []);

    expect(
      recordFor(records, PersonalRecordMetric.heaviestLoad, 'Bench Press').value,
      55,
    );
    expect(
      recordFor(records, PersonalRecordMetric.mostReps, 'Bench Press').value,
      10,
    );
    expect(
      recordFor(records, PersonalRecordMetric.setVolume, 'Bench Press').value,
      500,
    );
  });

  test('drop sets do not create or replace strength personal records', () {
    final sets = [
      setRecord(
        exercise: 'Curl',
        at: DateTime(2026, 8, 1),
        reps: 10,
        weight: 15,
      ),
      setRecord(
        exercise: 'Curl',
        at: DateTime(2026, 8, 2),
        reps: 30,
        weight: 50,
        drop: true,
      ),
    ];

    final records = PersonalRecordEngine.currentRecords(sets: sets, runs: const []);
    expect(recordFor(records, PersonalRecordMetric.heaviestLoad, 'Curl').value, 15);
    expect(recordFor(records, PersonalRecordMetric.mostReps, 'Curl').value, 10);
    expect(
      PersonalRecordEngine.newSetRecords(current: sets.last, previous: [sets.first]),
      isEmpty,
    );
  });

  test('timed work tracks the longest duration', () {
    final sets = [
      setRecord(
        exercise: 'Plank',
        at: DateTime(2026, 8, 1),
        duration: 45,
      ),
      setRecord(
        exercise: 'Plank',
        at: DateTime(2026, 8, 5),
        duration: 60,
      ),
    ];

    final records = PersonalRecordEngine.currentRecords(sets: sets, runs: const []);
    expect(
      recordFor(records, PersonalRecordMetric.timedDuration, 'Plank').value,
      60,
    );
  });

  test('running records keep longest run and fastest qualifying pace', () {
    final runs = [
      runRecord(id: 'one', at: DateTime(2026, 8, 1), km: 5, minutes: 25),
      runRecord(id: 'two', at: DateTime(2026, 8, 5), km: 8, minutes: 48),
    ];

    final records = PersonalRecordEngine.currentRecords(sets: const [], runs: runs);
    expect(
      recordFor(records, PersonalRecordMetric.longestRun, 'Running').value,
      8000,
    );
    expect(
      recordFor(records, PersonalRecordMetric.fastestPace, 'Running').value,
      300,
    );
  });

  test('fastest pace ignores runs under 500 metres', () {
    final runs = [
      RunRecord(
        id: 'short',
        startedAt: DateTime(2026, 8, 1),
        durationSeconds: 20,
        distanceMeters: 100,
      ),
      runRecord(id: 'normal', at: DateTime(2026, 8, 2), km: 1, minutes: 6),
    ];

    final records = PersonalRecordEngine.currentRecords(sets: const [], runs: runs);
    expect(
      recordFor(records, PersonalRecordMetric.fastestPace, 'Running').value,
      360,
    );
  });

  test('new weighted set reports every metric it genuinely improves', () {
    final previous = setRecord(
      exercise: 'Squat',
      at: DateTime(2026, 8, 1),
      reps: 8,
      weight: 50,
    );
    final current = setRecord(
      exercise: 'Squat',
      at: DateTime(2026, 8, 10),
      reps: 9,
      weight: 52.5,
    );

    final achievements = PersonalRecordEngine.newSetRecords(
      current: current,
      previous: [previous],
    );

    expect(
      achievements.map((record) => record.metric).toSet(),
      {
        PersonalRecordMetric.heaviestLoad,
        PersonalRecordMetric.mostReps,
        PersonalRecordMetric.setVolume,
      },
    );
  });

  test('equal performance is not treated as a new record', () {
    final previous = setRecord(
      exercise: 'Row',
      at: DateTime(2026, 8, 1),
      reps: 10,
      weight: 30,
    );
    final current = setRecord(
      exercise: 'Row',
      at: DateTime(2026, 8, 2),
      reps: 10,
      weight: 30,
    );

    expect(
      PersonalRecordEngine.newSetRecords(
        current: current,
        previous: [previous],
      ),
      isEmpty,
    );
  });

  test('record history preserves baseline and later breakthroughs', () {
    final sets = [
      setRecord(
        exercise: 'Deadlift',
        at: DateTime(2026, 8, 1),
        reps: 5,
        weight: 80,
      ),
      setRecord(
        exercise: 'Deadlift',
        at: DateTime(2026, 8, 5),
        reps: 5,
        weight: 90,
      ),
    ];

    final history = PersonalRecordEngine.recordHistory(sets: sets, runs: const []);
    final loadHistory = history
        .where((record) => record.metric == PersonalRecordMetric.heaviestLoad)
        .toList();

    expect(loadHistory.length, 2);
    expect(loadHistory.first.value, 90);
    expect(loadHistory.first.previousValue, 80);
    expect(loadHistory.last.isBaseline, isTrue);
  });

  test('backdated run only celebrates if it beats current all-time best', () {
    final existing = [
      runRecord(id: 'current-best', at: DateTime(2026, 8, 20), km: 10, minutes: 60),
    ];
    final backdated = runRecord(
      id: 'older',
      at: DateTime(2026, 7, 1),
      km: 8,
      minutes: 40,
    );

    final achievements = PersonalRecordEngine.newRunRecords(
      current: backdated,
      previous: existing,
    );

    expect(
      achievements.any((record) => record.metric == PersonalRecordMetric.longestRun),
      isFalse,
    );
    expect(
      achievements.any((record) => record.metric == PersonalRecordMetric.fastestPace),
      isTrue,
    );
  });
}
