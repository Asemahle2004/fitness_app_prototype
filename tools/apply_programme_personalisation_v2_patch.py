from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding='utf-8')
    if old not in text:
        raise RuntimeError(f'Patch anchor missing in {path}: {old[:200]}')
    file.write_text(text.replace(old, new, 1), encoding='utf-8')


engine = Path('lib/programme_engine.dart')
text = engine.read_text(encoding='utf-8')
text = text.replace('preferred = preferred.clamp(1, 4);', 'preferred = preferred.clamp(1, 4).toInt();')
text = text.replace('preferred = preferred.clamp(1, 3);', 'preferred = preferred.clamp(1, 3).toInt();')
engine.write_text(text, encoding='utf-8')

replace_once(
    'lib/today_dashboard.dart',
    """                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _statChip(Icons.schedule_rounded, session.duration),
                          _statChip(Icons.place_outlined, session.location),
                          _statChip(
                            Icons.format_list_numbered_rounded,
                            'Session ${shownIndex + 1}/${programme.sessions.length}',
                          ),
                        ],
                      ),
""",
    """                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _statChip(Icons.schedule_rounded, session.duration),
                          _statChip(Icons.place_outlined, session.location),
                          _statChip(Icons.bolt_rounded, session.intensity),
                          _statChip(
                            Icons.format_list_numbered_rounded,
                            'Session ${shownIndex + 1}/${programme.sessions.length}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        session.focus,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF245B69),
                        ),
                      ),
                      if (session.personalisationNote.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          session.personalisationNote,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF627D98),
                          ),
                        ),
                      ],
""",
)
