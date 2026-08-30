from pathlib import Path

path = Path('lib/main.dart')
text = path.read_text(encoding='utf-8')

old_import = "import 'exercise_repository.dart';\n"
new_import = "import 'exercise_repository.dart';\nimport 'live_workout_screen.dart';\n"
if old_import not in text:
    raise SystemExit('exercise_repository import not found')
if "import 'live_workout_screen.dart';" not in text:
    text = text.replace(old_import, new_import, 1)

old_button = """                  onPressed: widget.hasLimitation
                      ? null
                      : () {
                          // Live Workout Mode comes next.
                        },
"""
new_button = """                  onPressed: widget.hasLimitation
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LiveWorkoutScreen(
                                workout: workout,
                              ),
                            ),
                          );
                        },
"""
count = text.count(old_button)
if count != 1:
    raise SystemExit(f'START WORKOUT block: expected 1 match, found {count}')
text = text.replace(old_button, new_button, 1)

path.write_text(text, encoding='utf-8')
print('Live workout wired successfully')
