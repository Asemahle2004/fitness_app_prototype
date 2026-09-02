import 'evidence_rule_engine.dart';
import 'programme_engine.dart';

enum ProgrammeTemplateCategory {
  strength,
  hypertrophy,
  generalFitness,
  home,
  returnToTraining,
  hybrid,
  runningSupport,
}

class ProgrammeTemplate {
  final String id;
  final String title;
  final String description;
  final ProgrammeTemplateCategory category;
  final Set<String> levels;
  final Set<String> goals;
  final Set<String> equipment;
  final int weeks;
  final int daysPerWeek;
  final List<String> evidenceRuleIds;
  final EvidenceReviewStatus reviewStatus;
  final List<PlannedSession> sessions;

  const ProgrammeTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.levels,
    required this.goals,
    required this.equipment,
    required this.weeks,
    required this.daysPerWeek,
    required this.evidenceRuleIds,
    required this.reviewStatus,
    required this.sessions,
  });

  bool get approved => reviewStatus == EvidenceReviewStatus.approved;

  GeneratedProgramme toGeneratedProgramme() => GeneratedProgramme(
        goal: goals.isEmpty ? 'General Fitness' : goals.first,
        structure: '$weeks-week $title • $daysPerWeek days/week',
        explanation:
            '$description LeanIt may adapt individual weeks from readiness, completion and performance while preserving the programme’s main purpose.',
        sessions: List<PlannedSession>.unmodifiable(sessions),
      );
}

class ProgrammeLibraryEngine {
  const ProgrammeLibraryEngine._();

