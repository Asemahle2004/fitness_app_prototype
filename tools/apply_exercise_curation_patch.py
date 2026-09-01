from pathlib import Path

repo = Path(__file__).resolve().parents[1]
repository_path = repo / 'lib' / 'exercise_repository.dart'
text = repository_path.read_text(encoding='utf-8')

import_anchor = "import 'package:supabase_flutter/supabase_flutter.dart';\n"
if "import 'exercise_curation.dart';" not in text:
    if import_anchor not in text:
        raise SystemExit('Could not find exercise_repository import anchor')
    text = text.replace(
        import_anchor,
        import_anchor + "\nimport 'exercise_curation.dart';\n",
        1,
    )

old_fetch_by_name = """    final lower = name.trim().toLowerCase();
    final catalogue = await _freeCatalogueSafely();
    for (final exercise in catalogue) {
      if (exercise.name.toLowerCase() == lower) return exercise;
    }

    // Programme Engine intentionally uses clean, user-facing exercise names.
    // The reference catalogue sometimes adds a small qualifier to the same
    // movement (for example \"Barbell Bench Press - Medium Grip\"). Resolve
    // those safe naming variants so programme cards can show their existing
    // reference media instead of a placeholder.
    return closestNameMatch(name, catalogue);
"""
new_fetch_by_name = """    final lower = name.trim().toLowerCase();
    final catalogue = await _freeCatalogueSafely();
    for (final exercise in catalogue) {
      if (exercise.name.toLowerCase() == lower) return exercise;
    }

    // Programme Engine intentionally uses clean, user-facing exercise names.
    // The reference catalogue sometimes adds a small qualifier to the same
    // movement (for example \"Barbell Bench Press - Medium Grip\"). Resolve
    // those safe naming variants so programme cards can show their existing
    // reference media instead of a placeholder.
    final direct = closestNameMatch(name, catalogue);
    if (direct != null) return direct;

    // A small, reviewed alias table handles source-catalogue names that are
    // semantically the same programme movement but cannot be resolved safely
    // by token matching alone (for example Machine Chest Press -> Leverage
    // Chest Press). Aliases are deliberately explicit rather than fuzzy.
    for (final alias in ExerciseCuration.aliasesFor(name)) {
      final aliasLower = alias.toLowerCase();
      for (final exercise in catalogue) {
        if (exercise.name.toLowerCase() == aliasLower) return exercise;
      }
      final aliasMatch = closestNameMatch(alias, catalogue);
      if (aliasMatch != null) return aliasMatch;
    }
    return null;
"""
if old_fetch_by_name not in text:
    raise SystemExit('Could not find fetchByName block')
text = text.replace(old_fetch_by_name, new_fetch_by_name, 1)

text = text.replace(
    "for (final exercise in freeCatalogue.take(freeCatalogueLimit)) {",
    "for (final exercise in freeCatalogue) {",
    1,
)

old_result = """    final result = merged.values.toList(growable: false)
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    return result;
"""
new_result = """    // The public fallback is intentionally broad. It is source material for
    // review, not the product catalogue. Only one reviewed match for each
    // programme-approved canonical exercise is exposed to the library,
    // custom-workout picker and substitution engine.
    final source = merged.values.toList(growable: false);
    final curated = <String, OnlineExercise>{};

    for (final canonicalName in ExerciseCuration.approvedCanonicalNames) {
      OnlineExercise? match;
      final canonicalLower = canonicalName.toLowerCase();

      for (final exercise in source) {
        if (exercise.name.toLowerCase() == canonicalLower) {
          match = exercise;
          break;
        }
      }

      match ??= closestNameMatch(canonicalName, source);

      if (match == null) {
        for (final alias in ExerciseCuration.aliasesFor(canonicalName)) {
          final aliasLower = alias.toLowerCase();
          for (final exercise in source) {
            if (exercise.name.toLowerCase() == aliasLower) {
              match = exercise;
              break;
            }
          }
          match ??= closestNameMatch(alias, source);
          if (match != null) break;
        }
      }

      if (match != null) curated[match.id] = match;
    }

    final result = curated.values.toList(growable: false)
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    return result;
"""
if old_result not in text:
    raise SystemExit('Could not find fetchAll result block')
text = text.replace(old_result, new_result, 1)
repository_path.write_text(text, encoding='utf-8')

(repo / 'lib' / 'exercise_curation.dart').write_text(r'''/// Product-level gate between broad imported exercise data and exercises that
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
''', encoding='utf-8')

