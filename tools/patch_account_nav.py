from pathlib import Path

path = Path('lib/main.dart')
text = path.read_text(encoding='utf-8')


def replace_once(old: str, new: str, label: str):
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected 1 match, found {count}')
    text = text.replace(old, new, 1)

replace_once(
    "import 'profile_service.dart';\nimport 'package:supabase_flutter/supabase_flutter.dart';",
    "import 'profile_service.dart';\nimport 'account_screen.dart';\nimport 'package:supabase_flutter/supabase_flutter.dart';",
    'account import',
)

replace_once(
'''              const SizedBox(height: 18),

              TextButton(
                onPressed: () {},
                child: const Text(
                  'Already have an account? Sign in',
                  style: TextStyle(color: Color(0xFF627D98)),
                ),
              ),

              const SizedBox(height: 10),''',
'''              const SizedBox(height: 18),

              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeanEatAccountScreen()),
                  );
                },
                icon: const Icon(Icons.account_circle_outlined),
                label: const Text('MY ACCOUNT'),
              ),

              const SizedBox(height: 10),''',
    'welcome account link',
)

replace_once(
'''              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProgressScreen()),
                        );
                      },
                      icon: const Icon(Icons.insights_outlined),
                      label: const Text('PROGRESS'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF176B87),
                        side: const BorderSide(color: Color(0xFFD9E2EC)),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReadinessScreen()),
                        );
                      },
                      icon: const Icon(Icons.battery_charging_full_outlined),
                      label: const Text('READINESS'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF176B87),
                        side: const BorderSide(color: Color(0xFFD9E2EC)),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),''',
'''              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProgressScreen()),
                        );
                      },
                      icon: const Icon(Icons.insights_outlined),
                      label: const Text('PROGRESS'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReadinessScreen()),
                        );
                      },
                      icon: const Icon(Icons.battery_charging_full_outlined),
                      label: const Text('READINESS'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LeanEatAccountScreen()),
                        );
                      },
                      icon: const Icon(Icons.person_outline_rounded),
                      label: const Text('ACCOUNT'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),''',
    'goal navigation row',
)

path.write_text(text, encoding='utf-8')
print('LeanEat account navigation wired')
