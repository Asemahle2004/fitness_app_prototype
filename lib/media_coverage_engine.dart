import 'exercise_curation.dart';
import 'exercise_repository.dart';

class MediaCoverageAudit {
  final int approvedMovements;
  final int resolvedMovements;
  final int reviewedMovements;
  final List<String> missingMovements;
  final List<String> referenceOnlyMovements;

  const MediaCoverageAudit({
    required this.approvedMovements,
    required this.resolvedMovements,
    required this.reviewedMovements,
    required this.missingMovements,
    required this.referenceOnlyMovements,
  });

  double get resolvedPercent => approvedMovements == 0
      ? 0
      : (resolvedMovements / approvedMovements * 100).clamp(0, 100);
}

class MediaCoverageEngine {
  const MediaCoverageEngine._();

  static Future<MediaCoverageAudit> audit(ExerciseRepository repository) async {
    final missing = <String>[];
    final referenceOnly = <String>[];
    var resolved = 0;
    var reviewed = 0;

    for (final name in ExerciseCuration.approvedCanonicalNames) {
      final media = await repository.fetchByName(name);
      if (media == null) {
        missing.add(name);
        continue;
      }
      final hasAny = media.hasApprovedGenericImage ||
          media.hasReferenceGenericImage ||
          media.hasReviewedMaleImage ||
          media.hasReviewedFemaleImage;
      if (!hasAny) {
        missing.add(name);
        continue;
      }
      resolved += 1;
      final productionReviewed = media.hasApprovedGenericImage ||
          media.hasReviewedMaleImage ||
          media.hasReviewedFemaleImage;
      if (productionReviewed) {
        reviewed += 1;
      } else {
        referenceOnly.add(name);
      }
    }

    return MediaCoverageAudit(
      approvedMovements: ExerciseCuration.approvedCanonicalNames.length,
      resolvedMovements: resolved,
      reviewedMovements: reviewed,
      missingMovements: List<String>.unmodifiable(missing),
      referenceOnlyMovements: List<String>.unmodifiable(referenceOnly),
    );
  }
}
