import 'session_preparation_engine.dart';
import 'training_store.dart';

class RecoveryDayPlan {
  final String title;
  final String headline;
  final String rationale;
  final String location;
  final List<SessionPhaseStep> steps;

  const RecoveryDayPlan({
    required this.title,
    required this.headline,
    required this.rationale,
    required this.location,
    required this.steps,
  });

  int get totalSeconds =>
      steps.fold<int>(0, (sum, step) => sum + step.durationSeconds);

  int get estimatedMinutes => (totalSeconds / 60).ceil();
}

class RecoveryDayEngine {
  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isTodaysCheckIn(ReadinessRecord record, {DateTime? now}) =>
      sameDay(record.recordedAt.toLocal(), (now ?? DateTime.now()).toLocal());

  /// Recovery is offered when the existing readiness model already recommends
  /// a lighter or recovery-focused session. It is an option, not a medical
  /// instruction and it does not block the planned workout.
  static bool shouldOffer(ReadinessRecord record) => record.score < 60;

  static String _preferredLocation(Set<String> locations) {
    if (locations.contains('Home')) return 'Home';
    if (locations.contains('Outside')) return 'Outside';
    if (locations.contains('Gym')) return 'Gym';
    return 'Home';
  }

  static String _easyMovementName(String location) {
    switch (location) {
      case 'Outside':
        return 'Easy walk';
      case 'Gym':
        return 'Easy treadmill walk or bike';
      default:
        return 'Easy march or walk';
    }
  }

  static String _easyMovementCue(String location) {
    switch (location) {
      case 'Outside':
        return 'Walk at a relaxed pace. You should be able to breathe comfortably and talk normally.';
      case 'Gym':
        return 'Use a treadmill or stationary bike at an easy pace. Keep resistance and effort low.';
      default:
        return 'Move gently around the room or march in place. The goal is easy movement, not fatigue.';
    }
  }

  static RecoveryDayPlan forReadiness(
    ReadinessRecord readiness, {
    Set<String> locations = const <String>{},
  }) {
    final location = _preferredLocation(locations);
    final veryLow = readiness.score < 40;
    final highSoreness = readiness.soreness >= 4;
    final highStress = readiness.stress >= 4;

    final steps = veryLow
        ? <SessionPhaseStep>[
            SessionPhaseStep(
              name: _easyMovementName(location),
              durationSeconds: 180,
              cue: _easyMovementCue(location),
              target: 'Gentle circulation and movement',
              type: SessionStepType.recovery,
            ),
            const SessionPhaseStep(
              name: 'Cat-cow mobility',
              durationSeconds: 60,
              cue: 'Move slowly between comfortable rounded and extended positions. Do not force the range.',
              target: 'Spine and trunk mobility',
              type: SessionStepType.mobility,
            ),
            const SessionPhaseStep(
              name: '90/90 hip switches',
              durationSeconds: 60,
              cue: 'Move side to side slowly and keep the range comfortable.',
              target: 'Hips',
              type: SessionStepType.mobility,
            ),
            const SessionPhaseStep(
              name: 'Thoracic rotations',
              durationSeconds: 60,
              cue: 'Rotate gently through the upper back. Stop before the movement becomes uncomfortable.',
              target: 'Upper back',
              type: SessionStepType.mobility,
            ),
            const SessionPhaseStep(
              name: 'Calf stretch',
              durationSeconds: 60,
              cue: 'Use a mild stretch and switch sides halfway through.',
              target: 'Calves',
              type: SessionStepType.stretch,
            ),
            const SessionPhaseStep(
              name: 'Hip flexor stretch',
              durationSeconds: 60,
              cue: 'Stay tall and shift gently forward. Switch sides halfway through.',
              target: 'Hip flexors',
              type: SessionStepType.stretch,
            ),
            SessionPhaseStep(
              name: 'Slow breathing',
              durationSeconds: highStress ? 180 : 120,
              cue: 'Relax your shoulders and use slow, comfortable breaths. Do not force a breathing pattern.',
              target: 'Down-regulation and recovery',
              type: SessionStepType.breathing,
            ),
          ]
        : <SessionPhaseStep>[
            SessionPhaseStep(
              name: _easyMovementName(location),
              durationSeconds: 240,
              cue: _easyMovementCue(location),
              target: 'Easy cardiovascular movement',
              type: SessionStepType.recovery,
            ),
            const SessionPhaseStep(
              name: 'Ankle rocks',
              durationSeconds: 60,
              cue: 'Move the knee gently forward while the heel stays down. Switch sides halfway.',
              target: 'Ankles and calves',
              type: SessionStepType.mobility,
            ),
            const SessionPhaseStep(
              name: 'Hip mobility flow',
              durationSeconds: 90,
              cue: 'Use slow hip circles or controlled 90/90 switches within a comfortable range.',
              target: 'Hips',
              type: SessionStepType.mobility,
            ),
            const SessionPhaseStep(
              name: 'Shoulder and upper-back mobility',
              durationSeconds: 90,
              cue: 'Use easy arm circles and upper-back rotations. Keep the neck relaxed.',
              target: 'Shoulders and upper back',
              type: SessionStepType.mobility,
            ),
            SessionPhaseStep(
              name: highSoreness ? 'Gentle supported squat mobility' : 'Controlled sit-to-stand',
              durationSeconds: 60,
              cue: highSoreness
                  ? 'Use support and only a comfortable depth. This is mobility, not a strength set.'
                  : 'Move slowly through a comfortable range. Keep the effort easy and stop well before fatigue.',
              target: 'Hips, knees and ankles',
              type: SessionStepType.mobility,
            ),
            SessionPhaseStep(
              name: _easyMovementName(location),
              durationSeconds: 120,
              cue: 'Return to relaxed continuous movement and keep the effort easy.',
              target: 'General recovery',
              type: SessionStepType.recovery,
            ),
            const SessionPhaseStep(
              name: 'Calf and hamstring stretch',
              durationSeconds: 90,
              cue: 'Use mild stretches only and switch sides during the timer.',
              target: 'Calves and hamstrings',
              type: SessionStepType.stretch,
            ),
            SessionPhaseStep(
              name: 'Slow breathing',
              durationSeconds: highStress ? 150 : 90,
              cue: 'Relax your shoulders and let your breathing settle naturally.',
              target: 'Recovery',
              type: SessionStepType.breathing,
            ),
          ];

    return RecoveryDayPlan(
      title: 'Recovery Day — $location',
      headline: veryLow
          ? 'Recovery is the priority today'
          : 'A lighter recovery session may fit today better',
      rationale: veryLow
          ? 'Your readiness score is ${readiness.score.round()}/100. LeanIt is offering very easy movement, mobility and breathing instead of training volume.'
          : 'Your readiness score is ${readiness.score.round()}/100. This option keeps you moving while avoiding normal strength volume and progressive-overload targets.',
      location: location,
      steps: steps,
    );
  }
}
