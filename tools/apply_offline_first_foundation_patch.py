from pathlib import Path
import re


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding='utf-8')
    if old not in text:
        raise RuntimeError(f'Patch anchor missing in {path}: {old[:180]}')
    file.write_text(text.replace(old, new, 1), encoding='utf-8')


# Generate the compact built-in programme catalogue directly from the exercise
# names WorkoutEngine can prescribe. This guarantees that a generated workout
# never references a movement that is absent from LeanIt's library offline.
workout_path = Path('lib/workout_engine.dart')
workout_text = workout_path.read_text(encoding='utf-8')
names = sorted(set(re.findall(r"_e\(\s*'([^']+)'", workout_text)), key=str.lower)
if not names:
    raise RuntimeError('Could not discover WorkoutEngine exercise names')

catalogue_lines = [
    '// GENERATED FROM WorkoutEngine. Keep this file small: names only.',
    '// Rich metadata/media from Supabase or the free catalogue replaces these',
    '// fallback entries whenever it is available.',
    '',
    'const Set<String> offlineProgrammeExerciseNames = <String>{',
]
for name in names:
    escaped = name.replace('\\', '\\\\').replace("'", "\\'")
    catalogue_lines.append(f"  '{escaped}',")
catalogue_lines.extend(['};', ''])
Path('lib/offline_programme_exercises.dart').write_text(
    '\n'.join(catalogue_lines), encoding='utf-8'
)

