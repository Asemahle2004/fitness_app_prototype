from pathlib import Path

path = Path('lib/main.dart')
text = path.read_text(encoding='utf-8')


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected 1 match, found {count}')
    return source.replace(old, new, 1)

text = replace_once(
    text,
    "import 'account_screen.dart';\n",
    "import 'account_screen.dart';\nimport 'member_shell.dart';\n",
    'member shell import',
)

old = """completedHomeBuilder: (profile) => ProgrammeReadyScreen(
          goal: profile['main_goal']?.toString() ?? 'Improve General Fitness',
          experience: profile['experience']?.toString() ?? 'Beginner',
          fitnessLevel: profile['fitness_level']?.toString() ?? 'Low',
          availableDays: _profileStringSet(profile['available_days']),
          locations: _profileStringSet(profile['training_locations']),
          homeEquipment: _profileStringSet(profile['home_equipment']),
          gymAccess: profile['gym_access']?.toString(),
          sessionLength: profile['session_length']?.toString() ?? '45 min',
          trainingTime: profile['training_time']?.toString() ?? 'Flexible',
          hasLimitation: profile['has_limitation'] == true,
          affectedAreas: _profileStringSet(profile['affected_areas']),
          limitationNotes: profile['limitation_notes']?.toString() ?? '',
          warningSigns: _profileStringSet(profile['warning_signs']),
          isMemberHome: true,
        ),"""

new = """completedHomeBuilder: (profile) => LeanEatMemberShell(
          programmeHome: ProgrammeReadyScreen(
            goal: profile['main_goal']?.toString() ?? 'Improve General Fitness',
            experience: profile['experience']?.toString() ?? 'Beginner',
            fitnessLevel: profile['fitness_level']?.toString() ?? 'Low',
            availableDays: _profileStringSet(profile['available_days']),
            locations: _profileStringSet(profile['training_locations']),
            homeEquipment: _profileStringSet(profile['home_equipment']),
            gymAccess: profile['gym_access']?.toString(),
            sessionLength: profile['session_length']?.toString() ?? '45 min',
            trainingTime: profile['training_time']?.toString() ?? 'Flexible',
            hasLimitation: profile['has_limitation'] == true,
            affectedAreas: _profileStringSet(profile['affected_areas']),
            limitationNotes: profile['limitation_notes']?.toString() ?? '',
            warningSigns: _profileStringSet(profile['warning_signs']),
            isMemberHome: true,
          ),
        ),"""

text = replace_once(text, old, new, 'completed member home')
path.write_text(text, encoding='utf-8')
print('Integrated persistent LeanEat member shell.')
