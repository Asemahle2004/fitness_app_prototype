from pathlib import Path

path = Path('lib/progress_screen.dart')
text = path.read_text(encoding='utf-8')

old_import = "import 'exercise_performance_store.dart';\n"
new_import = "import 'exercise_performance_store.dart';\nimport 'exercise_progress_entry_section.dart';\n"
if old_import not in text:
    raise RuntimeError('progress screen import anchor missing')
text = text.replace(old_import, new_import, 1)

old_section = """                const SizedBox(height: 28),
                const Text(
                  'Recent set performance',
"""
new_section = """                const SizedBox(height: 28),
                ExerciseProgressEntrySection(sets: sets),
                const SizedBox(height: 28),
                const Text(
                  'Recent set performance',
"""
if old_section not in text:
    raise RuntimeError('progress screen section anchor missing')
text = text.replace(old_section, new_section, 1)

path.write_text(text, encoding='utf-8')
