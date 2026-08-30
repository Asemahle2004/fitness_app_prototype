from pathlib import Path

path = Path('lib/live_workout_screen.dart')
text = path.read_text(encoding='utf-8')

old_import = "import 'movement_visual.dart';\nimport 'training_store.dart';"
new_import = "import 'exercise_media.dart';\nimport 'movement_visual.dart';\nimport 'training_store.dart';"
if old_import not in text:
    raise SystemExit('live media import point not found')
text = text.replace(old_import, new_import, 1)

old_visual = """                        child: exercise.visualAsset != null
                            ? Image.asset(
                                exercise.visualAsset!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => MovementVisual(
                                  exerciseName: exercise.name,
                                ),
                              )
                            : MovementVisual(exerciseName: exercise.name),"""
new_visual = """                        child: ExerciseMedia(
                          exerciseName: exercise.name,
                          localAsset: exercise.visualAsset,
                          fit: BoxFit.contain,
                        ),"""
if old_visual not in text:
    raise SystemExit('live exercise visual block not found')
text = text.replace(old_visual, new_visual, 1)

path.write_text(text, encoding='utf-8')
print('Universal live exercise media enabled')
