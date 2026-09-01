from pathlib import Path

path = Path('lib/main.dart')
text = path.read_text()


def replace_once(old: str, new: str, label: str) -> None:
    global text
    if old not in text:
        raise SystemExit(f'Expected snippet not found: {label}')
    text = text.replace(old, new, 1)


replace_once(
    "import 'training_environment_engine.dart';\n",
    "import 'training_environment_engine.dart';\nimport 'weekly_plan_screen.dart';\n",
    'weekly plan import',
)

old_handler = """                    onPressed: () {
                      final firstSession = programme.sessions.first;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutDetailScreen(
                            session: firstSession,
                            locations: locations,
                            homeEquipment: homeEquipment,
                            gymAccess: gymAccess,
                            hasLimitation: hasLimitation,
                            affectedAreas: Set<String>.from(affectedAreas),
                            limitationNotes: limitationNotes,
                            warningSigns: Set<String>.from(warningSigns),
                          ),
                        ),
                      );
                    },"""

new_handler = """                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WeeklyPlanScreen(
                            baseSessions: programme.sessions,
                            availableDays: availableDays,
                            userScope: supabase.auth.currentUser?.id ?? 'guest',
                            onOpenSession: (weeklyContext, session) {
                              Navigator.push(
                                weeklyContext,
                                MaterialPageRoute(
                                  builder: (_) => WorkoutDetailScreen(
                                    session: session,
                                    locations: locations,
                                    homeEquipment: homeEquipment,
                                    gymAccess: gymAccess,
                                    hasLimitation: hasLimitation,
                                    affectedAreas: Set<String>.from(affectedAreas),
                                    limitationNotes: limitationNotes,
                                    warningSigns: Set<String>.from(warningSigns),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },"""
replace_once(old_handler, new_handler, 'programme weekly plan navigation')
replace_once(
    "                      'VIEW MY WORKOUTS',",
    "                      'OPEN WEEKLY PLAN',",
    'weekly plan button label',
)

path.write_text(text)