# Replace exercise-count trimming with a real time budget. The estimate includes
# guided preparation/cool-down, working time, rest and exercise transitions.
pattern = re.compile(
    r"  static GeneratedWorkout _fitToDuration\([\s\S]*?\n  static const Set<String> _runningTitles",
    re.MULTILINE,
)
replacement = r'''  static GeneratedWorkout _fitToDuration(
    GeneratedWorkout workout,
    String? sessionDuration,
  ) {
    final targetSeconds = _targetDurationSeconds(sessionDuration);
    if (targetSeconds == null || workout.exercises.isEmpty) return workout;

    final fixedSeconds = _preparationAndCooldownSeconds(targetSeconds);

    // A single continuous running/cardio block can use the remaining session
    // budget directly instead of pretending a fixed 20 minute block fills a
    // 45 or 60 minute session.
    if (workout.exercises.length == 1 &&
        workout.exercises.first.isSingleDurationBlock &&
        workout.exercises.first.reps.toLowerCase().contains('min')) {
      final exercise = workout.exercises.first;
      final availableMinutes = ((targetSeconds - fixedSeconds) / 60)
          .round()
          .clamp(5, 120)
          .toInt();
      final qualifier = _durationQualifier(exercise.reps);
      final adjusted = exercise.copyWith(
        reps: '$availableMinutes min${qualifier.isEmpty ? '' : ' $qualifier'}',
      );
      return GeneratedWorkout(title: workout.title, exercises: [adjusted]);
    }

    final selected = <ExercisePrescription>[];
    var usedSeconds = fixedSeconds;

    for (final exercise in workout.exercises) {
      final cost = _exerciseEstimatedSeconds(
        exercise,
        includeTransition: selected.isNotEmpty,
      );
      if (selected.isEmpty || usedSeconds + cost <= targetSeconds + 45) {
        selected.add(exercise);
        usedSeconds += cost;
      }
    }

    // Keep a useful minimum when a very short session contains expensive
    // prescriptions. Sets are reduced below if necessary.
    for (final exercise in workout.exercises) {
      if (selected.length >= 2 || selected.contains(exercise)) continue;
      selected.add(exercise);
      usedSeconds += _exerciseEstimatedSeconds(
        exercise,
        includeTransition: selected.length > 1,
      );
    }

    var tuned = List<ExercisePrescription>.from(selected);

    // Use spare time for an additional working set on existing movements,
    // capped at four sets. This keeps 45/60 minute plans close to the selected
    // duration without padding sessions with fake waiting time.
    var madeChange = true;
    while (targetSeconds - usedSeconds > 90 && madeChange) {
      madeChange = false;
      for (var i = 0; i < tuned.length; i += 1) {
        final exercise = tuned[i];
        if (exercise.isSingleDurationBlock || exercise.sets >= 4) continue;
        final extra = _additionalSetSeconds(exercise);
        if (usedSeconds + extra <= targetSeconds + 45) {
          tuned[i] = exercise.copyWith(sets: exercise.sets + 1);
          usedSeconds += extra;
          madeChange = true;
        }
        if (targetSeconds - usedSeconds <= 90) break;
      }
    }

    // If the minimum selection slightly overran a short budget, reduce the
    // least-priority later exercises to two sets before dropping an exercise.
    for (var i = tuned.length - 1;
        i >= 0 && usedSeconds > targetSeconds + 60;
        i -= 1) {
      final exercise = tuned[i];
      if (exercise.isSingleDurationBlock || exercise.sets <= 2) continue;
      final saved = _additionalSetSeconds(exercise);
      tuned[i] = exercise.copyWith(sets: exercise.sets - 1);
      usedSeconds -= saved;
    }

    while (tuned.length > 2 && usedSeconds > targetSeconds + 60) {
      final removed = tuned.removeLast();
      usedSeconds -= _exerciseEstimatedSeconds(
        removed,
        includeTransition: tuned.isNotEmpty,
      );
    }

    return GeneratedWorkout(title: workout.title, exercises: tuned);
  }

  /// Estimated wall-clock workout time including the guided preparation and
  /// cool-down phases, working sets, prescribed rests and exercise transitions.
  static int estimateDurationSeconds(
    GeneratedWorkout workout, {
    String? sessionDuration,
  }) {
    final target = _targetDurationSeconds(sessionDuration);
    var total = target == null ? 0 : _preparationAndCooldownSeconds(target);
    for (var i = 0; i < workout.exercises.length; i += 1) {
      total += _exerciseEstimatedSeconds(
        workout.exercises[i],
        includeTransition: i > 0,
      );
    }
    return total;
  }

  static int? _targetDurationSeconds(String? label) {
    if (label == null) return null;
    final match = RegExp(r'(\d+)').firstMatch(label);
    final minutes = int.tryParse(match?.group(1) ?? '');
    return minutes == null ? null : minutes * 60;
  }

  static int _preparationAndCooldownSeconds(int targetSeconds) {
    if (targetSeconds <= 15 * 60) return 5 * 60;
    if (targetSeconds <= 20 * 60) return 7 * 60;
    if (targetSeconds <= 30 * 60) return 9 * 60;
    if (targetSeconds <= 45 * 60) return 12 * 60;
    return 15 * 60;
  }

  static int _exerciseEstimatedSeconds(
    ExercisePrescription exercise, {
    required bool includeTransition,
  }) {
    final transition = includeTransition ? 40 : 0;
    if (exercise.isSingleDurationBlock) {
      final minutes = _minutesFromTarget(exercise.reps);
      if (minutes != null) return (minutes * 60).round() + transition;
    }

    final workPerSet = _workSecondsPerSet(exercise.reps);
    final rest = _restSeconds(exercise.rest);
    final betweenSetRest = exercise.sets <= 1 ? 0 : (exercise.sets - 1) * rest;
    return (exercise.sets * workPerSet) + betweenSetRest + transition;
  }

  static int _additionalSetSeconds(ExercisePrescription exercise) {
    return _workSecondsPerSet(exercise.reps) + _restSeconds(exercise.rest);
  }

  static int _workSecondsPerSet(String target) {
    final lower = target.toLowerCase();
    final seconds = RegExp(r'(\d+)\s*[–-]\s*(\d+)\s*sec').firstMatch(lower);
    if (seconds != null) {
      return ((int.parse(seconds.group(1)!) + int.parse(seconds.group(2)!)) / 2)
          .round();
    }
    final singleSeconds = RegExp(r'(\d+)\s*sec').firstMatch(lower);
    if (singleSeconds != null) return int.parse(singleSeconds.group(1)!);

    final numbers = RegExp(r'\d+').allMatches(lower).map((m) => int.parse(m.group(0)!)).toList();
    var reps = numbers.isEmpty
        ? 10.0
        : numbers.length >= 2
            ? (numbers[0] + numbers[1]) / 2
            : numbers.first.toDouble();
    if (lower.contains('each side') || lower.contains('each leg')) reps *= 1.7;
    return (reps * 4).round().clamp(25, 90).toInt();
  }

  static int _restSeconds(String rest) {
    final lower = rest.toLowerCase();
    final seconds = RegExp(r'(\d+)\s*sec').firstMatch(lower);
    if (seconds != null) return int.parse(seconds.group(1)!);
    final minutes = RegExp(r'(\d+)\s*min').firstMatch(lower);
    if (minutes != null) return int.parse(minutes.group(1)!) * 60;
    return 60;
  }

  static double? _minutesFromTarget(String target) {
    final lower = target.toLowerCase();
    final range = RegExp(r'(\d+)\s*[–-]\s*(\d+)\s*min').firstMatch(lower);
    if (range != null) {
      return (int.parse(range.group(1)!) + int.parse(range.group(2)!)) / 2;
    }
    final single = RegExp(r'(\d+)\s*min').firstMatch(lower);
    if (single != null) return int.parse(single.group(1)!).toDouble();
    return null;
  }

  static String _durationQualifier(String target) {
    final match = RegExp(r'\d+(?:\s*[–-]\s*\d+)?\s*min\s*(.*)', caseSensitive: false)
        .firstMatch(target);
    return match?.group(1)?.trim() ?? '';
  }

  static const Set<String> _runningTitles'''
