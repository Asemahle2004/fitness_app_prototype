import 'package:fitness_app_prototype/adaptive_programme_engine.dart';
import 'package:fitness_app_prototype/programme_adaptation_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AdaptiveWeekSignals signals({
  int planned = 4,
  int completed = 4,
  int skipped = 0,
  int readinessCheckIns = 3,
  double? averageReadiness = 75,
  int lowReadiness = 0,
  int progressionWins = 0,
  int personalRecords = 0,
  int frictionSwaps = 0,
  int painSwaps = 0,
  int runs = 0,
  double runDistanceKm = 0,
  bool runningImproved = false,
}) {
  return AdaptiveWeekSignals(
    plannedSessions: planned,
    completedSessions: completed,
    skippedSessions: skipped,
    readinessCheckIns: readinessCheckIns,
    averageReadiness: averageReadiness,
    lowReadinessCheckIns: lowReadiness,
    progressionWins: progressionWins,
    personalRecords: personalRecords,
    frictionSwaps: frictionSwaps,
    painSwaps: painSwaps,
    runs: runs,
    runDistanceKm: runDistanceKm,
    runningImproved: runningImproved,
  );
}

void main() {
  group('AdaptiveProgrammeEngine decisions', () {
    test('progresses after strong adherence, readiness and progress evidence', () {
      final decision = AdaptiveProgrammeEngine.decide(
        signals(progressionWins: 2),
      );

      expect(decision.mode, AdaptiveWeekMode.progress);
      expect(decision.rationale, contains('100%'));
      expect(decision.rationale, contains('progression'));
    });

    test('PR evidence can support a progress week', () {
      final decision = AdaptiveProgrammeEngine.decide(
        signals(personalRecords: 1),
      );

      expect(decision.mode, AdaptiveWeekMode.progress);
    });

    test('running improvement can support a progress week', () {
      final decision = AdaptiveProgrammeEngine.decide(
        signals(
          runs: 3,
          runDistanceKm: 18,
          runningImproved: true,
        ),
      );

      expect(decision.mode, AdaptiveWeekMode.progress);
      expect(decision.rationale, contains('running trend improved'));
    });

    test('holds when adherence is good but there is no reason to progress', () {
      final decision = AdaptiveProgrammeEngine.decide(signals());
      expect(decision.mode, AdaptiveWeekMode.hold);
    });

    test('consolidates a week with low completion', () {
      final decision = AdaptiveProgrammeEngine.decide(
        signals(completed: 2, skipped: 2),
      );

      expect(decision.mode, AdaptiveWeekMode.consolidate);
      expect(
        AdaptiveProgrammeEngine.targetSessionCount(
          mode: decision.mode,
          baselineSessions: 4,
        ),
        3,
      );
    });

    test('consolidates repeated equipment or difficulty friction', () {
      final decision = AdaptiveProgrammeEngine.decide(
        signals(frictionSwaps: 3),
      );

      expect(decision.mode, AdaptiveWeekMode.consolidate);
    });

    test('uses recovery mode after repeated low readiness', () {
      final decision = AdaptiveProgrammeEngine.decide(
        signals(
          averageReadiness: 45,
          lowReadiness: 3,
          readinessCheckIns: 3,
        ),
      );

      expect(decision.mode, AdaptiveWeekMode.recovery);
      expect(
        AdaptiveProgrammeEngine.targetDuration(
          mode: decision.mode,
          baselineDuration: '60 min',
        ),
        '45 min',
      );
      expect(
        AdaptiveProgrammeEngine.targetSessionCount(
          mode: decision.mode,
          baselineSessions: 4,
        ),
        3,
      );
    });

    test('uses recovery mode after repeated pain/discomfort swaps', () {
      final decision = AdaptiveProgrammeEngine.decide(
        signals(painSwaps: 2, progressionWins: 3),
      );

      expect(decision.mode, AdaptiveWeekMode.recovery);
    });

    test('one pain swap prevents automatic progression without overreacting', () {
      final decision = AdaptiveProgrammeEngine.decide(
        signals(painSwaps: 1, progressionWins: 3),
      );

      expect(decision.mode, AdaptiveWeekMode.hold);
    });

    test('progress mode never adds sessions beyond profile baseline', () {
      expect(
        AdaptiveProgrammeEngine.targetSessionCount(
          mode: AdaptiveWeekMode.progress,
          baselineSessions: 5,
        ),
        5,
      );
    });

    test('recovery duration does not go below a 20 minute profile', () {
      expect(
        AdaptiveProgrammeEngine.targetDuration(
          mode: AdaptiveWeekMode.recovery,
          baselineDuration: '20 min',
        ),
        '20 min',
      );
    });
  });

  group('ProgrammeAdaptationStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('records one event per week/session/type', () async {
      await ProgrammeAdaptationStore.resetForWeek(
        2,
        startedAt: DateTime(2026, 9, 1),
        clearEvents: true,
      );

      await ProgrammeAdaptationStore.recordSessionEvent(
        weekNumber: 2,
        sessionIndex: 0,
        sessionTitle: 'Full Body A',
        type: ProgrammeSessionEventType.skipped,
        recordedAt: DateTime(2026, 9, 2, 8),
      );
      await ProgrammeAdaptationStore.recordSessionEvent(
        weekNumber: 2,
        sessionIndex: 0,
        sessionTitle: 'Full Body A',
        type: ProgrammeSessionEventType.skipped,
        recordedAt: DateTime(2026, 9, 2, 9),
      );

      final events = await ProgrammeAdaptationStore.eventsForWeek(2);
      expect(events.length, 1);
      expect(events.single.recordedAt.hour, 9);
      expect(events.single.type, ProgrammeSessionEventType.skipped);
    });

    test('completed and skipped are distinct events for the same slot', () async {
      await ProgrammeAdaptationStore.resetForWeek(3, clearEvents: true);

      await ProgrammeAdaptationStore.recordSessionEvent(
        weekNumber: 3,
        sessionIndex: 1,
        sessionTitle: 'Lower Body',
        type: ProgrammeSessionEventType.skipped,
      );
      await ProgrammeAdaptationStore.recordSessionEvent(
        weekNumber: 3,
        sessionIndex: 1,
        sessionTitle: 'Lower Body',
        type: ProgrammeSessionEventType.completed,
      );

      final events = await ProgrammeAdaptationStore.eventsForWeek(3);
      expect(events.length, 2);
      expect(
        events.map((event) => event.type).toSet(),
        {
          ProgrammeSessionEventType.skipped,
          ProgrammeSessionEventType.completed,
        },
      );
    });

    test('reset starts the next adaptive window at the supplied time', () async {
      final startedAt = DateTime(2026, 9, 8, 7, 30);
      await ProgrammeAdaptationStore.resetForWeek(
        4,
        startedAt: startedAt,
        previousMode: AdaptiveWeekMode.hold.name,
        previousSummary: 'Hold the current dose.',
      );

      final state = await ProgrammeAdaptationStore.loadState();
      expect(state, isNotNull);
      expect(state!.weekNumber, 4);
      expect(state.startedAt, startedAt);
      expect(state.previousMode, 'hold');
    });
  });
}
