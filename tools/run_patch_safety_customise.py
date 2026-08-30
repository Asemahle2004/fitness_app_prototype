from pathlib import Path

source_path = Path('tools/patch_safety_customise.py')
source = source_path.read_text(encoding='utf-8')

old_block = '''replace_once(
"""    required this.hasLimitation,
    required this.affectedAreas,
  });""",
"""    required this.hasLimitation,
    required this.affectedAreas,
    required this.limitationNotes,
    required this.warningSigns,
  });""",
    'programme safety constructor',
)'''

new_block = '''old = """    required this.hasLimitation,
    required this.affectedAreas,
  });"""
new = """    required this.hasLimitation,
    required this.affectedAreas,
    required this.limitationNotes,
    required this.warningSigns,
  });"""
if old not in text:
    raise SystemExit('programme safety constructor: no match')
text = text.replace(old, new, 1)'''

if old_block not in source:
    raise SystemExit('Could not patch the one-time patch script')

source = source.replace(old_block, new_block, 1)
exec(compile(source, str(source_path), 'exec'))
