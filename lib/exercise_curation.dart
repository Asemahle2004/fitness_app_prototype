/// Product-level gate between broad imported exercise data and exercises that
/// LeanIt is willing to expose as programme-ready.
///
/// This shortlist is deliberately conservative. An imported exercise is not
/// approved merely because it has a name, instructions or a licensed image.
/// New movements must be reviewed for programme purpose, practicality,
/// teachability, substitution behaviour, safety metadata and media quality.
class ExerciseCuration {
  const ExerciseCuration._();

  /// Canonical movements currently allowed to enter LeanIt's programme-facing
  /// exercise catalogue. The list covers the movements emitted by the current
  /// programme engine plus its running/cardio session building blocks.
  static const List<String> approvedCanonicalNames = [
    'Band Biceps Curl',
    'Band Pull-Apart',
    'Band Romanian Deadlift',
    'Band Row',
    'Banded Squat',
    'Barbell Bench Press',
    'Bird Dog',
    'Bodyweight Squat',
    'Brisk Walk',
    'Bulgarian Split Squat',
    'Cable Lateral Raise',
    'Cable Overhead Extension',
    'Calf Raise',
    'Calf Stretch',
    'Cat-Cow',
    'Chest-Supported Dumbbell Row',
    'Chin-Up',
    'Close-Grip Push-Up',
    'Dead Bug',
    'Diamond Push-Up',
    'Dumbbell Bench Press',
    'Dumbbell Curl',
    'Dumbbell Floor Press',
    'Dumbbell Pullover',
    'Dumbbell Romanian Deadlift',
    'Dumbbell Shoulder Press',
    'Easy Run',
    'Elliptical',
    'EZ-Bar Curl',
    'Face Pull',
    'Fartlek Run',
    'Glute Bridge',
    'Goblet Squat',
    'Hammer Curl',
    'Hamstring Stretch',
    'High Knees',
    'Hip Flexor Stretch',
    'Hip Thrust',
    'Incline Dumbbell Press',
    'Interval Run',
    'Lat Pulldown',
    'Lateral Raise',
    'Leg Curl',
    'Leg Press',
    'Long Easy Run',
    'Machine Chest Press',
    'Machine Shoulder Press',
    'March in Place',
    'Mountain Climber',
    'One-Arm Dumbbell Row',
    'Overhead Triceps Extension',
    'Pike Push-Up',
    'Plank',
    'Plank Shoulder Tap',
    'Prone Y-T Raise',
    'Pull-Up',
    'Push-Up',
    'Recovery Run',
    'Reverse Fly',
    'Reverse Lunge',
    'Romanian Deadlift',
    'Run-Walk Intervals',
    'Seated Cable Row',
    'Seated Calf Raise',
    'Seated Dumbbell Shoulder Press',
    'Seated Leg Curl',
    'Side Plank',
    'Split Squat',
    'Standing Calf Raise',
    'Stationary Bike',
    'Step-Up',
    'T-Bar Row',
    'Tempo Run',
    'Thoracic Rotation',
    'Treadmill Easy Run',
    'Treadmill Intervals',
    'Triceps Pushdown',
    'Warm-Up Walk',
  ];

  /// Explicit source-name aliases. These are only naming/media bridges; they
  /// do not silently create new programme exercises.
  static const Map<String, List<String>> _sourceAliases = {
    'Barbell Bench Press': ['Barbell Bench Press - Medium Grip'],
    'Cable Lateral Raise': ['Cable Seated Lateral Raise'],
    'Cable Overhead Extension': ['Triceps Overhead Extension with Rope'],
    'Calf Raise': ['Standing Calf Raises'],
    'Hip Thrust': ['Barbell Hip Thrust'],
    'Lat Pulldown': ['Wide-Grip Lat Pulldown', 'Close-Grip Front Lat Pulldown'],
    'Machine Chest Press': ['Leverage Chest Press'],
    'Machine Shoulder Press': [
      'Machine Shoulder (Military) Press',
      'Leverage Shoulder Press',
    ],
    'Pull-Up': ['Pullups'],
    'Push-Up': ['Pushups'],
    'Seated Cable Row': ['Seated Cable Rows'],
    'Split Squat': ['Split Squat with Dumbbells'],
    'T-Bar Row': ['Lying T-Bar Row'],
  };

  static List<String> aliasesFor(String canonicalName) {
    return _sourceAliases[canonicalName] ?? const <String>[];
  }

  static bool isApprovedCanonicalName(String name) {
    final normalized = _normalize(name);
    return approvedCanonicalNames.any(
      (candidate) => _normalize(candidate) == normalized,
    );
  }

  static bool isExplicitApprovedSourceName(String name) {
    if (isApprovedCanonicalName(name)) return true;
    final normalized = _normalize(name);
    return _sourceAliases.values.expand((values) => values).any(
          (alias) => _normalize(alias) == normalized,
        );
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
