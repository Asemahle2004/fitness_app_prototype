import 'workout_engine.dart';

enum EquipmentIssueType {
  temporarilyOccupied('Temporarily occupied'),
  unavailableAtLocation('Not available at this training location'),
  unavailableToday('Not available today');

  final String label;
  const EquipmentIssueType(this.label);
}

enum EquipmentSessionAction {
  alternative,
  moveLater,
  skipToday,
}

class EquipmentFlexibilityEngine {
  static Set<String> components(String equipment) {
    final raw = equipment
        .replaceAll(RegExp(r'\bor\b', caseSensitive: false), '+')
        .replaceAll('/', '+')
        .replaceAll(',', '+')
        .split('+')
        .map((value) => normaliseEquipmentToken(value))
        .where((value) => value.isNotEmpty && value != 'bodyweight')
        .toSet();
    return raw;
  }

  static String normaliseEquipmentToken(String value) {
    final text = value.trim().toLowerCase();
    if (text.isEmpty || text.contains('bodyweight') || text == 'none') {
      return 'bodyweight';
    }
    if (text.contains('dumbbell')) return 'dumbbell';
    if (text.contains('barbell')) return 'barbell';
    if (text.contains('bench')) return 'bench';
    if (text.contains('cable')) return 'cable';
    if (text.contains('band')) return 'band';
    if (text.contains('kettlebell')) return 'kettlebell';
    if (text.contains('leg press')) return 'leg press machine';
    if (text.contains('lat pulldown')) return 'lat pulldown machine';
    if (text.contains('machine')) return text.replaceAll(RegExp(r'\s+'), ' ');
    if (text.contains('pull-up') || text.contains('pull up')) return 'pull-up bar';
    if (text.contains('medicine ball')) return 'medicine ball';
    if (text.contains('exercise ball')) return 'exercise ball';
    if (text.contains('treadmill')) return 'treadmill';
    if (text.contains('bike') || text.contains('cycle')) return 'bike';
    return text.replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool exerciseUsesAny(
    ExercisePrescription exercise,
    Set<String> unavailable,
  ) {
    if (unavailable.isEmpty) return false;
    final exerciseEquipment = components('${exercise.equipment} + ${exercise.name}');
    return exerciseEquipment.intersection(unavailable).isNotEmpty;
  }

  static int? nextSafeIndex({
    required List<ExercisePrescription> exercises,
    required int currentIndex,
    required Set<String> unavailable,
  }) {
    for (var index = currentIndex + 1; index < exercises.length; index += 1) {
      final candidate = exercises[index];
      if (candidate.supersetId != null) continue;
      if (!exerciseUsesAny(candidate, unavailable)) return index;
    }
    return null;
  }

  static bool canMoveLater({
    required List<ExercisePrescription> exercises,
    required int currentIndex,
    required Set<String> unavailable,
  }) {
    if (currentIndex < 0 || currentIndex >= exercises.length - 1) return false;
    if (exercises[currentIndex].supersetId != null) return false;
    return nextSafeIndex(
          exercises: exercises,
          currentIndex: currentIndex,
          unavailable: unavailable,
        ) !=
        null;
  }

  static int moveLaterTargetIndex({
    required List<ExercisePrescription> exercises,
    required int currentIndex,
  }) {
    if (exercises.length <= 1) return currentIndex;
    return (currentIndex + 2).clamp(0, exercises.length - 1);
  }

  static EquipmentSessionAction recommend({
    required EquipmentIssueType issue,
    required List<ExercisePrescription> exercises,
    required int currentIndex,
    required Set<String> unavailable,
  }) {
    if (issue == EquipmentIssueType.temporarilyOccupied &&
        canMoveLater(
          exercises: exercises,
          currentIndex: currentIndex,
          unavailable: unavailable,
        )) {
      return EquipmentSessionAction.moveLater;
    }
    return EquipmentSessionAction.alternative;
  }

  static String labelForToken(String token) {
    switch (token) {
      case 'dumbbell':
        return 'Dumbbells';
      case 'barbell':
        return 'Barbell';
      case 'bench':
        return 'Bench';
      case 'cable':
        return 'Cable station';
      case 'band':
        return 'Resistance bands';
      case 'kettlebell':
        return 'Kettlebell';
      case 'pull-up bar':
        return 'Pull-up bar';
      case 'leg press machine':
        return 'Leg press machine';
      case 'lat pulldown machine':
        return 'Lat pulldown machine';
      case 'medicine ball':
        return 'Medicine ball';
      case 'exercise ball':
        return 'Exercise ball';
      case 'treadmill':
        return 'Treadmill';
      case 'bike':
        return 'Bike';
      default:
        if (token.isEmpty) return 'Equipment';
        return '${token[0].toUpperCase()}${token.substring(1)}';
    }
  }
}
