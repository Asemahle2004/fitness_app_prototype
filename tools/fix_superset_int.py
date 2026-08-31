from pathlib import Path

path = Path('lib/live_workout_screen.dart')
text = path.read_text(encoding='utf-8')
old = """    _completedSetsByExercise[currentIndex] =\n        (_completedSetsByExercise[currentIndex] + 1).clamp(0, exercise.sets);\n"""
new = """    _completedSetsByExercise[currentIndex] =\n        (_completedSetsByExercise[currentIndex] + 1)\n            .clamp(0, exercise.sets)\n            .toInt();\n"""
if new not in text:
    if old not in text:
        raise RuntimeError('Superset set-counter pattern not found.')
    path.write_text(text.replace(old, new, 1), encoding='utf-8')
print('Superset integer counter fix applied.')
