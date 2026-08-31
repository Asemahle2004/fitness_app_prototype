from pathlib import Path

library_path = Path('lib/exercise_library_screen.dart')
live_path = Path('lib/live_workout_screen.dart')
library = library_path.read_text(encoding='utf-8')
live = live_path.read_text(encoding='utf-8')


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected 1 match, found {count}')
    return text.replace(old, new, 1)

library = replace_once(
    library,
    "import 'movement_visual.dart';\n",
    "import 'exercise_media.dart';\n",
    'library media import',
)

old_thumb = """child: exercise.imagePath != null &&
                                                exercise.imagePath!.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.network(
                                                  _repository.publicImageUrl(
                                                    exercise.imagePath!,
                                                  ),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      MovementVisual(
                                                    exerciseName: exercise.name,
                                                    movementPattern:
                                                        exercise.movementPattern,
                                                    compact: true,
                                                  ),
                                                ),
                                              )
                                            : MovementVisual(
                                                exerciseName: exercise.name,
                                                movementPattern:
                                                    exercise.movementPattern,
                                                compact: true,
                                              ),"""
new_thumb = """child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: ExerciseMedia(
                                            exerciseName: exercise.name,
                                            movementPattern: exercise.movementPattern,
                                            fit: BoxFit.cover,
                                            compact: true,
                                          ),
                                        ),"""
library = replace_once(library, old_thumb, new_thumb, 'library thumbnail')

old_detail = """child: exercise.imagePath != null && exercise.imagePath!.isNotEmpty
                  ? Image.network(
                      repository.publicImageUrl(exercise.imagePath!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => MovementVisual(
                        exerciseName: exercise.name,
                        movementPattern: exercise.movementPattern,
                      ),
                    )
                  : MovementVisual(
                      exerciseName: exercise.name,
                      movementPattern: exercise.movementPattern,
                    ),"""
new_detail = """child: ExerciseMedia(
                  exerciseName: exercise.name,
                  movementPattern: exercise.movementPattern,
                  fit: BoxFit.contain,
                ),"""
library = replace_once(library, old_detail, new_detail, 'library detail media')

live = live.replace("import 'movement_visual.dart';\n", '', 1)

library_path.write_text(library, encoding='utf-8')
live_path.write_text(live, encoding='utf-8')
print('Exercise library and live workout now use photo-first media.')
