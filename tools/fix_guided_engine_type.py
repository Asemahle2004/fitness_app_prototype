from pathlib import Path

path = Path('lib/guided_run_engine.dart')
text = path.read_text()
old = "return (secondsIntoStep / current.durationSeconds).clamp(0, 1);"
new = "return (secondsIntoStep / current.durationSeconds).clamp(0, 1).toDouble();"
if old not in text:
    raise SystemExit('guided progress clamp anchor not found')
path.write_text(text.replace(old, new, 1))