new_text, count = pattern.subn(replacement, workout_text, count=1)
if count != 1:
    raise RuntimeError('Could not replace WorkoutEngine duration fitter')
workout_path.write_text(new_text, encoding='utf-8')

# ExerciseRepository: merge the guaranteed built-in programme vocabulary with
# richer cached/network records. Richer records win by ID.
replace_once(
    'lib/exercise_repository.dart',
    "import 'package:supabase_flutter/supabase_flutter.dart';\n",
    "import 'package:supabase_flutter/supabase_flutter.dart';\n\nimport 'offline_programme_exercises.dart';\n",
)
replace_once(
    'lib/exercise_repository.dart',
    "  Future<List<OnlineExercise>> fetchAll() async {\n    final merged = <String, OnlineExercise>{};\n\n    final freeCatalogue = await _freeCatalogueSafely();\n",
    "  Future<List<OnlineExercise>> fetchAll() async {\n    final merged = <String, OnlineExercise>{};\n\n    // These tiny built-in records make every programme exercise available in\n    // the library even before the first catalogue download.\n    for (final name in offlineProgrammeExerciseNames) {\n      final exercise = _offlineProgrammeExercise(name);\n      merged[exercise.id] = exercise;\n    }\n\n    final freeCatalogue = await _freeCatalogueSafely();\n",
)
replace_once(
    'lib/exercise_repository.dart',
    "    final catalogue = await _freeCatalogueSafely();\n    for (final exercise in catalogue) {\n      if (exercise.id == exerciseId) return exercise;\n    }\n    return null;\n  }\n\n  Future<List<OnlineExercise>> fetchAll() async {",
    "    final catalogue = await _freeCatalogueSafely();\n    for (final exercise in catalogue) {\n      if (exercise.id == exerciseId) return exercise;\n    }\n    for (final name in offlineProgrammeExerciseNames) {\n      final exercise = _offlineProgrammeExercise(name);\n      if (exercise.id == exerciseId) return exercise;\n    }\n    return null;\n  }\n\n  OnlineExercise _offlineProgrammeExercise(String name) {\n    final lower = name.toLowerCase();\n    final equipment = lower.contains('dumbbell')\n        ? <String>['Dumbbell']\n        : lower.contains('barbell') || lower.contains('deadlift')\n            ? <String>['Barbell']\n            : lower.contains('cable') || lower.contains('pulldown')\n                ? <String>['Cable / machine']\n                : lower.contains('leg press') || lower.contains('machine')\n                    ? <String>['Machine']\n                    : lower.contains('band')\n                        ? <String>['Resistance Bands']\n                        : <String>['Bodyweight'];\n    final primary = lower.contains('squat') ||\n            lower.contains('lunge') ||\n            lower.contains('leg press')\n        ? <String>['Quads', 'Glutes']\n        : lower.contains('row') ||\n                lower.contains('pulldown') ||\n                lower.contains('pull-up')\n            ? <String>['Back', 'Biceps']\n            : lower.contains('press') || lower.contains('push-up')\n                ? <String>['Chest', 'Shoulders', 'Triceps']\n                : lower.contains('deadlift') ||\n                        lower.contains('bridge') ||\n                        lower.contains('hinge')\n                    ? <String>['Hamstrings', 'Glutes']\n                    : lower.contains('plank') ||\n                            lower.contains('bird dog') ||\n                            lower.contains('core')\n                        ? <String>['Core']\n                        : <String>['General fitness'];\n    return OnlineExercise(\n      id: idFromName(name),\n      name: name,\n      category: 'LeanIt programme',\n      primaryMuscles: primary,\n      secondaryMuscles: const <String>[],\n      equipment: equipment,\n      difficulty: null,\n      movementPattern: null,\n      locations: const <String>['Home', 'Gym', 'Outside'],\n      instructions: const <String>[\n        'Follow the set, rep and rest prescription shown in your LeanIt workout.',\n        'Use controlled technique and stop the movement if it causes new or increasing pain.',\n      ],\n      commonMistakes: const <String>[],\n      imagePath: null,\n      videoPath: null,\n      maleImagePath: null,\n      femaleImagePath: null,\n      maleVideoPath: null,\n      femaleVideoPath: null,\n      maleImageReviewed: false,\n      femaleImageReviewed: false,\n      mediaSource: 'LeanIt built-in offline catalogue',\n      mediaLicense: null,\n      mediaReviewNotes: '[offline-programme] Minimal offline metadata; richer catalogue data replaces this when available.',\n    );\n  }\n\n  Future<List<OnlineExercise>> fetchAll() async {",
)

