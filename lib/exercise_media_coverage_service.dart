import 'master_exercise_catalogue.dart';
import 'musclewiki_media_service.dart';

typedef ExerciseMediaResolver = Future<MuscleWikiMediaResult> Function({
  required String exerciseName,
  required String sex,
});

class ExerciseMediaCoverageItem {
  final String exerciseName;
  final String section;
  final bool maleAvailable;
  final bool femaleAvailable;
  final int? providerExerciseId;
  final String? maleReason;
  final String? femaleReason;

  const ExerciseMediaCoverageItem({
    required this.exerciseName,
    required this.section,
    required this.maleAvailable,
    required this.femaleAvailable,
    this.providerExerciseId,
    this.maleReason,
    this.femaleReason,
  });

  bool get complete => maleAvailable && femaleAvailable;
  int get availableSides => (maleAvailable ? 1 : 0) + (femaleAvailable ? 1 : 0);
}

class ExerciseMediaCoverageReport {
  final List<ExerciseMediaCoverageItem> items;
  final DateTime auditedAt;

  const ExerciseMediaCoverageReport({
    required this.items,
    required this.auditedAt,
  });

  int get totalExercises => items.length;
  int get expectedSides => totalExercises * 2;
  int get availableSides =>
      items.fold<int>(0, (sum, item) => sum + item.availableSides);
  int get completeExercises => items.where((item) => item.complete).length;
  int get missingExercises => totalExercises - completeExercises;
  double get coveragePercent => expectedSides == 0
      ? 0
      : (availableSides / expectedSides) * 100;

  List<ExerciseMediaCoverageItem> get incomplete =>
      items.where((item) => !item.complete).toList(growable: false);

  Map<String, int> get missingBySection {
    final counts = <String, int>{};
    for (final item in incomplete) {
      counts.update(item.section, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }
}

/// Audits the standardized exercise-demonstration provider without persisting
/// provider URLs or media bytes.
///
/// The audit deliberately requests male and female separately because LeanIt's
/// target is two demonstration variants for every master exercise. A provider
/// exercise ID may be cached by the backend mapping layer, but short-lived
/// media URLs remain memory-only per provider media rules.
class ExerciseMediaCoverageService {
  final ExerciseMediaResolver resolver;

  const ExerciseMediaCoverageService({required this.resolver});

  factory ExerciseMediaCoverageService.muscleWiki(
    MuscleWikiMediaService service,
  ) {
    return ExerciseMediaCoverageService(
      resolver: ({required exerciseName, required sex}) => service.resolve(
        exerciseName: exerciseName,
        sex: sex,
      ),
    );
  }

  Future<ExerciseMediaCoverageReport> audit({
    Iterable<MasterExerciseDefinition>? definitions,
    int batchSize = 4,
  }) async {
    final source = (definitions ?? MasterExerciseCatalogue.definitions).toList();
    final results = <ExerciseMediaCoverageItem>[];
    final safeBatch = batchSize.clamp(1, 8).toInt();

    for (var start = 0; start < source.length; start += safeBatch) {
      final end = (start + safeBatch).clamp(0, source.length).toInt();
      final batch = source.sublist(start, end);
      final resolved = await Future.wait(
        batch.map((definition) async {
          final pair = await Future.wait([
            resolver(exerciseName: definition.name, sex: 'Male'),
            resolver(exerciseName: definition.name, sex: 'Female'),
          ]);
          final male = pair[0];
          final female = pair[1];
          return ExerciseMediaCoverageItem(
            exerciseName: definition.name,
            section: definition.section,
            maleAvailable: male.available,
            femaleAvailable: female.available,
            providerExerciseId:
                male.providerExerciseId ?? female.providerExerciseId,
            maleReason: male.reason,
            femaleReason: female.reason,
          );
        }),
      );
      results.addAll(resolved);
    }

    return ExerciseMediaCoverageReport(
      items: List.unmodifiable(results),
      auditedAt: DateTime.now(),
    );
  }

  static String canonicalProviderKey(String exerciseName) =>
      MasterExerciseCatalogue.normalize(exerciseName);
}
