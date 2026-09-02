import 'training_context_engine.dart';

class TrainingContextSelection {
  final TrainingContextMode mode;
  final int? readinessScore;
  final DateTime expiresAt;

  const TrainingContextSelection({
    required this.mode,
    required this.readinessScore,
    required this.expiresAt,
  });

  bool get active => DateTime.now().isBefore(expiresAt);
}

class TrainingContextCache {
  TrainingContextCache._();

  static TrainingContextSelection? _current;

  static TrainingContextSelection? get current {
    final value = _current;
    if (value == null) return null;
    if (!value.active) {
      _current = null;
      return null;
    }
    return value;
  }

  static void set(
    TrainingContextMode mode, {
    int? readinessScore,
    Duration duration = const Duration(hours: 8),
  }) {
    if (mode == TrainingContextMode.normal) {
      _current = null;
      return;
    }
    _current = TrainingContextSelection(
      mode: mode,
      readinessScore: readinessScore,
      expiresAt: DateTime.now().add(duration),
    );
  }

  static void clear() => _current = null;
}
