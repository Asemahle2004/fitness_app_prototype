import 'programme_engine.dart';

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
  final TrainingBlockPhase phase;
  final double sessionVolumeMultiplier;
  final double sessionDurationMultiplier;
  final double strengthSetMultiplier;
  final double workingLoadMultiplier;
  final bool allowDropSets;
  final bool allowSupersets;
  final int minimumHardSessionSpacingDays;
  final String headline;
  final List<String> reasons;

  const PeriodizationPlan({
    required this.programmeWeek,
    required this.phase,
    required this.sessionVolumeMultiplier,
    required this.sessionDurationMultiplier,
    required this.strengthSetMultiplier,
    required this.workingLoadMultiplier,
    required this.allowDropSets,
    required this.allowSupersets,
    required this.minimumHardSessionSpacingDays,
    required this.headline,
    required this.reasons,
  });

  bool get isRecoveryBlock => phase == TrainingBlockPhase.deload;
}

class PeriodizationEngine {
  const PeriodizationEngine._();

  static PeriodizationPlan? _current;
  static PeriodizationPlan? get current => _current;
  static void setCurrent(PeriodizationPlan? value) => _current = value;

  /// Uses a conservative four-week wave. Recovery/fatigue signals always
  /// override the calendar wave and create a deload instead of forcing load.
  static PeriodizationPlan forWeek({
    required int programmeWeek,
    bool forceRecovery = false,
    bool consolidate = false,
    bool progressionSupported = false,
  }) {
    final safeWeek = programmeWeek < 1 ? 1 : programmeWeek;

    if (forceRecovery) {
      return PeriodizationPlan(
        programmeWeek: safeWeek,
        phase: TrainingBlockPhase.deload,
        sessionVolumeMultiplier: 0.65,
        sessionDurationMultiplier: 0.75,
        strengthSetMultiplier: 0.65,
        workingLoadMultiplier: 0.90,
        allowDropSets: false,
        allowSupersets: false,
        minimumHardSessionSpacingDays: 2,
        headline: 'Recovery block: absorb training before building again',
        reasons: const [
          'Fatigue or recovery evidence overrides planned progression.',
          'Working-set volume is reduced before load is rebuilt.',
          'Drop sets and non-essential intensity techniques are removed.',
        ],
      );
    }

    if (consolidate) {
      return PeriodizationPlan(
        programmeWeek: safeWeek,
        phase: TrainingBlockPhase.consolidate,
        sessionVolumeMultiplier: 0.85,
        sessionDurationMultiplier: 0.90,
        strengthSetMultiplier: 0.85,
        workingLoadMultiplier: 1.0,
        allowDropSets: false,
        allowSupersets: true,
        minimumHardSessionSpacingDays: 1,
        headline: 'Consolidation block: make the current dose repeatable',
        reasons: const [
          'The programme holds difficulty while reducing avoidable fatigue.',
          'Consistency is prioritised before another progression step.',
        ],
      );
    }

    final position = ((safeWeek - 1) % 4) + 1;
    if (position == 1) {
      return PeriodizationPlan(
        programmeWeek: safeWeek,
        phase: TrainingBlockPhase.foundation,
        sessionVolumeMultiplier: 0.90,
        sessionDurationMultiplier: 0.95,
        strengthSetMultiplier: 0.90,
        workingLoadMultiplier: 0.97,
        allowDropSets: false,
        allowSupersets: true,
        minimumHardSessionSpacingDays: 1,
        headline: 'Foundation block: establish clean repeatable work',
        reasons: const [
          'The first week of the wave establishes a stable performance baseline.',
          'Intensity techniques stay limited while movement quality is established.',
        ],
      );
    }

    if (position == 2) {
      return PeriodizationPlan(
        programmeWeek: safeWeek,
        phase: TrainingBlockPhase.build,
        sessionVolumeMultiplier: progressionSupported ? 1.05 : 1.0,
        sessionDurationMultiplier: 1.0,
        strengthSetMultiplier: 1.0,
        workingLoadMultiplier: 1.0,
        allowDropSets: progressionSupported,
        allowSupersets: true,
        minimumHardSessionSpacingDays: 1,
        headline: progressionSupported
            ? 'Build block: measured progression is available'
            : 'Build block: hold until performance supports progression',
        reasons: [
          progressionSupported
              ? 'Recent performance and recovery support a small training increase.'
              : 'The calendar never forces progression without performance evidence.',
        ],
      );
    }

    if (position == 3) {
      return PeriodizationPlan(
        programmeWeek: safeWeek,
        phase: progressionSupported
            ? TrainingBlockPhase.intensify
            : TrainingBlockPhase.build,
        sessionVolumeMultiplier: progressionSupported ? 1.08 : 1.0,
        sessionDurationMultiplier: 1.0,
        strengthSetMultiplier: progressionSupported ? 1.05 : 1.0,
        workingLoadMultiplier: 1.0,
        allowDropSets: progressionSupported,
        allowSupersets: true,
        minimumHardSessionSpacingDays: 1,
        headline: progressionSupported
            ? 'Intensify block: progress without adding unnecessary volume'
            : 'Build block held: evidence is not strong enough to intensify',
        reasons: [
          progressionSupported
              ? 'The highest-loading week stays bounded and is followed by consolidation.'
              : 'LeanIt holds the training dose instead of following the calendar blindly.',
        ],
      );
    }

    return PeriodizationPlan(
      programmeWeek: safeWeek,
      phase: TrainingBlockPhase.consolidate,
      sessionVolumeMultiplier: 0.82,
      sessionDurationMultiplier: 0.90,
      strengthSetMultiplier: 0.82,
      workingLoadMultiplier: 0.97,
      allowDropSets: false,
      allowSupersets: true,
      minimumHardSessionSpacingDays: 2,
      headline: 'Consolidation week: reduce fatigue before the next wave',
      reasons: const [
        'Every fourth programme week intentionally reduces training stress.',
        'The next wave starts from recovered performance rather than accumulated fatigue.',
      ],
    );
  }

