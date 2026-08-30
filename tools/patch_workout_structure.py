from pathlib import Path

path = Path('lib/main.dart')
text = path.read_text(encoding='utf-8')

old_import = "import 'exercise_library_screen.dart';\nimport 'package:supabase_flutter/supabase_flutter.dart';"
new_import = "import 'exercise_library_screen.dart';\nimport 'workout_structure.dart';\nimport 'package:supabase_flutter/supabase_flutter.dart';"
if old_import not in text:
    raise SystemExit('import anchor not found')
text = text.replace(old_import, new_import, 1)

old = '''    final generatedWorkout = WorkoutEngine.generate(
      sessionTitle: widget.session.title,
      location: selectedLocation,
      homeEquipment: widget.homeEquipment,
      gymAccess: widget.gymAccess,
      sessionDuration: widget.session.duration,
    );
    final selectedWorkout = customExercises == null
        ? generatedWorkout
        : GeneratedWorkout(
            title: '${generatedWorkout.title} — Custom',
            exercises: customExercises!,
          );'''
new = '''    final generatedWorkout = WorkoutEngine.generate(
      sessionTitle: widget.session.title,
      location: selectedLocation,
      homeEquipment: widget.homeEquipment,
      gymAccess: widget.gymAccess,
      sessionDuration: widget.session.duration,
    );
    final structuredWorkout = WorkoutStructureEnhancer.enhance(
      generatedWorkout,
      sessionDuration: widget.session.duration,
      location: selectedLocation,
    );
    final selectedWorkout = customExercises == null
        ? structuredWorkout
        : GeneratedWorkout(
            title: '${structuredWorkout.title} — Custom',
            exercises: customExercises!,
          );'''
if old not in text:
    raise SystemExit('workout generation anchor not found')
text = text.replace(old, new, 1)

path.write_text(text, encoding='utf-8')
print('wired fuller workout structure')
