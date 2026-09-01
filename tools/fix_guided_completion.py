from pathlib import Path

path = Path('lib/live_run_screen.dart')
text = path.read_text()

old = """  Future<void> _resume() async {
    if (!_running || !_paused) return;
"""
new = """  Future<void> _resume() async {
    if (!_running || !_paused || _guidedCompleteHandled) return;
"""
if old not in text:
    raise SystemExit('resume anchor not found')
text = text.replace(old, new, 1)

old = """                        onPressed: _paused ? _resume : _pause,
                        icon: Icon(
                          _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        ),
                        label: Text(_paused ? 'RESUME' : 'PAUSE'),
"""
new = """                        onPressed: _guidedCompleteHandled
                            ? null
                            : (_paused ? _resume : _pause),
                        icon: Icon(
                          _guidedCompleteHandled
                              ? Icons.check_rounded
                              : _paused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                        ),
                        label: Text(
                          _guidedCompleteHandled
                              ? 'COMPLETE'
                              : _paused
                                  ? 'RESUME'
                                  : 'PAUSE',
                        ),
"""
if old not in text:
    raise SystemExit('pause/resume button anchor not found')
text = text.replace(old, new, 1)
path.write_text(text)