  static String adaptDuration(String baseline, PeriodizationPlan plan) {
    final match = RegExp(r'\d+').firstMatch(baseline);
    if (match == null) return baseline;
    final minutes = int.tryParse(match.group(0) ?? '');
    if (minutes == null || minutes <= 0) return baseline;
    final target = (minutes * plan.sessionDurationMultiplier).round();
    final rounded = ((target / 5).round() * 5).clamp(15, 90);
    return '$rounded min';
  }

  /// Applies the current block to the visible weekly schedule. A deload trims
  /// one non-recovery session when the week has three or more sessions, then
  /// reduces duration and intensity across the remaining week.
  static List<PlannedSession> adaptSessions(
    List<PlannedSession> sessions,
    PeriodizationPlan? plan,
  ) {
    if (plan == null || sessions.isEmpty) {
      return List<PlannedSession>.from(sessions);
    }
    var source = List<PlannedSession>.from(sessions);
    if (plan.phase == TrainingBlockPhase.deload && source.length >= 3) {
      final removeIndex = _highestStressIndex(source);
      source.removeAt(removeIndex);
    }

    return source
        .map(
          (session) => PlannedSession(
            day: session.day,
            title: session.title,
            location: session.location,
            duration: adaptDuration(session.duration, plan),
            focus: session.focus,
            intensity: _adaptIntensity(session.intensity, plan),
            personalisationNote:
                '${plan.phase.label} block • ${plan.headline}. ${session.personalisationNote}'
                    .trim(),
          ),
        )
        .toList(growable: false);
  }

  static int _highestStressIndex(List<PlannedSession> sessions) {
    var bestIndex = sessions.length - 1;
    var bestScore = -1;
    for (var i = 0; i < sessions.length; i += 1) {
      final session = sessions[i];
      final text = '${session.title} ${session.focus} ${session.intensity}'.toLowerCase();
      var score = 0;
      if (text.contains('interval') || text.contains('speed')) score += 5;
      if (text.contains('hard') || text.contains('high')) score += 4;
      if (text.contains('lower') || text.contains('legs')) score += 2;
      if (text.contains('recovery') || text.contains('mobility')) score -= 6;
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
}
