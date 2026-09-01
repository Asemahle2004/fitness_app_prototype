import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise_performance_store.dart';
import 'personal_record_engine.dart';
import 'programme_adaptation_store.dart';
import 'programme_engine.dart';
import 'run_tracking_store.dart';
import 'training_store.dart';

enum AdaptiveWeekMode { progress, hold, consolidate, recovery }

extension AdaptiveWeekModeDetails on AdaptiveWeekMode {
  String get label {
    switch (this) {
      case AdaptiveWeekMode.progress:
        return 'Progress';
      case AdaptiveWeekMode.hold:
        return 'Hold';
      case AdaptiveWeekMode.consolidate:
        return 'Consolidate';
      case AdaptiveWeekMode.recovery:
        return 'Recovery';
    }
  }
}

class AdaptiveWeekSignals {
  final int plannedSessions;
  final int completedSessions;
  final int skippedSessions;
  final int readinessCheckIns;
  final double? averageReadiness;
  final int lowReadinessCheckIns;
  final int progressionWins;
  final int personalRecords;
  final int frictionSwaps;
  final int painSwaps;
  final int runs;
  final double runDistanceKm;
  final bool runningImproved;

  const AdaptiveWeekSignals({
    required this.plannedSessions,
    required this.completedSessions,
    required this.skippedSessions,
    required this.readinessCheckIns,
    required this.averageReadiness,
    required this.lowReadinessCheckIns,
    required this.progressionWins,
    required this.personalRecords,
    required this.frictionSwaps,
    required this.painSwaps,
    required this.runs,
    required this.runDistanceKm,
    required this.runningImproved,
  });

  double get completionRate {
    if (plannedSessions <= 0) return 0;
    return (completedSessions / plannedSessions).clamp(0.0, 1.0).toDouble();
  }
}

class AdaptiveWeekDecision {
  final AdaptiveWeekMode mode;
  final String summary;
  final String rationale;

  const AdaptiveWeekDecision({
    required this.mode,
    required this.summary,
    required this.rationale,
  });
}

class AdaptiveProgrammeResult {
  final GeneratedProgramme programme;
  final AdaptiveWeekDecision decision;
  final AdaptiveWeekSignals signals;

  const AdaptiveProgrammeResult({
    required this.programme,
    required this.decision,
    required this.signals,
  });
}

class AdaptiveProgrammeEngine {
  static AdaptiveWeekDecision decide(AdaptiveWeekSignals signals) {
    final readinessLow = signals.readinessCheckIns >= 2 &&
        (signals.averageReadiness ?? 100) < 50;
    final repeatedLowReadiness = signals.lowReadinessCheckIns >= 2 &&
        (signals.averageReadiness ?? 100) < 60;

    if (signals.painSwaps >= 2 || readinessLow || repeatedLowReadiness) {
      return AdaptiveWeekDecision(
        mode: AdaptiveWeekMode.recovery,
        summary: 'LeanIt is reducing next week to protect recovery.',
        rationale: _rationale(signals),
      );
    }

    if (signals.completionRate < 0.75 ||
        signals.skippedSessions >= 2 ||
        signals.frictionSwaps >= 3) {
      return AdaptiveWeekDecision(
        mode: AdaptiveWeekMode.consolidate,
        summary: 'LeanIt is simplifying next week so the plan is easier to complete.',
        rationale: _rationale(signals),
      );
    }

    final positiveEvidence = signals.progressionWins >= 2 ||
        signals.personalRecords >= 1 ||
        signals.runningImproved;
    final readinessSupportsProgress = signals.averageReadiness == null ||
        signals.averageReadiness! >= 65;

    if (signals.completionRate >= 0.90 &&
        positiveEvidence &&
        readinessSupportsProgress &&
        signals.painSwaps == 0 &&
        signals.frictionSwaps <= 1) {
      return AdaptiveWeekDecision(
        mode: AdaptiveWeekMode.progress,
        summary:
            'LeanIt is keeping your schedule and allowing measured progression next week.',
        rationale: _rationale(signals),
      );
    }

    return AdaptiveWeekDecision(
      mode: AdaptiveWeekMode.hold,
      summary: 'LeanIt is holding the current training dose for another week.',
      rationale: _rationale(signals),
    );
  }

