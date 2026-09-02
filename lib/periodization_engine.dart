import 'programme_engine.dart';
import 'training_profile_context.dart';

enum TrainingBlockPhase {
  foundation,
  build,
  intensify,
  consolidate,
  deload,
}

extension TrainingBlockPhaseDetails on TrainingBlockPhase {
  String get label {
    switch (this) {
      case TrainingBlockPhase.foundation:
        return 'Foundation';
      case TrainingBlockPhase.build:
        return 'Build';
      case TrainingBlockPhase.intensify:
        return 'Intensify';
      case TrainingBlockPhase.consolidate:
        return 'Consolidate';
      case TrainingBlockPhase.deload:
        return 'Deload';
    }
  }
}

class PeriodizationPlan {
  final int programmeWeek;
  final int blockNumber;
  final int weekInBlock;
  final TrainingBlockPhase phase;
  final double sessionVolumeMultiplier;
  final double sessionDurationMultiplier;
  final double strengthSetMultiplier;
  final double workingLoadMultiplier;
  final bool allowDropSets;
  final bool allowSupersets;
  final int minimumHardSessionSpacingDays;
  final bool plannedRecovery;
  final String goalEmphasis;
  final String headline;
  final List<String> reasons;

  const PeriodizationPlan({
    required this.programmeWeek,
    this.blockNumber = 1,
    this.weekInBlock = 1,
    required this.phase,
    required this.sessionVolumeMultiplier,
    required this.sessionDurationMultiplier,
    required this.strengthSetMultiplier,
    required this.workingLoadMultiplier,
    required this.allowDropSets,
    required this.allowSupersets,
    required this.minimumHardSessionSpacingDays,
    this.plannedRecovery = false,
    this.goalEmphasis = 'balanced',
    required this.headline,
    required this.reasons,
  });

  bool get isRecoveryBlock => phase == TrainingBlockPhase.deload;
  bool get protectsRecovery =>
      phase == TrainingBlockPhase.deload ||
      phase == TrainingBlockPhase.consolidate;
  String get blockLabel => 'Block $blockNumber • Week $weekInBlock/8';
}

class PeriodizationEngine {
  const PeriodizationEngine._();

  static PeriodizationPlan? _current;
  static PeriodizationPlan? get current => _current;
  static void setCurrent(PeriodizationPlan? value) => _current = value;

