from pathlib import Path


def patch(path: str, replacements: list[tuple[str, str]]) -> None:
    file = Path(path)
    text = file.read_text(encoding='utf-8')
    original = text
    for old, new in replacements:
        text = text.replace(old, new)
    if text == original:
        raise RuntimeError(f'No visible brand replacements applied in {path}')
    file.write_text(text, encoding='utf-8')


patch(
    'lib/main.dart',
    [
        ("title: 'LeanEat'", "title: 'LeanIt'"),
        ("'LeanEat adapts with you.'", "'LeanIt adapts with you.'"),
        ("Text('LeanEat')", "Text('LeanIt')"),
    ],
)

patch(
    'lib/today_dashboard.dart',
    [
        ("'LeanEat'", "'LeanIt'"),
        ("'LeanEat could", "'LeanIt could"),
    ],
)

patch(
    'lib/account_screen.dart',
    [
        ("'LeanEat member'", "'LeanIt member'"),
    ],
)
