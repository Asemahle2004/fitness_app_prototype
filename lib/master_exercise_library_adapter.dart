import 'exercise_repository.dart';
import 'exercise_source_aliases.dart';
import 'master_exercise_catalogue.dart';

class MasterExerciseLibraryAdapter {
  const MasterExerciseLibraryAdapter._();

  /// Fast, fully local catalogue used for initial rendering and offline mode.
  /// This is built once per app process instead of rebuilding 400+ records on
  /// every Exercise Library open.
  static final List<OnlineExercise> builtIn = List<OnlineExercise>.unmodifiable(
    _buildCatalogue(const <OnlineExercise>[]),
  );

  static final Map<String, MasterExerciseDefinition> _definitionsByName = {
    for (final definition in MasterExerciseCatalogue.definitions)
      MasterExerciseCatalogue.normalize(definition.name): definition,
  };

  static List<OnlineExercise> mergeWithSource(
    Iterable<OnlineExercise> source,
  ) {
    final sourceList = source.toList(growable: false);
    if (sourceList.isEmpty) return builtIn;
    return List<OnlineExercise>.unmodifiable(_buildCatalogue(sourceList));
  }

  static List<OnlineExercise> _buildCatalogue(List<OnlineExercise> source) {
    // Exact/alias lookup maps make hydration O(master + source) for the common
    // path. The old implementation repeatedly scanned the full source list for
    // every one of LeanIt's ~488 master exercises, which was expensive on a
    // phone and especially bad in a Flutter debug build.
    final sourceByName = <String, OnlineExercise>{
      for (final exercise in source)
        MasterExerciseCatalogue.normalize(exercise.name): exercise,
    };

    final result = <OnlineExercise>[];
    for (final definition in MasterExerciseCatalogue.definitions) {
      final match = _findSourceFast(definition.name, sourceByName);
      result.add(_build(definition, match));
    }

    result.sort(_compare);
    return result;
  }

  static OnlineExercise _build(
    MasterExerciseDefinition definition,
    OnlineExercise? source,
  ) {
    final primary = MasterExerciseCatalogue.primaryMusclesFor(
      definition.section,
    );
    final primaryLower = primary.map((value) => value.toLowerCase()).toSet();
    final secondary = <String>{
      ...?source?.primaryMuscles,
      ...?source?.secondaryMuscles,
    }..removeWhere((value) => primaryLower.contains(value.toLowerCase()));

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

  static OnlineExercise? _findSourceFast(
    String canonicalName,
    Map<String, OnlineExercise> sourceByName,
  ) {
    final canonical = MasterExerciseCatalogue.normalize(canonicalName);
    final exact = sourceByName[canonical];
    if (exact != null) return exact;

    for (final alias in ExerciseSourceAliases.forCanonical(canonicalName)) {
      final aliased = sourceByName[MasterExerciseCatalogue.normalize(alias)];
      if (aliased != null) return aliased;
    }

    // Do not fuzzy-scan the full catalogue during initial library hydration.
    // A detail view can resolve legacy naming variants lazily for one exercise
    // without blocking the whole 488-exercise screen.
    return null;
  }

  static int _compare(OnlineExercise a, OnlineExercise b) {
    final aDefinition =
        _definitionsByName[MasterExerciseCatalogue.normalize(a.name)];
    final bDefinition =
        _definitionsByName[MasterExerciseCatalogue.normalize(b.name)];
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
  }

  static String _slug(String value) {
    var output = value.toLowerCase().replaceAll('&', 'and');
    output = output.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return output.replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