  /// Eight-week evidence-aware mesocycle.
  ///
  /// The calendar supplies structure only. Recovery/fatigue evidence always
  /// wins and can create an earlier deload. Likewise, build/intensify weeks
  /// only increase training when recent performance supports progression.
  static PeriodizationPlan forWeek({
    required int programmeWeek,
    bool forceRecovery = false,
    bool consolidate = false,
    bool progressionSupported = false,
    List<String>? goals,
  }) {
    final safeWeek = programmeWeek < 1 ? 1 : programmeWeek;
    final blockNumber = ((safeWeek - 1) ~/ 8) + 1;
    final weekInBlock = ((safeWeek - 1) % 8) + 1;
    final effectiveGoals = goals ??
        TrainingProfileContext.current?.goals ??
        const <String>[];
    final emphasis = _goalEmphasis(effectiveGoals);

    if (forceRecovery) {
      return PeriodizationPlan(
        programmeWeek: safeWeek,
        blockNumber: blockNumber,
        weekInBlock: weekInBlock,
        phase: TrainingBlockPhase.deload,
        sessionVolumeMultiplier: 0.62,
        sessionDurationMultiplier: 0.72,
        strengthSetMultiplier: 0.62,
        workingLoadMultiplier: 0.88,
        allowDropSets: false,
        allowSupersets: false,
        minimumHardSessionSpacingDays: 2,
        plannedRecovery: false,
        goalEmphasis: emphasis,
        headline: 'Recovery week active: absorb training before building again',
        reasons: const [
          'Current fatigue or recovery evidence overrides the planned block.',
          'Weekly volume and session duration are reduced before load is rebuilt.',
          'Drop sets, hard supersets and non-essential intensity techniques are removed.',
          'Missed work is not crammed into another day during recovery.',
        ],
      );
    }

    if (consolidate) {
      return PeriodizationPlan(
        programmeWeek: safeWeek,
        blockNumber: blockNumber,
        weekInBlock: weekInBlock,
        phase: TrainingBlockPhase.consolidate,
        sessionVolumeMultiplier: 0.84,
        sessionDurationMultiplier: 0.90,
        strengthSetMultiplier: 0.84,
        workingLoadMultiplier: 1.0,
        allowDropSets: false,
        allowSupersets: true,
        minimumHardSessionSpacingDays: 1,
        goalEmphasis: emphasis,
        headline: 'Consolidation week: make the current training dose repeatable',
        reasons: const [
          'Recovery or adherence data does not support adding more work right now.',
          'Difficulty is held while avoidable fatigue is reduced.',
        ],
      );
    }

    if (weekInBlock == 8) {
      return PeriodizationPlan(
        programmeWeek: safeWeek,
        blockNumber: blockNumber,
        weekInBlock: weekInBlock,
        phase: TrainingBlockPhase.deload,
        sessionVolumeMultiplier: 0.70,
        sessionDurationMultiplier: 0.80,
        strengthSetMultiplier: 0.70,
        workingLoadMultiplier: 0.92,
        allowDropSets: false,
        allowSupersets: false,
        minimumHardSessionSpacingDays: 2,
        plannedRecovery: true,
        goalEmphasis: emphasis,
        headline: 'Planned recovery week: finish the block fresh enough to progress',
        reasons: const [
          'The eighth week intentionally lowers accumulated training stress.',
          'The next block starts from recovered performance rather than fatigue.',
          'No missed volume is made up during this lighter week.',
        ],
      );
    }

    if (weekInBlock == 1) {
      return PeriodizationPlan(
        programmeWeek: safeWeek,
        blockNumber: blockNumber,
        weekInBlock: weekInBlock,
        phase: TrainingBlockPhase.foundation,
        sessionVolumeMultiplier: 0.90,
        sessionDurationMultiplier: 0.95,
        strengthSetMultiplier: 0.90,
        workingLoadMultiplier: 0.97,
        allowDropSets: false,
        allowSupersets: true,
        minimumHardSessionSpacingDays: 1,
        goalEmphasis: emphasis,
        headline: 'Foundation week: establish clean, repeatable work',
        reasons: const [
          'The new block starts below peak workload so technique and readiness can be re-established.',
          'Intensity techniques stay limited while a fresh baseline is built.',
        ],
      );
    }

    if (weekInBlock == 4) {
      return PeriodizationPlan(
        programmeWeek: safeWeek,
        blockNumber: blockNumber,
        weekInBlock: weekInBlock,
        phase: TrainingBlockPhase.consolidate,
        sessionVolumeMultiplier: 0.86,
        sessionDurationMultiplier: 0.90,
        strengthSetMultiplier: 0.86,
        workingLoadMultiplier: 0.98,
        allowDropSets: false,
        allowSupersets: true,
        minimumHardSessionSpacingDays: 2,
        goalEmphasis: emphasis,
        headline: 'Mid-block consolidation: reduce fatigue without losing momentum',
        reasons: const [
          'The fourth week reduces training stress before the second half of the block.',
          'Progression resumes only if performance and recovery remain supportive.',
        ],
      );
    }

    final intensifyWeek = weekInBlock == 6 || weekInBlock == 7;
    if (intensifyWeek) {
      return PeriodizationPlan(
        programmeWeek: safeWeek,
        blockNumber: blockNumber,
        weekInBlock: weekInBlock,
        phase: progressionSupported
            ? TrainingBlockPhase.intensify
            : TrainingBlockPhase.build,
        sessionVolumeMultiplier: progressionSupported ? 1.05 : 1.0,
        sessionDurationMultiplier: 1.0,
        strengthSetMultiplier: progressionSupported ? 1.03 : 1.0,
        workingLoadMultiplier: progressionSupported && emphasis != 'endurance'
            ? 1.01
            : 1.0,
        allowDropSets: progressionSupported && emphasis != 'running',
        allowSupersets: true,
        minimumHardSessionSpacingDays: 1,
        goalEmphasis: emphasis,
        headline: progressionSupported
            ? 'Intensify week: progress the quality of work, not random volume'
            : 'Build week held: evidence is not strong enough to intensify',
        reasons: [
          progressionSupported
              ? 'Recent performance supports a bounded increase before the recovery week.'
              : 'LeanIt holds the dose instead of intensifying because the evidence is not strong enough.',
          if (emphasis == 'running')
            'Running quality is progressed through pace, distance or interval structure rather than gym intensity techniques.',
        ],
      );
    }

    return PeriodizationPlan(
      programmeWeek: safeWeek,
      blockNumber: blockNumber,
      weekInBlock: weekInBlock,
      phase: TrainingBlockPhase.build,
      sessionVolumeMultiplier: progressionSupported ? 1.04 : 1.0,
      sessionDurationMultiplier: 1.0,
      strengthSetMultiplier: progressionSupported ? 1.02 : 1.0,
      workingLoadMultiplier: 1.0,
      allowDropSets: progressionSupported && emphasis != 'running',
      allowSupersets: true,
      minimumHardSessionSpacingDays: 1,
      goalEmphasis: emphasis,
      headline: progressionSupported
          ? 'Build week: a measured progression is available'
          : 'Build week: repeat the current dose until performance supports more',
      reasons: [
        progressionSupported
            ? 'Recent performance and recovery support a small training increase.'
            : 'The calendar never forces progression without performance evidence.',
      ],
    );
  }

