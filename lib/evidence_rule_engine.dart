enum EvidenceReviewStatus { draft, reviewed, approved, retired }

class EvidenceRule {
  final String id;
  final String title;
  final Set<String> goals;
  final Set<String> experienceLevels;
  final String movementRole;
  final String weeklyTarget;
  final String sets;
  final String reps;
  final String rest;
  final String progressionRule;
  final String recoveryRule;
  final Set<String> allowedSubstitutions;
  final Set<String> environments;
  final Set<String> equipment;
  final List<String> sources;
  final EvidenceReviewStatus reviewStatus;
  final String reviewerNote;

  const EvidenceRule({
    required this.id,
    required this.title,
    required this.goals,
    required this.experienceLevels,
    required this.movementRole,
    required this.weeklyTarget,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.progressionRule,
    required this.recoveryRule,
    required this.allowedSubstitutions,
    required this.environments,
    required this.equipment,
    required this.sources,
    required this.reviewStatus,
    this.reviewerNote = '',
  });

  bool get canDriveAutomation => reviewStatus == EvidenceReviewStatus.approved;
}

class EvidenceRuleRegistry {
  const EvidenceRuleRegistry._();

  static const List<EvidenceRule> rules = <EvidenceRule>[
    EvidenceRule(
      id: 'strength_novice_full_body',
      title: 'Novice full-body resistance base',
      goals: {'general fitness', 'strength', 'build muscle'},
      experienceLevels: {'beginner'},
      movementRole: 'Compound push, pull, squat/hinge plus simple assistance',
      weeklyTarget: '2–3 full-body exposures with recovery between hard sessions',
      sets: '2–3 working sets per primary movement',
      reps: 'Mostly moderate rep ranges with controlled technique',
      rest: 'Long enough to repeat controlled work; longer for large compound lifts',
      progressionRule: 'Repeat first; add reps within range before a small load increase',
      recoveryRule: 'Hold or reduce when readiness, repeated hard effort or declining performance indicates fatigue',
      allowedSubstitutions: {'same movement role', 'same primary muscle', 'equipment-valid alternative'},
      environments: {'gym', 'home'},
      equipment: {'bodyweight', 'dumbbell', 'barbell', 'machine'},
      sources: {'ACSM resistance-training principles', 'LeanIt conservative progression policy'},
      reviewStatus: EvidenceReviewStatus.approved,
      reviewerNote: 'Seed rule uses conservative volume and double progression.',
    ),
    EvidenceRule(
      id: 'hypertrophy_moderate_volume',
      title: 'Hypertrophy moderate-volume block',
      goals: {'build muscle', 'hypertrophy'},
      experienceLevels: {'beginner', 'intermediate', 'experienced'},
      movementRole: 'Multi-joint and isolation work distributed by muscle group',
      weeklyTarget: 'Multiple quality sets per muscle distributed across the week',
      sets: 'Volume grows only when performance and recovery support it',
      reps: 'Broad moderate-to-high rep ranges depending on exercise',
      rest: 'Enough recovery to preserve productive repetitions',
      progressionRule: 'Progress reps/load or selected volume; never all three aggressively at once',
      recoveryRule: 'Use RIR/RPE, soreness/readiness and declining performance to hold or deload',
      allowedSubstitutions: {'same target muscle', 'similar movement role'},
      environments: {'gym', 'home'},
      equipment: {'bodyweight', 'dumbbell', 'barbell', 'machine', 'cable', 'band'},
      sources: {'ACSM', 'peer-reviewed resistance-training consensus principles'},
      reviewStatus: EvidenceReviewStatus.approved,
    ),
    EvidenceRule(
      id: 'sprint_acceleration_quality',
      title: 'Sprint acceleration quality',
      goals: {'100 m', '200 m', '400 m', 'sprint'},
      experienceLevels: {'beginner', 'intermediate', 'experienced'},
      movementRole: 'Short acceleration repetitions with full recovery',
      weeklyTarget: '1–2 quality acceleration exposures depending on total sprint load',
      sets: 'Low repetition count; quality over fatigue',
      reps: 'Short 10–40 m accelerations',
      rest: 'Full recovery between high-quality efforts',
      progressionRule: 'Progress quality, distance or repetitions conservatively, not all simultaneously',
      recoveryRule: 'Stop high-speed work when mechanics deteriorate or recovery is poor',
      allowedSubstitutions: {'hill acceleration', 'reduced-distance acceleration'},
      environments: {'outside', 'track'},
      equipment: {'none', 'track'},
      sources: {'World Athletics coaching principles', 'LeanIt sprint-quality policy'},
      reviewStatus: EvidenceReviewStatus.approved,
    ),
    EvidenceRule(
      id: 'sprint_max_velocity_quality',
      title: 'Maximum velocity quality',
      goals: {'100 m', '200 m', 'sprint'},
      experienceLevels: {'intermediate', 'experienced'},
      movementRole: 'Flying sprint or maximum-velocity mechanics',
      weeklyTarget: 'Usually one primary maximum-velocity exposure within a balanced sprint week',
      sets: 'Low-volume high-quality repetitions',
      reps: 'Short flying zones after progressive build-in',
      rest: 'Long/full recovery',
      progressionRule: 'Increase exposure only when mechanics and recovery remain high quality',
      recoveryRule: 'Do not schedule maximal-speed work on clearly low-readiness days',
      allowedSubstitutions: {'submaximal wicket/drill session', 'acceleration technique'},
      environments: {'outside', 'track'},
      equipment: {'none', 'cones'},
      sources: {'World Athletics coaching principles'},
      reviewStatus: EvidenceReviewStatus.approved,
    ),
    EvidenceRule(
      id: 'endurance_easy_volume',
      title: 'Easy aerobic volume',
      goals: {'800 m', '1500 m', 'mile', '3k', '5k', '10k', 'half marathon', 'marathon'},
      experienceLevels: {'beginner', 'intermediate', 'experienced'},
      movementRole: 'Easy aerobic running',
      weeklyTarget: 'Majority of endurance volume remains easy enough to recover from',
      sets: 'Continuous run or controlled run-walk',
      reps: 'Distance/time based',
      rest: 'Not applicable during continuous easy running',
      progressionRule: 'Weekly endurance volume rises gradually with regular consolidation weeks',
      recoveryRule: 'Reduce distance/intensity when readiness is low or recent load spikes',
      allowedSubstitutions: {'run-walk', 'shorter easy run', 'low-impact aerobic recovery'},
      environments: {'outside', 'treadmill'},
      equipment: {'running shoes', 'treadmill'},
      sources: {'World Athletics endurance coaching principles', 'ACSM aerobic exercise principles'},
      reviewStatus: EvidenceReviewStatus.approved,
    ),
    EvidenceRule(
      id: 'endurance_threshold_quality',
      title: 'Threshold / tempo quality',
      goals: {'1500 m', 'mile', '3k', '5k', '10k', 'half marathon', 'marathon'},
      experienceLevels: {'intermediate', 'experienced'},
      movementRole: 'Sustained controlled quality running below all-out effort',
      weeklyTarget: 'Normally one threshold-oriented session in a balanced week',
      sets: 'Continuous block or intervals',
      reps: 'Time/distance blocks appropriate to event and level',
      rest: 'Short easy recovery when broken into intervals',
      progressionRule: 'Extend total quality duration gradually before forcing faster pace',
      recoveryRule: 'Replace with easy running when readiness or recent training load is poor',
      allowedSubstitutions: {'cruise intervals', 'steady aerobic run'},
      environments: {'outside', 'track', 'treadmill'},
      equipment: {'running shoes', 'treadmill'},
      sources: {'World Athletics endurance coaching principles'},
      reviewStatus: EvidenceReviewStatus.approved,
    ),
    EvidenceRule(
      id: 'long_run_progression',
      title: 'Long-run progression',
      goals: {'5k', '10k', 'half marathon', 'marathon'},
      experienceLevels: {'beginner', 'intermediate', 'experienced'},
      movementRole: 'Low-intensity aerobic durability',
      weeklyTarget: 'One long run when appropriate to the plan and recovery state',
      sets: 'One continuous or run-walk session',
      reps: 'Distance/time based',
      rest: 'Recovery follows the session rather than between repetitions',
      progressionRule: 'Build gradually, reduce on consolidation weeks, taper before target races',
      recoveryRule: 'Do not compensate for missed long runs by cramming distance into adjacent days',
      allowedSubstitutions: {'shorter easy long run', 'run-walk'},
      environments: {'outside', 'treadmill'},
      equipment: {'running shoes', 'treadmill'},
      sources: {'World Athletics endurance coaching principles', 'LeanIt load-spike policy'},
      reviewStatus: EvidenceReviewStatus.approved,
    ),
    EvidenceRule(
      id: 'experimental_high_frequency',
      title: 'Experimental high-frequency block',
      goals: {'strength'},
      experienceLevels: {'experienced'},
      movementRole: 'Experimental',
      weeklyTarget: 'Research draft only',
      sets: 'Not approved',
      reps: 'Not approved',
      rest: 'Not approved',
      progressionRule: 'Not approved for automation',
      recoveryRule: 'Not approved for automation',
      allowedSubstitutions: {},
      environments: {'gym'},
      equipment: {'barbell'},
      sources: {'Internal research queue'},
      reviewStatus: EvidenceReviewStatus.draft,
    ),
  ];

  static List<EvidenceRule> approvedFor({
    String? goal,
    String? experience,
    String? environment,
  }) {
    final g = goal?.trim().toLowerCase();
    final e = experience?.trim().toLowerCase();
    final env = environment?.trim().toLowerCase();
    return rules.where((rule) {
      if (!rule.canDriveAutomation) return false;
      if (g != null && g.isNotEmpty &&
          !rule.goals.any((item) => g.contains(item) || item.contains(g))) {
        return false;
      }
      if (e != null && e.isNotEmpty &&
          !rule.experienceLevels.map((item) => item.toLowerCase()).contains(e)) {
        return false;
      }
      if (env != null && env.isNotEmpty &&
          !rule.environments.map((item) => item.toLowerCase()).contains(env)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  static EvidenceRule? byId(String id) {
    for (final rule in rules) {
      if (rule.id == id) return rule;
    }
    return null;
  }
}
