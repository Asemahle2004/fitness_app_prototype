from pathlib import Path

path = Path('lib/progress_screen.dart')
text = path.read_text(encoding='utf-8')

old_import = "import 'exercise_progress_entry_section.dart';\n"
new_import = "import 'exercise_progress_entry_section.dart';\nimport 'run_tracking_entry_section.dart';\n"
if old_import not in text:
    raise RuntimeError('progress screen import anchor missing')
text = text.replace(old_import, new_import, 1)

old_section = """                const BodyProgressEntrySection(),
                const SizedBox(height: 28),
                WorkoutCalendarEntrySection(records: records),
"""
new_section = """                const BodyProgressEntrySection(),
                const SizedBox(height: 28),
                const RunTrackingEntrySection(),
                const SizedBox(height: 28),
                WorkoutCalendarEntrySection(records: records),
"""
if old_section not in text:
    raise RuntimeError('progress screen running anchor missing')
text = text.replace(old_section, new_section, 1)

path.write_text(text, encoding='utf-8')
