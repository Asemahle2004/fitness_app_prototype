from pathlib import Path

path = Path('lib/main.dart')
text = path.read_text(encoding='utf-8')


def replace_once(old: str, new: str, label: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected 1 match, found {count}')
    text = text.replace(old, new, 1)

replace_once(
    "import 'movement_visual.dart';\n",
    "import 'exercise_media.dart';\n",
    'main exercise media import',
)

replace_once(
"""child: MovementVisual(
                                    exerciseName: exercise.name,
                                    compact: true,
                                  ),""",
"""child: ExerciseMedia(
                                    exerciseName: exercise.name,
                                    localAsset: exercise.visualAsset,
                                    fit: BoxFit.cover,
                                    compact: true,
                                  ),""",
    'workout card media',
)

old_helpers = """  Widget _placeholderVisual([String? movementPattern]) {
    return MovementVisual(
      exerciseName: exercise.name,
      movementPattern: movementPattern,
    );
  }

  Widget _localVisual([String? movementPattern]) {
    final visualAsset = exercise.visualAsset;
    if (visualAsset == null || visualAsset.isEmpty) {
      return _placeholderVisual(movementPattern);
    }

    return Image.asset(
      visualAsset,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          _placeholderVisual(movementPattern),
    );
  }

"""
replace_once(old_helpers, '', 'remove diagram helpers')

old_visual = """  Widget _exerciseVisual(
    OnlineExercise? onlineExercise, {
    required bool isLoading,
  }) {
    final imagePath = onlineExercise?.imagePath;

    if (imagePath != null && imagePath.isNotEmpty) {
      final imageUrl = _exerciseRepository.publicImageUrl(imagePath);
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _localVisual(onlineExercise?.movementPattern),
      );
    }

    if (isLoading && exercise.visualAsset == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return _localVisual(onlineExercise?.movementPattern);
  }
"""
new_visual = """  Widget _exerciseVisual(
    OnlineExercise? onlineExercise, {
    required bool isLoading,
  }) {
    if (isLoading && exercise.visualAsset == null && onlineExercise == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ExerciseMedia(
      exerciseName: exercise.name,
      localAsset: exercise.visualAsset,
      movementPattern: onlineExercise?.movementPattern,
      fit: BoxFit.contain,
    );
  }
"""
replace_once(old_visual, new_visual, 'exercise detail media')

path.write_text(text, encoding='utf-8')
print('Main workout list and exercise details now use photo-first gender-aware media.')
