import 'programme_engine.dart';

enum MissedWorkoutAction {
  moveLater,
  skipToday,
  continuePlan,
}

class MissedWorkoutOption {
  final MissedWorkoutAction action;
  final String title;
  final String explanation;
  final String? targetDay;
  final List<PlannedSession> revisedSessions;

  const MissedWorkoutOption({
    required this.action,
    required this.title,
    required this.explanation,
    required this.revisedSessions,
    this.targetDay,
  });
}

class MissedWorkoutRecommendation {
  final PlannedSession missedSession;
  final MissedWorkoutOption recommended;
  final List<MissedWorkoutOption> alternatives;

  const MissedWorkoutRecommendation({
    required this.missedSession,
    required this.recommended,
    required this.alternatives,
  });
}

/// Reorganises one programme week when a planned session is missed.
///
/// The engine deliberately does not try to "make up" every missed workout.
/// It only moves a session when there is a later available day that does not
/// create an obviously poor back-to-back workload pattern. When no suitable
/// slot exists, skipping the missed session and continuing the plan is preferred
/// over cramming training into the week.
class MissedWorkoutEngine {
  static const List<String> weekOrder = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static MissedWorkoutRecommendation recommend({
    required List<PlannedSession> sessions,
    required int missedIndex,
    required Set<String> availableDays,
  }) {
    if (sessions.isEmpty || missedIndex < 0 || missedIndex >= sessions.length) {
      throw ArgumentError('missedIndex must point to a planned session.');
    }

    final ordered = List<PlannedSession>.from(sessions)
      ..sort((a, b) => _dayIndex(a.day).compareTo(_dayIndex(b.day)));
    final missed = sessions[missedIndex];
    final orderedMissedIndex = ordered.indexWhere(
      (session) => _sameSession(session, missed),
    );
    final effectiveMissedIndex = orderedMissedIndex < 0 ? 0 : orderedMissedIndex;

    final move = _bestMove(
      sessions: ordered,
      missedIndex: effectiveMissedIndex,
      availableDays: availableDays,
    );
    final skip = _skipOption(ordered, effectiveMissedIndex);
    final continuePlan = _continueOption(ordered, effectiveMissedIndex);

    if (move != null) {
      return MissedWorkoutRecommendation(
        missedSession: missed,
        recommended: move,
        alternatives: <MissedWorkoutOption>[skip, continuePlan],
      );
    }

    return MissedWorkoutRecommendation(
      missedSession: missed,
      recommended: skip,
      alternatives: <MissedWorkoutOption>[continuePlan],
    );
  }

  static MissedWorkoutOption? _bestMove({
    required List<PlannedSession> sessions,
    required int missedIndex,
    required Set<String> availableDays,
  }) {
    final missed = sessions[missedIndex];
    final missedDay = _dayIndex(missed.day);
    final occupied = <String>{
      for (var i = 0; i < sessions.length; i += 1)
        if (i != missedIndex) sessions[i].day,
    };

    final candidates = availableDays
        .where((day) => _dayIndex(day) > missedDay && !occupied.contains(day))
        .toList()
      ..sort((a, b) => _dayIndex(a).compareTo(_dayIndex(b)));

    String? fallback;
    for (final candidate in candidates) {
      fallback ??= candidate;
      if (_isSafePlacement(
        session: missed,
        targetDay: candidate,
        otherSessions: <PlannedSession>[
          for (var i = 0; i < sessions.length; i += 1)
            if (i != missedIndex) sessions[i],
        ],
      )) {
        return _moveOption(sessions, missedIndex, candidate, safe: true);
      }
    }

    // A same-week move that creates poor adjacent loading is intentionally not
    // recommended. Do not use fallback just to keep every planned session.
    if (fallback != null) return null;
    return null;
  }

  static MissedWorkoutOption _moveOption(
    List<PlannedSession> sessions,
    int missedIndex,
    String targetDay, {
    required bool safe,
  }) {
    final missed = sessions[missedIndex];
    final revised = List<PlannedSession>.from(sessions);
    revised[missedIndex] = _copyWithDay(missed, targetDay);
    revised.sort((a, b) => _dayIndex(a.day).compareTo(_dayIndex(b.day)));

    return MissedWorkoutOption(
      action: MissedWorkoutAction.moveLater,
      title: 'Move ${missed.title} to $targetDay',
      explanation: safe
          ? 'This keeps the session in the week without stacking it too closely against a conflicting workout.'
          : 'Move the session later this week.',
      targetDay: targetDay,
      revisedSessions: revised,
    );
  }

