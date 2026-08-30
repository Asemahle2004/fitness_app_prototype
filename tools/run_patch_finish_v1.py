from pathlib import Path

source_path = Path('tools/patch_finish_v1.py')
source = source_path.read_text(encoding='utf-8')
source = source.replace(
    'old_imports = "import \'exercise_library_screen.dart\';\\nimport \'package:supabase_flutter/supabase_flutter.dart\';"',
    'old_imports = "import \'exercise_library_screen.dart\';\\nimport \'workout_structure.dart\';\\nimport \'package:supabase_flutter/supabase_flutter.dart\';"',
    1,
)
source = source.replace(
    'new_imports = "import \'exercise_library_screen.dart\';\\nimport \'progress_screen.dart\';\\nimport \'readiness_screen.dart\';\\nimport \'package:supabase_flutter/supabase_flutter.dart\';"',
    'new_imports = "import \'exercise_library_screen.dart\';\\nimport \'workout_structure.dart\';\\nimport \'progress_screen.dart\';\\nimport \'readiness_screen.dart\';\\nimport \'package:supabase_flutter/supabase_flutter.dart\';"',
    1,
)
exec(compile(source, str(source_path), 'exec'))