# Smaller on-device image cache: keep network images useful offline after they
# have been viewed, but store reduced-resolution files rather than originals.
replace_once(
    'lib/exercise_media.dart',
    "      fadeInDuration: const Duration(milliseconds: 120),\n      placeholder: (_, __) => _loadingPhoto(),\n",
    "      fadeInDuration: const Duration(milliseconds: 120),\n      maxWidthDiskCache: widget.compact ? 360 : 720,\n      maxHeightDiskCache: widget.compact ? 360 : 720,\n      memCacheWidth: widget.compact ? 360 : 720,\n      placeholder: (_, __) => _loadingPhoto(),\n",
)

# Workout detail screen: show a calculated wall-clock estimate instead of
# equating a fixed number of exercises with 45/60 minutes.
replace_once(
    'lib/main.dart',
    "    final workout = adaptation.workout;\n\n    return Scaffold(\n",
    "    final workout = adaptation.workout;\n    final estimatedMinutes = (WorkoutEngine.estimateDurationSeconds(\n              workout,\n              sessionDuration: widget.session.duration,\n            ) /\n            60)\n        .round();\n\n    return Scaffold(\n",
)
replace_once(
    'lib/main.dart',
    "                      '${widget.session.duration} • '\n                      '${workout.exercises.length} exercises',\n",
    "                      '≈$estimatedMinutes min including warm-up, sets, rest & cool-down • '\n                      '${workout.exercises.length} exercises',\n",
)

# Account screen must use the same local-first profile service, otherwise an
# offline user could open the app but still fail on the Account tab.
account = Path('lib/account_screen.dart')
account_text = account.read_text(encoding='utf-8')
account_pattern = re.compile(
    r"  Future<Map<String, dynamic>\?> _loadProfile\(\) async \{[\s\S]*?\n  \}\n\n  @override\n  void dispose",
    re.MULTILINE,
)
account_replacement = '''  Future<Map<String, dynamic>?> _loadProfile() async {\n    final row = await _profiles.currentProfileMap();\n    if (row != null) {\n      _nameController.text =\n          (row['display_name'] ?? row['full_name'] ?? '').toString();\n      final pref = row['visual_preference'] as String?;\n      _visualPreference = switch (pref) {\n        'Female' => 'Female',\n        'Male' => 'Male',\n        'Neutral' => 'Neutral',\n        _ => 'Match my profile',\n      };\n    }\n    return row;\n  }\n\n  @override\n  void dispose'''
account_text, count = account_pattern.subn(account_replacement, account_text, count=1)
if count != 1:
    raise RuntimeError('Could not patch Account profile loading')
account.write_text(account_text, encoding='utf-8')
