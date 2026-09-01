import 'session_preparation_engine.dart';

class SessionStepDemonstration {
  final String exerciseName;
  final String label;

  const SessionStepDemonstration({
    required this.exerciseName,
    this.label = 'Visual demonstration',
  });
}

/// Connects guided warm-up / mobility / recovery steps to exercises already in
/// LeanIt's curated media system.
///
/// We deliberately use explicit mappings instead of fuzzy name matching. A
/// preparation step only borrows an exercise visual when the movement is the
/// same (or the step explicitly asks the user to choose that movement). If no
/// reviewed/reference visual exists, the flow keeps the written coaching cue
/// rather than showing a misleading demonstration.
class SessionStepVisuals {
  static const Map<String, SessionStepDemonstration> _byStepName = {
    'easy walk or march': SessionStepDemonstration(
      exerciseName: 'March in Place',
    ),
    'easy march': SessionStepDemonstration(
      exerciseName: 'March in Place',
    ),
    'march to running rhythm': SessionStepDemonstration(
      exerciseName: 'High Knees',
      label: 'Running-pattern reference',
    ),
    'easy walk': SessionStepDemonstration(
      exerciseName: 'Brisk Walk',
      label: 'Walking reference',
    ),
    'easy walk and shake-out': SessionStepDemonstration(
      exerciseName: 'Brisk Walk',
      label: 'Walking reference',
    ),
    'calf stretch': SessionStepDemonstration(
      exerciseName: 'Calf Stretch',
    ),
    'hip flexor stretch': SessionStepDemonstration(
      exerciseName: 'Hip Flexor Stretch',
    ),
    'thoracic rotations': SessionStepDemonstration(
      exerciseName: 'Thoracic Rotation',
    ),
    'bodyweight squat to reach': SessionStepDemonstration(
      exerciseName: 'Bodyweight Squat',
      label: 'Squat movement reference',
    ),
    'squat to reach': SessionStepDemonstration(
      exerciseName: 'Bodyweight Squat',
      label: 'Squat movement reference',
    ),
    'glute bridge': SessionStepDemonstration(
      exerciseName: 'Glute Bridge',
    ),
    'hamstring or glute stretch': SessionStepDemonstration(
      exerciseName: 'Hamstring Stretch',
      label: 'Hamstring option',
    ),
    'lower-body stretch': SessionStepDemonstration(
      exerciseName: 'Hamstring Stretch',
      label: 'Hamstring option',
    ),
  };

  static SessionStepDemonstration? forStep(SessionPhaseStep step) {
    return _byStepName[normalise(step.name)];
  }

  static String normalise(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static int coveredStepCount(Iterable<SessionPhaseStep> steps) =>
      steps.where((step) => forStep(step) != null).length;
}