(repo / 'test' / 'exercise_curation_test.dart').write_text(r'''import 'package:fitness_app_prototype/exercise_curation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseCuration', () {
    test('keeps programme core movements', () {
      expect(
        ExerciseCuration.isApprovedCanonicalName('Barbell Bench Press'),
        isTrue,
      );
      expect(
        ExerciseCuration.isApprovedCanonicalName('Dumbbell Bench Press'),
        isTrue,
      );
      expect(ExerciseCuration.isApprovedCanonicalName('Leg Press'), isTrue);
      expect(ExerciseCuration.isApprovedCanonicalName('Lat Pulldown'), isTrue);
      expect(
        ExerciseCuration.isApprovedCanonicalName('Romanian Deadlift'),
        isTrue,
      );
      expect(ExerciseCuration.isApprovedCanonicalName('Push-Up'), isTrue);
    });

    test('does not approve arbitrary imported catalogue exercises', () {
      expect(
        ExerciseCuration.isApprovedCanonicalName('90/90 Hamstring'),
        isFalse,
      );
      expect(
        ExerciseCuration.isApprovedCanonicalName('Advanced Kettlebell Windmill'),
        isFalse,
      );
      expect(
        ExerciseCuration.isApprovedCanonicalName('Alternate Heel Touchers'),
        isFalse,
      );
    });

    test('recognises only explicit source aliases', () {
      expect(
        ExerciseCuration.isExplicitApprovedSourceName(
          'Barbell Bench Press - Medium Grip',
        ),
        isTrue,
      );
      expect(
        ExerciseCuration.isExplicitApprovedSourceName('Seated Cable Rows'),
        isTrue,
      );
      expect(
        ExerciseCuration.isExplicitApprovedSourceName('Wide-Grip Decline Barbell Bench Press'),
        isFalse,
      );
    });

    test('approved catalogue remains deliberately compact', () {
      expect(ExerciseCuration.approvedCanonicalNames.length, lessThan(100));
      expect(ExerciseCuration.approvedCanonicalNames.length, greaterThan(50));
      expect(
        ExerciseCuration.approvedCanonicalNames.toSet().length,
        ExerciseCuration.approvedCanonicalNames.length,
      );
    });
  });
}
''', encoding='utf-8')

(repo / 'docs').mkdir(exist_ok=True)
(repo / 'docs' / 'EXERCISE_CURATION.md').write_text(r'''# LeanIt Exercise Curation Gate

LeanIt does not treat a large imported exercise database as a finished product catalogue.

The public/free exercise dataset remains **source material**. The user-facing Exercise Library, custom-workout picker and automatic substitution engine receive only a compact programme-approved shortlist.

## Why

A larger number is not automatically better. A final training product needs movements that have a clear purpose, are practical to teach and substitute, and fit the programme engine. Novelty or obscure variations should not appear merely because an external database contains them.

## Current approval criteria

A movement must have a clear programme role and must be useful for at least one supported LeanIt context: resistance training, home training, running/cardio, core/mobility, warm-up or recovery. It should also be practical for the intended experience level and environment, have usable equipment/muscle/movement metadata, and be suitable for LeanIt's substitution logic.

Media approval is separate. A movement being programme-approved does **not** automatically approve a photograph or video. Existing LeanIt media-review rules still apply.

## Evidence principle

The curation model follows the product evidence hierarchy rather than claiming that one exercise is universally superior. The 2026 ACSM resistance-training position stand emphasizes progressive resistance training, training major muscle groups, individualisation, and notes that bodyweight, elastic resistance, machines and free weights can all be useful. WHO physical-activity guidance also supports regular aerobic activity plus muscle-strengthening work involving major muscle groups.

These sources support the programme-design principles. They do not mean every individual exercise in this file has been independently proven to be the single best exercise. Before store release, each approved movement should still receive exercise-level evidence/coach review and final media review.

Primary guideline references:

- American College of Sports Medicine (2026), *Resistance Training Prescription for Muscle Function, Hypertrophy, and Physical Performance in Healthy Adults: An Overview of Reviews*.
- World Health Organization (2020), *WHO Guidelines on Physical Activity and Sedentary Behaviour*.

## Release rule

1. Raw import -> not user-facing by default.
2. Programme-purpose review -> candidate.
3. Exercise metadata and substitution review -> approved movement.
4. Technique/media rights review -> publishable visual.
5. Coach/trainer and real-user review -> final release approval.

Adding another external exercise database must never bypass this gate.
''', encoding='utf-8')

print('Exercise curation patch applied.')