  static const List<ProgrammeTemplate> templates = <ProgrammeTemplate>[
    ProgrammeTemplate(
      id: 'beginner_full_body_2',
      title: 'Beginner Full Body — 2 Day',
      description: 'A low-complexity strength base for learning repeatable full-body training.',
      category: ProgrammeTemplateCategory.strength,
      levels: {'Beginner'},
      goals: {'Improve General Fitness', 'Build Strength'},
      equipment: {'Bodyweight', 'Dumbbells', 'Gym'},
      weeks: 8,
      daysPerWeek: 2,
      evidenceRuleIds: {'strength_novice_full_body'},
      reviewStatus: EvidenceReviewStatus.approved,
      sessions: [
        PlannedSession(day: 'Monday', title: 'Full Body A', location: 'Flexible', duration: '45 min', focus: 'Squat, push, pull, hinge, core', intensity: 'Moderate', personalisationNote: 'Technique first; finish with repetitions in reserve.'),
        PlannedSession(day: 'Thursday', title: 'Full Body B', location: 'Flexible', duration: '45 min', focus: 'Hinge, push, pull, single-leg, core', intensity: 'Moderate', personalisationNote: 'Repeat clean work before adding load.'),
      ],
    ),
    ProgrammeTemplate(
      id: 'beginner_full_body_3',
      title: 'Beginner Full Body — 3 Day',
      description: 'Three balanced whole-body sessions with recovery between primary exposures.',
      category: ProgrammeTemplateCategory.strength,
      levels: {'Beginner'},
      goals: {'Improve General Fitness', 'Build Strength', 'Build Muscle'},
      equipment: {'Bodyweight', 'Dumbbells', 'Gym'},
      weeks: 8,
      daysPerWeek: 3,
      evidenceRuleIds: {'strength_novice_full_body'},
      reviewStatus: EvidenceReviewStatus.approved,
      sessions: [
        PlannedSession(day: 'Monday', title: 'Full Body A', location: 'Flexible', duration: '45 min', focus: 'Squat + horizontal push/pull', intensity: 'Moderate', personalisationNote: 'Leave margin on every primary lift.'),
        PlannedSession(day: 'Wednesday', title: 'Full Body B', location: 'Flexible', duration: '45 min', focus: 'Hinge + vertical push/pull', intensity: 'Moderate', personalisationNote: 'Middle-week session stays controlled.'),
        PlannedSession(day: 'Friday', title: 'Full Body C', location: 'Flexible', duration: '45 min', focus: 'Balanced full body + carries/core', intensity: 'Moderate', personalisationNote: 'Progress only when the week remains repeatable.'),
      ],
    ),
    ProgrammeTemplate(
      id: 'upper_lower_4',
      title: 'Upper / Lower — 4 Day',
      description: 'A simple four-day split that distributes muscle work across two upper and two lower sessions.',
      category: ProgrammeTemplateCategory.hypertrophy,
      levels: {'Intermediate', 'Experienced'},
      goals: {'Build Muscle', 'Build Strength'},
      equipment: {'Gym', 'Dumbbells', 'Barbell'},
      weeks: 8,
      daysPerWeek: 4,
      evidenceRuleIds: {'hypertrophy_moderate_volume'},
      reviewStatus: EvidenceReviewStatus.approved,
      sessions: [
        PlannedSession(day: 'Monday', title: 'Upper A', location: 'Gym', duration: '60 min', focus: 'Chest, back, shoulders, arms', intensity: 'Moderate–Hard', personalisationNote: 'Primary compounds before assistance.'),
        PlannedSession(day: 'Tuesday', title: 'Lower A', location: 'Gym', duration: '60 min', focus: 'Quads, hamstrings, glutes, calves', intensity: 'Moderate–Hard', personalisationNote: 'Keep lower-body fatigue measurable.'),
        PlannedSession(day: 'Thursday', title: 'Upper B', location: 'Gym', duration: '60 min', focus: 'Back, chest, shoulders, arms', intensity: 'Moderate', personalisationNote: 'Use alternatives without duplicating volume.'),
        PlannedSession(day: 'Saturday', title: 'Lower B', location: 'Gym', duration: '60 min', focus: 'Posterior chain, quads, calves, core', intensity: 'Moderate', personalisationNote: 'Finish the week without forced failure.'),
      ],
    ),
    ProgrammeTemplate(
      id: 'ppl_3',
      title: 'Push / Pull / Legs — 3 Day',
      description: 'One push, one pull and one lower-body day for a simple weekly split.',
      category: ProgrammeTemplateCategory.hypertrophy,
      levels: {'Intermediate'},
      goals: {'Build Muscle'},
      equipment: {'Gym', 'Dumbbells'},
      weeks: 8,
      daysPerWeek: 3,
      evidenceRuleIds: {'hypertrophy_moderate_volume'},
      reviewStatus: EvidenceReviewStatus.approved,
      sessions: [
        PlannedSession(day: 'Monday', title: 'Push', location: 'Gym', duration: '60 min', focus: 'Chest, shoulders, triceps', intensity: 'Moderate–Hard', personalisationNote: 'Progress compounds conservatively.'),
        PlannedSession(day: 'Wednesday', title: 'Pull', location: 'Gym', duration: '60 min', focus: 'Back, rear delts, biceps', intensity: 'Moderate–Hard', personalisationNote: 'Balance vertical and horizontal pulling.'),
        PlannedSession(day: 'Friday', title: 'Legs', location: 'Gym', duration: '60 min', focus: 'Quads, hamstrings, glutes, calves', intensity: 'Moderate–Hard', personalisationNote: 'Do not cram missed upper sessions into leg day.'),
      ],
    ),
    ProgrammeTemplate(
      id: 'hypertrophy_4',
      title: 'Hypertrophy Base — 4 Day',
      description: 'Moderate-volume muscle-building work with planned consolidation and deload support.',
      category: ProgrammeTemplateCategory.hypertrophy,
      levels: {'Intermediate', 'Experienced'},
      goals: {'Build Muscle'},
      equipment: {'Gym'},
      weeks: 12,
      daysPerWeek: 4,
      evidenceRuleIds: {'hypertrophy_moderate_volume'},
      reviewStatus: EvidenceReviewStatus.approved,
      sessions: [
        PlannedSession(day: 'Monday', title: 'Upper Strength', location: 'Gym', duration: '60 min', focus: 'Chest and back emphasis', intensity: 'Moderate–Hard', personalisationNote: 'Use RIR/RPE to decide progression.'),
        PlannedSession(day: 'Tuesday', title: 'Lower Strength', location: 'Gym', duration: '60 min', focus: 'Quads and posterior chain', intensity: 'Moderate–Hard', personalisationNote: 'Stop volume escalation when muscle recovery is low.'),
        PlannedSession(day: 'Thursday', title: 'Upper Volume', location: 'Gym', duration: '60 min', focus: 'Chest, back, shoulders, arms', intensity: 'Moderate', personalisationNote: 'Use productive volume, not junk volume.'),
        PlannedSession(day: 'Saturday', title: 'Lower Volume', location: 'Gym', duration: '60 min', focus: 'Glutes, quads, hamstrings, calves', intensity: 'Moderate', personalisationNote: 'Keep technique controlled through the final set.'),
      ],
    ),
    ProgrammeTemplate(
      id: 'strength_base_3',
      title: 'Strength Base — 3 Day',
      description: 'Three primary strength sessions using conservative double progression and back-off work.',
      category: ProgrammeTemplateCategory.strength,
      levels: {'Intermediate', 'Experienced'},
      goals: {'Build Strength'},
      equipment: {'Gym', 'Barbell', 'Dumbbells'},
      weeks: 10,
      daysPerWeek: 3,
      evidenceRuleIds: {'strength_novice_full_body'},
      reviewStatus: EvidenceReviewStatus.approved,
      sessions: [
        PlannedSession(day: 'Monday', title: 'Strength A', location: 'Gym', duration: '60 min', focus: 'Squat + press + row', intensity: 'Hard but submaximal', personalisationNote: 'No forced grind after RPE/RIR limits are reached.'),
        PlannedSession(day: 'Wednesday', title: 'Strength B', location: 'Gym', duration: '60 min', focus: 'Hinge + overhead + pull', intensity: 'Moderate–Hard', personalisationNote: 'Use the advanced progression engine.'),
        PlannedSession(day: 'Friday', title: 'Strength C', location: 'Gym', duration: '60 min', focus: 'Balanced strength + assistance', intensity: 'Moderate', personalisationNote: 'Finish with repeatable work.'),
      ],
    ),
    ProgrammeTemplate(
      id: 'home_dumbbell_3',
      title: 'Home Dumbbells — 3 Day',
      description: 'A home-based strength and muscle plan using dumbbells plus bodyweight.',
      category: ProgrammeTemplateCategory.home,
      levels: {'Beginner', 'Intermediate'},
      goals: {'Build Muscle', 'Improve General Fitness'},
      equipment: {'Dumbbells', 'Bodyweight'},
      weeks: 8,
      daysPerWeek: 3,
      evidenceRuleIds: {'strength_novice_full_body', 'hypertrophy_moderate_volume'},
      reviewStatus: EvidenceReviewStatus.approved,
      sessions: [
        PlannedSession(day: 'Monday', title: 'Home Full Body A', location: 'Home', duration: '45 min', focus: 'Squat, press, row, hinge', intensity: 'Moderate', personalisationNote: 'Use available dumbbells and bodyweight alternatives.'),
        PlannedSession(day: 'Wednesday', title: 'Home Full Body B', location: 'Home', duration: '45 min', focus: 'Single-leg, push, pull, core', intensity: 'Moderate', personalisationNote: 'Quiet/small-space mode can adapt this session.'),
        PlannedSession(day: 'Friday', title: 'Home Full Body C', location: 'Home', duration: '45 min', focus: 'Balanced full-body progression', intensity: 'Moderate', personalisationNote: 'Repeat clean reps before load.'),
      ],
    ),
    ProgrammeTemplate(
      id: 'bodyweight_foundation',
      title: 'Bodyweight Foundation',
      description: 'No-equipment general fitness for home, travel or limited-space training.',
      category: ProgrammeTemplateCategory.home,
      levels: {'Beginner'},
      goals: {'Improve General Fitness'},
      equipment: {'Bodyweight'},
      weeks: 6,
      daysPerWeek: 3,
      evidenceRuleIds: {'strength_novice_full_body'},
      reviewStatus: EvidenceReviewStatus.approved,
      sessions: [
        PlannedSession(day: 'Monday', title: 'Bodyweight A', location: 'Home', duration: '30 min', focus: 'Squat, push, core', intensity: 'Easy–Moderate', personalisationNote: 'Low-friction starting point.'),
        PlannedSession(day: 'Wednesday', title: 'Bodyweight B', location: 'Home', duration: '30 min', focus: 'Hinge pattern, push, pull substitute, core', intensity: 'Moderate', personalisationNote: 'Use controlled tempo where load is limited.'),
        PlannedSession(day: 'Friday', title: 'Bodyweight C', location: 'Home', duration: '30 min', focus: 'Full-body conditioning', intensity: 'Moderate', personalisationNote: 'Quiet mode removes impact if needed.'),
      ],
    ),
    ProgrammeTemplate(
      id: 'return_training_2',
      title: 'Return to Training — 2 Day',
      description: 'A conservative re-entry block after time away from structured training.',
      category: ProgrammeTemplateCategory.returnToTraining,
      levels: {'Beginner', 'Intermediate', 'Experienced'},
      goals: {'Improve General Fitness', 'Return to Training'},
      equipment: {'Flexible'},
      weeks: 4,
      daysPerWeek: 2,
      evidenceRuleIds: {'strength_novice_full_body'},
      reviewStatus: EvidenceReviewStatus.approved,
      sessions: [
        PlannedSession(day: 'Tuesday', title: 'Return Full Body A', location: 'Flexible', duration: '30 min', focus: 'Low-volume full body', intensity: 'Easy–Moderate', personalisationNote: 'Build tolerance before performance targets.'),
        PlannedSession(day: 'Friday', title: 'Return Full Body B', location: 'Flexible', duration: '30 min', focus: 'Low-volume full body', intensity: 'Easy–Moderate', personalisationNote: 'Readiness can reduce this further.'),
      ],
    ),
    ProgrammeTemplate(
      id: 'general_fitness_4',
      title: 'General Fitness Mix',
      description: 'Strength, aerobic work, mobility and recovery in one sustainable week.',
      category: ProgrammeTemplateCategory.generalFitness,
      levels: {'Beginner', 'Intermediate'},
      goals: {'Improve General Fitness'},
      equipment: {'Flexible'},
      weeks: 8,
      daysPerWeek: 4,
      evidenceRuleIds: {'strength_novice_full_body', 'endurance_easy_volume'},
      reviewStatus: EvidenceReviewStatus.approved,
      sessions: [
        PlannedSession(day: 'Monday', title: 'Full Body Strength', location: 'Flexible', duration: '45 min', focus: 'Full body strength', intensity: 'Moderate', personalisationNote: 'Controlled strength work.'),
        PlannedSession(day: 'Wednesday', title: 'Cardio Base', location: 'Outside', duration: '30 min', focus: 'Easy aerobic fitness', intensity: 'Easy', personalisationNote: 'Conversational effort.'),
        PlannedSession(day: 'Friday', title: 'Full Body Conditioning', location: 'Flexible', duration: '45 min', focus: 'Strength + conditioning', intensity: 'Moderate', personalisationNote: 'Avoid turning every session into hard work.'),
        PlannedSession(day: 'Sunday', title: 'Mobility + Core', location: 'Home', duration: '20 min', focus: 'Mobility and core', intensity: 'Easy', personalisationNote: 'Recovery-support session.'),
      ],
    ),
    ProgrammeTemplate(
      id: 'hybrid_run_strength_4',
      title: 'Run + Strength Hybrid',
      description: 'Two running days and two strength days with hard lower-body stress separated.',
      category: ProgrammeTemplateCategory.hybrid,
      levels: {'Beginner', 'Intermediate'},
      goals: {'Improve Running Performance', 'Improve General Fitness'},
      equipment: {'Flexible'},
      weeks: 10,
      daysPerWeek: 4,
      evidenceRuleIds: {'strength_novice_full_body', 'endurance_easy_volume'},
      reviewStatus: EvidenceReviewStatus.approved,
      sessions: [
        PlannedSession(day: 'Monday', title: 'Runner Strength', location: 'Flexible', duration: '45 min', focus: 'Full-body strength with lower-body support', intensity: 'Moderate', personalisationNote: 'Do not chase leg fatigue before quality running.'),
        PlannedSession(day: 'Wednesday', title: 'Easy Run', location: 'Outside', duration: '30 min', focus: 'Aerobic base', intensity: 'Easy', personalisationNote: 'Use guided running if desired.'),
        PlannedSession(day: 'Friday', title: 'Full Body Strength', location: 'Flexible', duration: '45 min', focus: 'Strength maintenance/build', intensity: 'Moderate', personalisationNote: 'Leave repetitions in reserve.'),
        PlannedSession(day: 'Sunday', title: 'Long Easy Run', location: 'Outside', duration: '45 min', focus: 'Aerobic durability', intensity: 'Easy', personalisationNote: 'Distance progression remains gradual.'),
      ],
    ),
    ProgrammeTemplate(
      id: 'sprint_support_4',
      title: 'Sprint + Strength Support',
      description: 'Acceleration, speed mechanics and two supporting strength exposures for short-distance athletes.',
      category: ProgrammeTemplateCategory.runningSupport,
      levels: {'Intermediate', 'Experienced'},
      goals: {'100 m', '200 m', '400 m'},
      equipment: {'Track', 'Gym'},
      weeks: 8,
      daysPerWeek: 4,
      evidenceRuleIds: {'sprint_acceleration_quality', 'sprint_max_velocity_quality'},
      reviewStatus: EvidenceReviewStatus.approved,
      sessions: [
        PlannedSession(day: 'Monday', title: 'Acceleration', location: 'Outside', duration: '45 min', focus: 'Starts and acceleration', intensity: 'High quality', personalisationNote: 'Full recovery between fast reps.'),
        PlannedSession(day: 'Tuesday', title: 'Sprint Strength A', location: 'Gym', duration: '45 min', focus: 'Posterior chain + general strength', intensity: 'Moderate', personalisationNote: 'Strength supports sprinting; it should not ruin speed quality.'),
        PlannedSession(day: 'Thursday', title: 'Max Velocity / Speed Endurance', location: 'Outside', duration: '45 min', focus: 'Speed quality', intensity: 'High quality', personalisationNote: 'Stop before mechanics deteriorate.'),
        PlannedSession(day: 'Saturday', title: 'Sprint Strength B', location: 'Gym', duration: '40 min', focus: 'General strength + core', intensity: 'Moderate', personalisationNote: 'Keep the final strength session repeatable.'),
      ],
    ),
  ];

  static List<ProgrammeTemplate> approved({
    String? goal,
    String? level,
    Set<String>? equipment,
  }) {
    final g = goal?.trim().toLowerCase();
    final l = level?.trim().toLowerCase();
    final available = equipment?.map((item) => item.toLowerCase()).toSet();
    return templates.where((template) {
      if (!template.approved) return false;
      if (g != null && g.isNotEmpty &&
          !template.goals.any((item) =>
              item.toLowerCase().contains(g) || g.contains(item.toLowerCase()))) {
        return false;
      }
      if (l != null && l.isNotEmpty &&
          !template.levels.map((item) => item.toLowerCase()).contains(l)) {
        return false;
      }
      if (available != null && available.isNotEmpty &&
          !template.equipment.any((item) =>
              item == 'Flexible' || available.contains(item.toLowerCase()))) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  static ProgrammeTemplate? byId(String id) {
    for (final item in templates) {
      if (item.id == id) return item;
    }
    return null;
  }
}
