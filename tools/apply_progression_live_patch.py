from pathlib import Path

path = Path('lib/live_workout_screen.dart')
text = path.read_text(encoding='utf-8')


def replace_once(old: str, new: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'Expected exactly one match, found {count}: {old[:80]!r}')
    text = text.replace(old, new, 1)


replace_once(
    "import 'exercise_performance_store.dart';\nimport 'exercise_swap_service.dart';",
    "import 'exercise_performance_store.dart';\nimport 'exercise_swap_service.dart';\nimport 'progression_engine.dart';",
)

replace_once(
    "  ExerciseSetPerformance? _previousPerformance;\n  bool _performanceLoading = false;",
    "  ExerciseSetPerformance? _previousPerformance;\n  ProgressionSuggestion? _progressionSuggestion;\n  bool _performanceLoading = false;",
)

replace_once(
    "    _previousPerformance = null;\n    _performanceLoading = true;",
    "    _previousPerformance = null;\n    _progressionSuggestion = null;\n    _performanceLoading = true;",
)

replace_once(
    """      setState(() {
        _previousPerformance = previous;
        _performanceLoading = false;
        if (previous?.weightKg != null && _weightController.text.isEmpty) {
          final weight = previous!.weightKg!;
          _weightController.text = weight % 1 == 0
              ? weight.toStringAsFixed(0)
              : weight.toStringAsFixed(1);
        }
      });""",
    """      setState(() {
        _previousPerformance = previous;
        _progressionSuggestion = ProgressionEngine.suggest(
          exercise: currentExercise,
          previous: previous,
        );
        _performanceLoading = false;

        final suggestion = _progressionSuggestion;
        if (suggestion?.targetReps != null) {
          targetReps = suggestion!.targetReps!;
        }
        if (suggestion?.targetDurationSeconds != null) {
          workSecondsTarget = suggestion!.targetDurationSeconds!;
          workSecondsRemaining = workSecondsTarget;
        }

        final suggestedWeight = suggestion?.targetWeightKg;
        if (suggestedWeight != null && _weightController.text.isEmpty) {
          _weightController.text = _formatWeight(suggestedWeight);
        } else if (previous?.weightKg != null && _weightController.text.isEmpty) {
          _weightController.text = _formatWeight(previous!.weightKg!);
        }
      });""",
)

replace_once(
    """                    _previousPerformanceCard(),
                    const SizedBox(height: 14),
                    if (currentIsTimed)""",
    """                    _previousPerformanceCard(),
                    if (_progressionSuggestion != null) ...[
                      const SizedBox(height: 10),
                      _progressionSuggestionCard(),
                    ],
                    const SizedBox(height: 14),
                    if (currentIsTimed)""",
)

marker = "\n  Widget _repControls(ExercisePrescription exercise) {"
if marker not in text:
    raise SystemExit('Could not find _repControls insertion marker')

method = r'''

  Widget _progressionSuggestionCard() {
    final suggestion = _progressionSuggestion;
    if (suggestion == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8DC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E89A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.trending_up_rounded, color: Color(0xFF0F6B4B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LeanEat progression suggestion',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF55721B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.headline,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.explanation,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF627D98),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This is a suggested starting target, not a requirement. Reduce it if form, comfort or readiness is worse today.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: Color(0xFF829AB1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
'''

text = text.replace(marker, method + marker, 1)
path.write_text(text, encoding='utf-8')
print('Patched live_workout_screen.dart with progressive overload targets.')
