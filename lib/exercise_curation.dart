import 'exercise_source_aliases.dart';
import 'master_exercise_catalogue.dart';

/// Product-level gate between broad imported exercise data and exercises that
/// LeanIt is willing to expose as programme-ready or library-ready.
///
/// The master catalogue is intentionally explicit rather than accepting every
/// exercise returned by an external database. This keeps the public library
/// understandable while still covering strength, muscle groups, cardio,
/// mobility, warm-up/cooldown and running-specific preparation.
class ExerciseCuration {
  const ExerciseCuration._();

  /// Canonical movements approved for LeanIt's Exercise Library.
  ///
  /// Names are deduplicated by [MasterExerciseCatalogue] even when a movement
  /// belongs to several muscle/group filters.
  static final List<String> approvedCanonicalNames =
      List<String>.unmodifiable(
    MasterExerciseCatalogue.definitions.map((item) => item.name),
  );

  static List<String> aliasesFor(String canonicalName) =>
      ExerciseSourceAliases.forCanonical(canonicalName);

  static bool isApprovedCanonicalName(String name) {
    final normalized = _normalize(name);
    return approvedCanonicalNames.any(
      (candidate) => _normalize(candidate) == normalized,
    );
  }

  static bool isExplicitApprovedSourceName(String name) {
    if (isApprovedCanonicalName(name)) return true;
    return ExerciseSourceAliases.containsSourceName(name);
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
