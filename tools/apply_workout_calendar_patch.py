from pathlib import Path

path = Path('lib/progress_screen.dart')
text = path.read_text(encoding='utf-8')

old_import = "import 'training_store.dart';\n"
new_import = "import 'training_store.dart';\nimport 'workout_calendar_entry_section.dart';\n"
if old_import not in text:
    raise RuntimeError('progress screen import anchor missing')
text = text.replace(old_import, new_import, 1)

old_section = """                const SizedBox(height: 28),
                ExerciseProgressEntrySection(sets: sets),
"""
new_section = """                const SizedBox(height: 28),
                WorkoutCalendarEntrySection(records: records),
                const SizedBox(height: 28),
                ExerciseProgressEntrySection(sets: sets),
"""
if old_section not in text:
    raise RuntimeError('progress screen calendar anchor missing')
text = text.replace(old_section, new_section, 1)

path.write_text(text, encoding='utf-8')