  static String _rationale(AdaptiveWeekSignals signals) {
    final parts = <String>[
      '${(signals.completionRate * 100).round()}% of planned sessions completed',
    ];
    if (signals.skippedSessions > 0) {
      parts.add('${signals.skippedSessions} explicitly skipped');
    }
    if (signals.averageReadiness != null) {
      parts.add('average readiness ${signals.averageReadiness!.round()}/100');
    }
    if (signals.progressionWins > 0) {
      parts.add('${signals.progressionWins} exercise progression signal(s)');
    }
    if (signals.personalRecords > 0) {
      parts.add('${signals.personalRecords} new PR signal(s)');
    }
    if (signals.painSwaps > 0) {
      parts.add('${signals.painSwaps} pain/discomfort swap(s)');
    }
    if (signals.frictionSwaps > 0) {
      parts.add('${signals.frictionSwaps} difficulty/equipment swap(s)');
    }
    if (signals.runs > 0) {
      final distance = signals.runDistanceKm.toStringAsFixed(1);
      parts.add('${signals.runs} run(s), $distance km');
    }
    if (signals.runningImproved) parts.add('running trend improved');
    return parts.join(' • ');
  }

  static int targetSessionCount({
    required AdaptiveWeekMode mode,
    required int baselineSessions,
  }) {
    if (baselineSessions <= 1) return math.max(1, baselineSessions);
    if (mode == AdaptiveWeekMode.consolidate ||
        mode == AdaptiveWeekMode.recovery) {
      return math.max(1, baselineSessions - 1);
    }
    return baselineSessions;
  }

  static String targetDuration({
    required AdaptiveWeekMode mode,
    required String baselineDuration,
  }) {
    if (mode != AdaptiveWeekMode.recovery) return baselineDuration;
    switch (baselineDuration) {
      case '75+ min':
        return '60 min';
      case '60 min':
        return '45 min';
      case '45 min':
        return '30 min';
      case '30 min':
        return '20 min';
      default:
        return baselineDuration;
    }
  }
}

class AdaptiveProgrammeService {
  final SupabaseClient client;

  const AdaptiveProgrammeService(this.client);

  static const _weekOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  Future<AdaptiveProgrammeResult> buildNextWeek({
    required Map<String, dynamic> profile,
    required GeneratedProgramme currentProgramme,
    required int currentWeek,
  }) async {
    final state = await ProgrammeAdaptationStore.ensureWeek(currentWeek);
    final now = DateTime.now();
    final windowStart = state.startedAt;
    final windowLength = now.difference(windowStart);
    final comparisonLength = windowLength < const Duration(days: 2)
        ? const Duration(days: 2)
        : windowLength;
    final previousStart = windowStart.subtract(comparisonLength);

    final events = await ProgrammeAdaptationStore.eventsForWeek(currentWeek);
    final workouts = await TrainingStore.loadWorkouts();
    final readiness = await TrainingStore.loadReadiness();
    final sets = await ExercisePerformanceStore(client).loadAll();
    final runs = await RunTrackingStore.load();
    final swapSignals = await _swapSignals(windowStart);

    final currentWorkouts = workouts
        .where((record) => !record.completedAt.isBefore(windowStart))
        .toList(growable: false);
    final matchingWorkoutCount = currentWorkouts.where((record) {
      final title = record.title.toLowerCase();
      return currentProgramme.sessions.any(
        (session) => title.contains(session.title.toLowerCase()),
      );
    }).length;

    final completedEvents = events
        .where((event) => event.type == ProgrammeSessionEventType.completed)
        .length;
    final skippedEvents = events
        .where((event) => event.type == ProgrammeSessionEventType.skipped)
        .length;
    final planned = currentProgramme.sessions.length;
    final completed = math.min(
      planned,
      math.max(completedEvents, matchingWorkoutCount),
    );

    final readinessInWindow = readiness
        .where((record) => !record.recordedAt.isBefore(windowStart))
        .toList(growable: false);
    final averageReadiness = readinessInWindow.isEmpty
        ? null
        : readinessInWindow
                .map((record) => record.score)
                .reduce((a, b) => a + b) /
            readinessInWindow.length;
    final lowReadiness =
        readinessInWindow.where((record) => record.score < 60).length;

    final currentSets = sets
        .where((record) => !record.performedAt.isBefore(windowStart))
        .toList(growable: false);
    final previousSets = sets
        .where((record) =>
            !record.performedAt.isBefore(previousStart) &&
            record.performedAt.isBefore(windowStart))
        .toList(growable: false);
    final progressionWins = _progressionWins(currentSets, previousSets);

    final recordHistory = PersonalRecordEngine.recordHistory(sets: sets, runs: runs);
    final personalRecords = recordHistory
        .where((record) =>
            !record.isBaseline && !record.achievedAt.isBefore(windowStart))
        .length;

    final currentRuns = runs
        .where((record) => !record.startedAt.isBefore(windowStart))
        .toList(growable: false);
    final previousRuns = runs
        .where((record) =>
            !record.startedAt.isBefore(previousStart) &&
            record.startedAt.isBefore(windowStart))
        .toList(growable: false);
    final runDistanceKm = currentRuns.fold<double>(
      0,
      (sum, run) => sum + run.distanceKm,
    );
    final runningImproved = _runningImproved(currentRuns, previousRuns);

    final signals = AdaptiveWeekSignals(
      plannedSessions: planned,
      completedSessions: completed,
      skippedSessions: math.min(skippedEvents, planned),
      readinessCheckIns: readinessInWindow.length,
      averageReadiness: averageReadiness,
      lowReadinessCheckIns: lowReadiness,
      progressionWins: progressionWins,
      personalRecords: personalRecords,
      frictionSwaps: swapSignals.friction,
      painSwaps: swapSignals.pain,
      runs: currentRuns.length,
      runDistanceKm: runDistanceKm,
      runningImproved: runningImproved,
    );

    final decision = AdaptiveProgrammeEngine.decide(signals);
    final baseline = _programmeFromProfile(profile);
    final baselineCount = baseline.sessions.length;
    final targetCount = AdaptiveProgrammeEngine.targetSessionCount(
      mode: decision.mode,
      baselineSessions: baselineCount,
    );
    final baselineDuration = _string(profile, 'session_length', '45 min');
    final targetDuration = AdaptiveProgrammeEngine.targetDuration(
      mode: decision.mode,
      baselineDuration: baselineDuration,
    );

    final availableDays = _stringSet(profile['available_days']);
    final selectedDays = _selectDays(availableDays, targetCount);
    final generated = _programmeFromProfile(
      profile,
      availableDaysOverride: selectedDays,
      sessionLengthOverride: targetDuration,
    );

    final adaptedSessions = generated.sessions
        .map(
          (session) => PlannedSession(
            day: session.day,
            title: session.title,
            location: session.location,
            duration: session.duration,
            focus: session.focus,
            intensity: _adaptedIntensity(session.intensity, decision.mode),
            personalisationNote:
                '${_sessionPrefix(decision.mode)} ${session.personalisationNote}'.trim(),
          ),
        )
        .toList(growable: false);

    final programme = GeneratedProgramme(
      goal: generated.goal,
      structure: '${generated.structure} • Adaptive ${decision.mode.label.toLowerCase()}',
      explanation:
          '${decision.summary} ${decision.rationale}.\n\n${generated.explanation}',
      sessions: adaptedSessions,
    );

    return AdaptiveProgrammeResult(
      programme: programme,
      decision: decision,
      signals: signals,
    );
  }

