import 'workout_engine.dart';

class TrainingEnvironmentSummary {
  final String fromEnvironment;
  final String toEnvironment;
  final int originalExerciseCount;
  final int adaptedExerciseCount;
  final int preservedSlots;
  final int changedSlots;

  const TrainingEnvironmentSummary({
    required this.fromEnvironment,
    required this.toEnvironment,
    required this.originalExerciseCount,
    required this.adaptedExerciseCount,
    required this.preservedSlots,
    required this.changedSlots,
  });

  bool get changed => fromEnvironment != toEnvironment || changedSlots > 0;

  String get headline => fromEnvironment == toEnvironment
      ? 'Training setup unchanged'
      : '$fromEnvironment → $toEnvironment';

  String get explanation {
    if (!changed) {
      return 'LeanIt kept today’s training environment and exercise structure.';
    }
    if (changedSlots == 0) {
      return 'LeanIt changed today’s training environment while keeping the same exercise structure.';
    }
    return 'LeanIt changed $changedSlots exercise slot${changedSlots == 1 ? '' : 's'} so the session still targets the same training day in $toEnvironment.';
  }
}

class TrainingEnvironmentEngine {
  static const environments = <String>['Gym', 'Home', 'Outside'];

  static String normalise(String? value) {
    final text = (value ?? '').toLowerCase();
    if (text.contains('home')) return 'Home';
    if (text.contains('outside')) return 'Outside';
    return 'Gym';
  }

  static Set<String> effectiveHomeEquipment({
    Set<String> savedEquipment = const {},
    Set<String>? todayOverride,
  }) {
    final source = todayOverride ?? savedEquipment;
    if (source.contains('Bodyweight only')) return const <String>{};
    return source
        .where((item) => item.trim().isNotEmpty && item != 'Bodyweight only')
        .toSet();
  }

  static GeneratedWorkout generate({
    required String sessionTitle,
    required String environment,
    required String? sessionDuration,
    Set<String> savedHomeEquipment = const {},
    Set<String>? todayHomeEquipment,
    String? gymAccess,
  }) {
    return WorkoutEngine.generate(
      sessionTitle: sessionTitle,
      location: normalise(environment),
      homeEquipment: effectiveHomeEquipment(
        savedEquipment: savedHomeEquipment,
        todayOverride: todayHomeEquipment,
      ),
      gymAccess: gymAccess,
      sessionDuration: sessionDuration,
    );
  }

  static TrainingEnvironmentSummary compare({
    required GeneratedWorkout original,
    required String originalEnvironment,
    required GeneratedWorkout adapted,
    required String adaptedEnvironment,
  }) {
    final commonLength = original.exercises.length < adapted.exercises.length
        ? original.exercises.length
        : adapted.exercises.length;
    var preserved = 0;
    for (var index = 0; index < commonLength; index += 1) {
      if (original.exercises[index].name.toLowerCase() ==
          adapted.exercises[index].name.toLowerCase()) {
        preserved += 1;
      }
    }
    final maxLength = original.exercises.length > adapted.exercises.length
        ? original.exercises.length
        : adapted.exercises.length;
    return TrainingEnvironmentSummary(
      fromEnvironment: normalise(originalEnvironment),
      toEnvironment: normalise(adaptedEnvironment),
      originalExerciseCount: original.exercises.length,
      adaptedExerciseCount: adapted.exercises.length,
      preservedSlots: preserved,
      changedSlots: maxLength - preserved,
    );
  }
}
