from pathlib import Path

# --- main.dart: add Progress + Readiness entry points ---
path = Path('lib/main.dart')
text = path.read_text(encoding='utf-8')

old_imports = "import 'exercise_library_screen.dart';\nimport 'package:supabase_flutter/supabase_flutter.dart';"
new_imports = "import 'exercise_library_screen.dart';\nimport 'progress_screen.dart';\nimport 'readiness_screen.dart';\nimport 'package:supabase_flutter/supabase_flutter.dart';"
if old_imports not in text:
    raise SystemExit('main imports block not found')
text = text.replace(old_imports, new_imports, 1)

old_tail = """              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExerciseLibraryScreen(client: supabase),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text(
                    'BROWSE ALL EXERCISES',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF176B87),
                    side: const BorderSide(color: Color(0xFF176B87)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),"""
new_tail = """              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExerciseLibraryScreen(client: supabase),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text(
                    'BROWSE ALL EXERCISES',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF176B87),
                    side: const BorderSide(color: Color(0xFF176B87)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProgressScreen()),
                        );
                      },
                      icon: const Icon(Icons.insights_outlined),
                      label: const Text('PROGRESS'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF176B87),
                        side: const BorderSide(color: Color(0xFFD9E2EC)),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReadinessScreen()),
                        );
                      },
                      icon: const Icon(Icons.battery_charging_full_outlined),
                      label: const Text('READINESS'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF176B87),
                        side: const BorderSide(color: Color(0xFFD9E2EC)),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),"""
if old_tail not in text:
    raise SystemExit('goal-screen button block not found')
text = text.replace(old_tail, new_tail, 1)
path.write_text(text, encoding='utf-8')

# --- live_workout_screen.dart: persist completed workouts and improve media size ---
path = Path('lib/live_workout_screen.dart')
text = path.read_text(encoding='utf-8')

old_import = "import 'movement_visual.dart';\nimport 'workout_engine.dart';"
new_import = "import 'movement_visual.dart';\nimport 'training_store.dart';\nimport 'workout_engine.dart';"
if old_import not in text:
    raise SystemExit('live imports block not found')
text = text.replace(old_import, new_import, 1)

old_state = """  int restSecondsRemaining = 0;

  bool get isComplete =>"""
new_state = """  int restSecondsRemaining = 0;
  bool _historySaved = false;

  bool get isComplete =>"""
if old_state not in text:
    raise SystemExit('live state insertion point not found')
text = text.replace(old_state, new_state, 1)

old_finish = """    if (completedExercises >= widget.workout.exercises.length) {
      setState(() => phase = LivePhase.ready);
      return;
    }"""
new_finish = """    if (completedExercises >= widget.workout.exercises.length) {
      setState(() => phase = LivePhase.ready);
      _saveHistory();
      return;
    }"""
if old_finish not in text:
    raise SystemExit('finish workout block not found')
text = text.replace(old_finish, new_finish, 1)

insert_before = """  void _skipRest() => _advanceAfterRest();
"""
insert = """  Future<void> _saveHistory() async {
    if (_historySaved) return;
    _historySaved = true;
    await TrainingStore.saveWorkout(
      WorkoutRecord(
        title: widget.workout.title,
        completedAt: DateTime.now(),
        durationSeconds: workoutSeconds,
        completedSets: completedSets,
        exercises: widget.workout.exercises
            .map((exercise) => exercise.name)
            .toList(growable: false),
      ),
    );
  }

  void _skipRest() => _advanceAfterRest();
"""
if insert_before not in text:
    raise SystemExit('history insertion point not found')
text = text.replace(insert_before, insert, 1)

# Bigger coach visual: 210 -> 290.
text = text.replace('height: 210,', 'height: 290,', 1)

# Add saved-history confirmation to complete screen if a stable sentence exists.
needle = "'Workout complete'"
if needle not in text:
    raise SystemExit('completion screen not found')
# No invasive replacement; completion is already sufficient.

path.write_text(text, encoding='utf-8')
print('LeanIt v1 completion patch applied')