  static String adaptDuration(String baseline, PeriodizationPlan plan) {
    final match = RegExp(r'\d+').firstMatch(baseline);
    if (match == null) return baseline;
    final minutes = int.tryParse(match.group(0) ?? '');
    if (minutes == null || minutes <= 0) return baseline;
    final target = (minutes * plan.sessionDurationMultiplier).round();
    final rounded = ((target / 5).round() * 5).clamp(15, 120);
    return '$rounded min';
  }

  /// Applies the active block to a copy of the weekly schedule.
  ///
  /// Deloads never add sessions or cram missed work. Four-plus-session weeks
  /// remove one highest-stress non-recovery slot; shorter weeks keep frequency
  /// but reduce every session. Hard sessions are then spaced by downgrading a
  /// conflicting second session instead of moving it onto another day.
  static List<PlannedSession> adaptSessions(
    List<PlannedSession> sessions,
    PeriodizationPlan? plan,
  ) {
    if (plan == null || sessions.isEmpty) {
      return List<PlannedSession>.from(sessions);
    }

    var source = List<PlannedSession>.from(sessions);
    if (plan.phase == TrainingBlockPhase.deload && source.length >= 4) {
      source.removeAt(_highestStressIndex(source));
    }

    final adapted = source
        .map(
          (session) => PlannedSession(
            day: session.day,
            title: session.title,
            location: session.location,
            duration: adaptDuration(session.duration, plan),
            focus: session.focus,
            intensity: _adaptIntensity(session.intensity, plan),
            personalisationNote:
                '${plan.blockLabel} • ${plan.phase.label}. ${plan.headline}. ${session.personalisationNote}'
                    .trim(),
          ),
        )
        .toList(growable: true);

    if (plan.minimumHardSessionSpacingDays >= 2) {
      _protectAdjacentHardSessions(adapted, plan);
    }
    return adapted;
  }

  static void _protectAdjacentHardSessions(
    List<PlannedSession> sessions,
    PeriodizationPlan plan,
  ) {
    sessions.sort((a, b) => _dayIndex(a.day).compareTo(_dayIndex(b.day)));
    for (var i = 1; i < sessions.length; i += 1) {
      final previous = sessions[i - 1];
      final current = sessions[i];
      final dayGap = _dayIndex(current.day) - _dayIndex(previous.day);
      if (dayGap != 1 || !_isHard(previous) || !_isHard(current)) continue;
      sessions[i] = PlannedSession(
        day: current.day,
        title: current.title,
        location: current.location,
        duration: current.duration,
        focus: current.focus,
        intensity: 'Moderate • recovery-protected',
        personalisationNote:
            '${current.personalisationNote} Adjacent hard loading was reduced to protect recovery.',
      );
    }
  }

  static bool _isHard(PlannedSession session) {
    final text = '${session.title} ${session.focus} ${session.intensity}'.toLowerCase();
    return text.contains('hard') ||
        text.contains('high') ||
        text.contains('interval') ||
        text.contains('speed') ||
        text.contains('intens');
  }

  static int _highestStressIndex(List<PlannedSession> sessions) {
    var bestIndex = sessions.length - 1;
    var bestScore = -999;
    for (var i = 0; i < sessions.length; i += 1) {
      final session = sessions[i];
      final text = '${session.title} ${session.focus} ${session.intensity}'.toLowerCase();
      var score = 0;
      if (text.contains('interval') || text.contains('speed')) score += 5;
      if (text.contains('hard') || text.contains('high')) score += 4;
      if (text.contains('lower') || text.contains('legs')) score += 2;
      if (text.contains('recovery') || text.contains('mobility')) score -= 10;
      if (score >= bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  static String _adaptIntensity(String baseline, PeriodizationPlan plan) {
    switch (plan.phase) {
      case TrainingBlockPhase.deload:
        return 'Easy–Moderate • deload';
      case TrainingBlockPhase.consolidate:
        return baseline.toLowerCase().contains('hard')
            ? 'Moderate • consolidate'
            : '$baseline • consolidate';
      case TrainingBlockPhase.foundation:
        return '$baseline • technique first';
      case TrainingBlockPhase.build:
        return '$baseline • controlled build';
      case TrainingBlockPhase.intensify:
        return '$baseline • measured progression';
    }
  }

  static String _goalEmphasis(List<String> goals) {
    final lower = goals.map((goal) => goal.toLowerCase()).toList(growable: false);
    final running = lower.any((goal) => goal.contains('running'));
    final strength = lower.any((goal) =>
        goal.contains('muscle') ||
        goal.contains('gain weight') ||
        goal.contains('strength'));
    if (running && strength) return 'concurrent';
    if (running) return 'running';
    if (strength) return 'strength';
    if (lower.any((goal) => goal.contains('fat'))) return 'conditioning';
    return 'balanced';
  }

  static int _dayIndex(String day) {
    const order = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final index = order.indexOf(day);
    return index < 0 ? 99 : index;
  }
}
