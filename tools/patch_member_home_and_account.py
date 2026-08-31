from pathlib import Path

main_path = Path('lib/main.dart')
account_path = Path('lib/account_screen.dart')
main = main_path.read_text(encoding='utf-8')
account = account_path.read_text(encoding='utf-8')


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected 1 match, found {count}')
    return text.replace(old, new, 1)


def replace_first(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f'{label}: no match')
    return text.replace(old, new, 1)

# ---------- main.dart ----------
main = replace_once(
    main,
    "final supabase = Supabase.instance.client;\n",
    "final supabase = Supabase.instance.client;\n\nSet<String> _profileStringSet(dynamic value) {\n  if (value is! List) return <String>{};\n  return value.whereType<String>().toSet();\n}\n",
    'profile set helper',
)

main = replace_once(
    main,
    "home: const LeanEatAuthGate(signedInHome: WelcomeScreen()),",
    """home: LeanEatAuthGate(
        onboardingHome: const WelcomeScreen(),
        completedHomeBuilder: (profile) => ProgrammeReadyScreen(
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
      ),""",
    'auth gate home',
)

main = replace_once(
    main,
    "'limitation_notes': limitationNotes,\n                      'visual_preference': 'Match profile',",
    "'limitation_notes': limitationNotes,\n                      'warning_signs': warningSigns.toList(),\n                      'visual_preference': 'Match profile',",
    'persist warning signs',
)

# Restrict ProgrammeReady edits to that class only.
start = main.find('class ProgrammeReadyScreen extends StatelessWidget {')
end = main.find('class WorkoutDetailScreen', start)
if start < 0 or end < 0:
    raise SystemExit('Could not isolate ProgrammeReadyScreen')
head = main[:start]
section = main[start:end]
tail = main[end:]

section = replace_first(
    section,
    "final Set<String> warningSigns;\n\n  const ProgrammeReadyScreen({",
    "final Set<String> warningSigns;\n  final bool isMemberHome;\n\n  const ProgrammeReadyScreen({",
    'member home field',
)

section = replace_first(
    section,
    "required this.warningSigns,\n  });",
    "required this.warningSigns,\n    this.isMemberHome = false,\n  });",
    'member home constructor',
)

old_appbar = """appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF102A43)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),"""
new_appbar = """appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        automaticallyImplyLeading: !isMemberHome,
        leading: isMemberHome
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF102A43)),
                onPressed: () => Navigator.pop(context),
              ),
        title: isMemberHome
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LeanEatLogo(size: 30, showWordmark: false),
                  SizedBox(width: 10),
                  Text('LeanEat'),
                ],
              )
            : null,
        actions: isMemberHome
            ? [
                IconButton(
                  tooltip: 'Progress',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProgressScreen()),
                    );
                  },
                  icon: const Icon(Icons.insights_outlined),
                ),
                IconButton(
                  tooltip: 'Account',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LeanEatAccountScreen()),
                    );
                  },
                  icon: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(width: 6),
              ]
            : null,
      ),"""
section = replace_first(section, old_appbar, new_appbar, 'ProgrammeReady app bar')

section = replace_first(
    section,
    "const Text(\n                      'Your programme is ready',",
    "Text(\n                      isMemberHome ? 'Your programme' : 'Your programme is ready',",
    'programme home heading',
)

main = head + section + tail

# ---------- account_screen.dart ----------
account = replace_once(
    account,
    "import 'profile_service.dart';\n",
    "import 'profile_service.dart';\nimport 'training_profile_edit_screen.dart';\n",
    'account edit import',
)

account = replace_once(
    account,
    """title: 'Training profile',
                  child: Column(
                    children: [
                      _fact(Icons.flag_outlined, 'Goal', profile['main_goal']?.toString() ?? 'Not set'),""",
    """title: 'Training profile',
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TrainingProfileEditScreen(),
                              ),
                            );
                            if (changed == true && mounted) {
                              setState(() => _profileFuture = _loadProfile());
                            }
                          },
                          icon: const Icon(Icons.tune_rounded),
                          label: const Text('EDIT TRAINING PROFILE'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      _fact(Icons.flag_outlined, 'Goal', profile['main_goal']?.toString() ?? 'Not set'),""",
    'account training edit button',
)

main_path.write_text(main, encoding='utf-8')
account_path.write_text(account, encoding='utf-8')
print('Patched main member routing and account training profile editing.')
