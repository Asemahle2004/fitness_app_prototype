import 'exercise_repository.dart';
import 'exercise_source_aliases.dart';
import 'master_exercise_catalogue.dart';

class MasterExerciseLibraryAdapter {
  const MasterExerciseLibraryAdapter._();

  static List<OnlineExercise> mergeWithSource(
    Iterable<OnlineExercise> source,
  ) {
    final sourceList = source.toList(growable: false);
    final result = <OnlineExercise>[];

    for (final definition in MasterExerciseCatalogue.definitions) {
      final match = _findSource(definition.name, sourceList);
      result.add(_build(definition, match));
    }

    result.sort((a, b) {
      final aDefinition = MasterExerciseCatalogue.findByName(a.name);
      final bDefinition = MasterExerciseCatalogue.findByName(b.name);
      final byType = MasterExerciseCatalogue.typeIndex(
        aDefinition?.exerciseType,
      ).compareTo(
        MasterExerciseCatalogue.typeIndex(bDefinition?.exerciseType),
      );
      if (byType != 0) return byType;
      final bySection = MasterExerciseCatalogue.sectionIndex(
        aDefinition?.section,
      ).compareTo(
        MasterExerciseCatalogue.sectionIndex(bDefinition?.section),
      );
      if (bySection != 0) return bySection;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return List<OnlineExercise>.unmodifiable(result);
  }

  static OnlineExercise _build(
    MasterExerciseDefinition definition,
    OnlineExercise? source,
  ) {
    final primary = MasterExerciseCatalogue.primaryMusclesFor(
      definition.section,
    );
    final secondary = <String>{
      ...?source?.primaryMuscles,
      ...?source?.secondaryMuscles,
    }..removeWhere(
        (value) => primary.any(
          (primaryValue) =>
              primaryValue.toLowerCase() == value.toLowerCase(),
        ),
      );
    final equipment = source != null && source.equipment.isNotEmpty
        ? source.equipment
        : MasterExerciseCatalogue.inferredEquipment(
            definition.name,
            definition.exerciseType,
          );
    final locations = source != null && source.locations.isNotEmpty
        ? source.locations
        : MasterExerciseCatalogue.inferredLocations(
            definition.name,
            definition.exerciseType,
            equipment,
          );

    return OnlineExercise(
      id: source?.id ?? _slug(definition.name),
      name: definition.name,
      category: _workoutEditorCategory(definition),
      primaryMuscles: primary,
      secondaryMuscles: secondary.toList(growable: false),
      equipment: equipment,
      difficulty: source?.difficulty ??
          MasterExerciseCatalogue.inferredDifficulty(
            definition.name,
            definition.exerciseType,
          ),
      movementPattern: MasterExerciseCatalogue.inferredMovementPattern(
        definition.name,
        definition.exerciseType,
      ),
      locations: locations,
      instructions: source?.instructions ?? const <String>[],
      commonMistakes: source?.commonMistakes ?? const <String>[],
      imagePath: source?.imagePath,
      videoPath: source?.videoPath,
      maleImagePath: source?.maleImagePath,
      femaleImagePath: source?.femaleImagePath,
      maleVideoPath: source?.maleVideoPath,
      femaleVideoPath: source?.femaleVideoPath,
      maleImageReviewed: source?.maleImageReviewed ?? false,
      femaleImageReviewed: source?.femaleImageReviewed ?? false,
      mediaSource: source?.mediaSource ?? 'LeanIt master catalogue',
      mediaLicense: source?.mediaLicense,
      mediaReviewNotes: source?.mediaReviewNotes ??
          'Built-in LeanIt exercise taxonomy. Demonstration media is not attached until separately reviewed.',
    );
  }

  /// The existing custom-workout mapper recognises `stretch` and `cardio`
  /// categories as timed blocks. Keep anatomical grouping in the master
  /// definition/UI, but expose a compatible category for non-strength work so
  /// a running drill or cooldown is never added as 3 sets of 8-12 reps.
  static String _workoutEditorCategory(MasterExerciseDefinition definition) {
    if (definition.exerciseType == 'Strength & Muscle') {
      return definition.section;
    }
    if (definition.exerciseType.contains('Stretching') ||
        definition.exerciseType == 'Cooldown' ||
        definition.exerciseType == 'Running Cooldown') {
      return '${definition.section} Stretch';
    }
    return '${definition.section} Cardio';
  }

  static OnlineExercise? _findSource(
    String canonicalName,
    List<OnlineExercise> source,
  ) {
    final canonical = MasterExerciseCatalogue.normalize(canonicalName);
    for (final exercise in source) {
      if (MasterExerciseCatalogue.normalize(exercise.name) == canonical) {
        return exercise;
      }
    }

    final direct = ExerciseRepository.closestNameMatch(canonicalName, source);
    if (direct != null) return direct;

    for (final alias in ExerciseSourceAliases.forCanonical(canonicalName)) {
      final aliasKey = MasterExerciseCatalogue.normalize(alias);
      for (final exercise in source) {
        if (MasterExerciseCatalogue.normalize(exercise.name) == aliasKey) {
          return exercise;
        }
      }
      final aliasMatch = ExerciseRepository.closestNameMatch(alias, source);
      if (aliasMatch != null) return aliasMatch;
    }
    return null;
  }

  static String _slug(String value) {
    var output = value.toLowerCase().replaceAll('&', 'and');
    output = output.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return output.replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