  static MissedWorkoutOption _skipOption(
    List<PlannedSession> sessions,
    int missedIndex,
  ) {
    final missed = sessions[missedIndex];
    final revised = <PlannedSession>[
      for (var i = 0; i < sessions.length; i += 1)
        if (i != missedIndex) sessions[i],
    ];
    return MissedWorkoutOption(
      action: MissedWorkoutAction.skipToday,
      title: 'Skip ${missed.title} this week',
      explanation:
          'Continue with the remaining programme instead of cramming missed volume into an unsafe or unrealistic slot.',
      revisedSessions: revised,
    );
  }

  static MissedWorkoutOption _continueOption(
    List<PlannedSession> sessions,
    int missedIndex,
  ) {
    final missed = sessions[missedIndex];
    return MissedWorkoutOption(
      action: MissedWorkoutAction.continuePlan,
      title: 'Leave the week unchanged',
      explanation:
          '${missed.title} stays marked as missed and the next planned session remains where it is.',
      revisedSessions: List<PlannedSession>.from(sessions),
    );
  }

  static bool _isSafePlacement({
    required PlannedSession session,
    required String targetDay,
    required List<PlannedSession> otherSessions,
  }) {
    final targetIndex = _dayIndex(targetDay);
    for (final other in otherSessions) {
      final gap = (_dayIndex(other.day) - targetIndex).abs();
      if (gap != 1) continue;
      if (_conflicts(session, other)) return false;
    }
    return true;
  }

  static bool _conflicts(PlannedSession a, PlannedSession b) {
    final aType = _sessionType(a);
    final bType = _sessionType(b);

    if (aType == _SessionType.recovery || bType == _SessionType.recovery) {
      return false;
    }
    if (aType == _SessionType.mobility || bType == _SessionType.mobility) {
      return false;
    }

    if (aType == _SessionType.hardRun && bType == _SessionType.hardRun) {
      return true;
    }
    if ((aType == _SessionType.hardRun && _isLowerLoading(bType)) ||
        (bType == _SessionType.hardRun && _isLowerLoading(aType))) {
      return true;
    }

    if (aType == _SessionType.fullBodyStrength &&
        _isStrength(bType)) {
      return true;
    }
    if (bType == _SessionType.fullBodyStrength &&
        _isStrength(aType)) {
      return true;
    }
    if (aType == _SessionType.lowerStrength &&
        bType == _SessionType.lowerStrength) {
      return true;
    }
    if (aType == _SessionType.upperStrength &&
        bType == _SessionType.upperStrength) {
      return true;
    }

    return false;
  }

  static bool _isStrength(_SessionType type) =>
      type == _SessionType.upperStrength ||
      type == _SessionType.lowerStrength ||
      type == _SessionType.fullBodyStrength;

  static bool _isLowerLoading(_SessionType type) =>
      type == _SessionType.lowerStrength ||
      type == _SessionType.fullBodyStrength;

  static _SessionType _sessionType(PlannedSession session) {
    final text = '${session.title} ${session.focus} ${session.intensity}'.toLowerCase();

    if (text.contains('mobility') || text.contains('stretch')) {
      return _SessionType.mobility;
    }
    if (text.contains('recovery')) return _SessionType.recovery;
    if (text.contains('interval') ||
        text.contains('tempo') ||
        text.contains('quality run')) {
      return _SessionType.hardRun;
    }
    if (text.contains('run') || text.contains('cardio')) {
      return _SessionType.easyRun;
    }
    if (text.contains('lower') ||
        text.contains('leg') ||
        text.contains('runner strength')) {
      return _SessionType.lowerStrength;
    }
    if (text.contains('upper') || text.contains('push') || text.contains('pull')) {
      return _SessionType.upperStrength;
    }
    if (text.contains('full body') ||
        text.contains('strength') ||
        text.contains('conditioning')) {
      return _SessionType.fullBodyStrength;
    }
    return _SessionType.other;
  }

  static PlannedSession _copyWithDay(PlannedSession session, String day) {
    return PlannedSession(
      day: day,
      title: session.title,
      location: session.location,
      duration: session.duration,
      focus: session.focus,
      intensity: session.intensity,
      personalisationNote: session.personalisationNote,
    );
  }

  static bool _sameSession(PlannedSession a, PlannedSession b) =>
      a.day == b.day && a.title == b.title && a.location == b.location;

  static int _dayIndex(String day) {
    final index = weekOrder.indexOf(day);
    return index < 0 ? 99 : index;
  }
}

enum _SessionType {
  upperStrength,
  lowerStrength,
  fullBodyStrength,
  hardRun,
  easyRun,
  mobility,
  recovery,
  other,
}