  GeneratedProgramme _programmeFromProfile(
    Map<String, dynamic> profile, {
    Set<String>? availableDaysOverride,
    String? sessionLengthOverride,
  }) {
    return ProgrammeEngine.generate(
      goal: _string(profile, 'main_goal', 'Improve General Fitness'),
      experience: _string(profile, 'experience', 'Beginner'),
      fitnessLevel: _string(profile, 'fitness_level', 'Low'),
      activityLevel: _string(profile, 'activity_level', 'Moderately active'),
      availableDays:
          availableDaysOverride ?? _stringSet(profile['available_days']),
      locations: _stringSet(profile['training_locations']),
      homeEquipment: _stringSet(profile['home_equipment']),
      gymAccess: _string(profile, 'gym_access', 'Standard gym'),
      sessionLength:
          sessionLengthOverride ?? _string(profile, 'session_length', '45 min'),
      trainingTime: _string(profile, 'training_time', 'Flexible'),
      hasLimitation: profile['has_limitation'] == true,
      affectedAreas: _stringSet(profile['affected_areas']),
    );
  }

  static Set<String> _stringSet(dynamic value) {
    if (value is! List) return <String>{};
    return value.whereType<String>().toSet();
  }

  static String _string(
    Map<String, dynamic> profile,
    String key,
    String fallback,
  ) {
    final value = profile[key]?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  static Set<String> _selectDays(Set<String> days, int targetCount) {
    final sorted = days.toList()
      ..sort((a, b) => _weekOrder.indexOf(a).compareTo(_weekOrder.indexOf(b)));
    if (sorted.isEmpty || targetCount >= sorted.length) return sorted.toSet();
    if (targetCount <= 1) return {sorted.first};

    final selected = <String>[];
    for (var i = 0; i < targetCount; i++) {
      final position = i * (sorted.length - 1) / (targetCount - 1);
      final day = sorted[position.round()];
      if (!selected.contains(day)) selected.add(day);
    }
    for (final day in sorted) {
      if (selected.length >= targetCount) break;
      if (!selected.contains(day)) selected.add(day);
    }
    return selected.take(targetCount).toSet();
  }

  static String _adaptedIntensity(String base, AdaptiveWeekMode mode) {
    switch (mode) {
      case AdaptiveWeekMode.progress:
        if (base.toLowerCase().contains('easy')) return base;
        return '$base • measured progression';
      case AdaptiveWeekMode.recovery:
        return 'Easy–Moderate';
      case AdaptiveWeekMode.consolidate:
        return base.toLowerCase().contains('hard') ? 'Moderate' : base;
      case AdaptiveWeekMode.hold:
        return base;
    }
  }

  static String _sessionPrefix(AdaptiveWeekMode mode) {
    switch (mode) {
      case AdaptiveWeekMode.progress:
        return 'Adaptive week: use LeanIt’s existing progression target when form stays controlled.';
      case AdaptiveWeekMode.hold:
        return 'Adaptive week: repeat the current training dose before adding more.';
      case AdaptiveWeekMode.consolidate:
        return 'Adaptive week: fewer planned sessions; focus on completing the work consistently.';
      case AdaptiveWeekMode.recovery:
        return 'Adaptive week: reduced duration and frequency; keep the session controlled.';
    }
  }

  static int _progressionWins(
    Iterable<ExerciseSetPerformance> current,
    Iterable<ExerciseSetPerformance> previous,
  ) {
    final currentBest = _bestPerformance(current);
    final previousBest = _bestPerformance(previous);
    var wins = 0;
    for (final entry in currentBest.entries) {
      final before = previousBest[entry.key];
      if (before == null || before.kind != entry.value.kind) continue;
      if (entry.value.value > before.value * 1.01) wins += 1;
    }
    return wins;
  }

  static Map<String, _PerformanceBest> _bestPerformance(
    Iterable<ExerciseSetPerformance> sets,
  ) {
    final best = <String, _PerformanceBest>{};
    for (final set in sets) {
      if (set.isDropSet) continue;
      final name = set.exerciseName.trim().toLowerCase();
      if (name.isEmpty) continue;

      _PerformanceBest? candidate;
      if (set.weightKg != null && set.weightKg! > 0 && set.reps != null && set.reps! > 0) {
        candidate = _PerformanceBest('weighted-volume', set.volumeKg, 3);
      } else if (set.durationSeconds != null && set.durationSeconds! > 0) {
        candidate = _PerformanceBest('duration', set.durationSeconds!.toDouble(), 2);
      } else if (set.reps != null && set.reps! > 0) {
        candidate = _PerformanceBest('reps', set.reps!.toDouble(), 1);
      }
      if (candidate == null) continue;

      final existing = best[name];
      if (existing == null ||
          candidate.priority > existing.priority ||
          (candidate.priority == existing.priority &&
              candidate.value > existing.value)) {
        best[name] = candidate;
      }
    }
    return best;
  }

  static bool _runningImproved(
    List<RunRecord> current,
    List<RunRecord> previous,
  ) {
    if (current.isEmpty || previous.isEmpty) return false;

    final currentDistance = current.fold<double>(0, (sum, run) => sum + run.distanceKm);
    final previousDistance = previous.fold<double>(0, (sum, run) => sum + run.distanceKm);
    if (previousDistance > 0 && currentDistance > previousDistance * 1.05) {
      return true;
    }

    double? bestPace(List<RunRecord> runs) {
      final paces = runs
          .where((run) => run.distanceMeters >= 500)
          .map((run) => run.averagePaceSecondsPerKm)
          .whereType<double>()
          .where((pace) => pace > 0)
          .toList(growable: false);
      if (paces.isEmpty) return null;
      return paces.reduce(math.min);
    }

    final currentPace = bestPace(current);
    final previousPace = bestPace(previous);
    return currentPace != null &&
        previousPace != null &&
        currentPace < previousPace * 0.98;
  }

  static Future<_SwapSignals> _swapSignals(DateTime since) async {
    var friction = 0;
    var pain = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('leanit_exercise_swaps_v1') ?? const <String>[];
      for (final item in raw) {
        try {
          final decoded = jsonDecode(item);
          if (decoded is! Map) continue;
          final map = Map<String, dynamic>.from(decoded);
          final at = DateTime.tryParse(map['swapped_at']?.toString() ?? '');
          if (at == null || at.isBefore(since)) continue;
          final reason = map['reason']?.toString();
          if (reason == 'painDiscomfort') {
            pain += 1;
          } else if (reason == 'tooDifficult' ||
              reason == 'equipmentUnavailable') {
            friction += 1;
          }
        } catch (_) {}
      }
    } catch (_) {}
    return _SwapSignals(friction: friction, pain: pain);
  }
}

class _PerformanceBest {
  final String kind;
  final double value;
  final int priority;

  const _PerformanceBest(this.kind, this.value, this.priority);
}

class _SwapSignals {
  final int friction;
  final int pain;

  const _SwapSignals({required this.friction, required this.pain});
}
