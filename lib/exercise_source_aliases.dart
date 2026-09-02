class ExerciseSourceAliases {
  const ExerciseSourceAliases._();

  static const Map<String, List<String>> values = {
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

  static List<String> forCanonical(String canonicalName) =>
      values[canonicalName] ?? const <String>[];

  static bool containsSourceName(String name) {
    final normalized = _normalize(name);
    return values.values.expand((items) => items).any(
          (item) => _normalize(item) == normalized,
        );
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}
