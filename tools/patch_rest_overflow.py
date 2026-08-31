from pathlib import Path

path = Path('lib/live_workout_screen.dart')
text = path.read_text(encoding='utf-8')

old = '''    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.timer_outlined,
              size: 74,
              color: Color(0xFF176B87),
            ),
            const SizedBox(height: 18),
            const Text(
              'REST',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF627D98),
              ),
            ),
            Text(
              _formatClock(restSecondsRemaining),
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102A43),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              nextSet
                  ? 'Next: Set ${currentSet + 1} of ${currentExercise.sets} • ${currentExercise.name}'
                  : 'Next exercise: $nextExercise',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF486581),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => _adjustRest(-15),
                  child: const Text('-15 sec'),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => _adjustRest(15),
                  child: const Text('+15 sec'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _skipRest,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF176B87),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'SKIP REST',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );'''

new = '''    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 520;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            compact ? 14 : 28,
            24,
            24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - (compact ? 38 : 52))
                  .clamp(0.0, double.infinity),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: compact ? 54 : 74,
                    color: const Color(0xFF176B87),
                  ),
                  SizedBox(height: compact ? 8 : 18),
                  const Text(
                    'REST',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF627D98),
                    ),
                  ),
                  Text(
                    _formatClock(restSecondsRemaining),
                    style: TextStyle(
                      fontSize: compact ? 58 : 72,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nextSet
                        ? 'Next: Set ${currentSet + 1} of ${currentExercise.sets} • ${currentExercise.name}'
                        : 'Next exercise: $nextExercise',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF486581),
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => _adjustRest(-15),
                        child: const Text('-15 sec'),
                      ),
                      OutlinedButton(
                        onPressed: () => _adjustRest(15),
                        child: const Text('+15 sec'),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 10 : 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _skipRest,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: const Color(0xFF176B87),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'SKIP REST',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );'''

if old not in text:
    raise SystemExit('Could not find rest view block to patch')

text = text.replace(old, new, 1)
path.write_text(text, encoding='utf-8')
print('rest overflow patch applied')
