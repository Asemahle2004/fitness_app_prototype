from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding='utf-8')
    if old not in text:
        raise RuntimeError(f'Patch anchor missing in {path}: {old[:200]}')
    file.write_text(text.replace(old, new, 1), encoding='utf-8')


replace_once(
    'lib/workout_engine.dart',
    """      case '15 min':
        maxExercises = 3;
        break;
      case '30 min':
""",
    """      case '15 min':
      case '20 min':
        maxExercises = 3;
        break;
      case '30 min':
""",
)
