from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding='utf-8')
    if old not in text:
        raise RuntimeError(f'Patch anchor missing in {path}:\n{old[:240]}')
    file.write_text(text.replace(old, new, 1), encoding='utf-8')


# Today dashboard: only use today's readiness, offer Recovery Day, and launch it.
replace_once(
    'lib/today_dashboard.dart',
    "import 'profile_service.dart';\nimport 'programme_engine.dart';\n",
    "import 'profile_service.dart';\nimport 'recovery_day_engine.dart';\nimport 'recovery_day_screen.dart';\nimport 'programme_engine.dart';\n",
)

replace_once(
    'lib/today_dashboard.dart',
    "      ReadinessRecord? readiness;\n      final readinessHistory = await TrainingStore.loadReadiness();\n      if (readinessHistory.isNotEmpty) readiness = readinessHistory.first;\n",
    "      ReadinessRecord? readiness;\n      final readinessHistory = await TrainingStore.loadReadiness();\n      if (readinessHistory.isNotEmpty &&\n          RecoveryDayEngine.isTodaysCheckIn(readinessHistory.first)) {\n        readiness = readinessHistory.first;\n      }\n",
)

replace_once(
    'lib/today_dashboard.dart',
    "  Widget _statChip(IconData icon, String label) {\n",
    "  Future<void> _startRecoveryDay() async {\n    final readiness = _readiness;\n    final profile = _profile;\n    if (readiness == null ||\n        profile == null ||\n        !RecoveryDayEngine.shouldOffer(readiness)) {\n      return;\n    }\n\n    await Navigator.push<bool>(\n      context,\n      MaterialPageRoute(\n        builder: (_) => RecoveryDayScreen(\n          readiness: readiness,\n          profile: profile,\n        ),\n      ),\n    );\n    if (mounted) await _load();\n  }\n\n  Widget _statChip(IconData icon, String label) {\n",
)

replace_once(
    'lib/today_dashboard.dart',
    "    final readiness = _readiness;\n\n    final heading = activeIndex != null\n",
    "    final readiness = _readiness;\n    final recoveryAvailable = readiness != null &&\n        RecoveryDayEngine.shouldOffer(readiness) &&\n        adaptation?.blocksTraining != true &&\n        activeIndex == null;\n\n    final heading = activeIndex != null\n",
)

replace_once(
    'lib/today_dashboard.dart',
    "              const SizedBox(height: 18),\n              InkWell(\n                borderRadius: BorderRadius.circular(20),\n                onTap: () {\n",
    "              const SizedBox(height: 18),\n              if (recoveryAvailable) ...[\n                Container(\n                  padding: const EdgeInsets.all(18),\n                  decoration: BoxDecoration(\n                    color: const Color(0xFFF3F8DC),\n                    borderRadius: BorderRadius.circular(20),\n                    border: Border.all(color: const Color(0xFFD8E89A)),\n                  ),\n                  child: Column(\n                    crossAxisAlignment: CrossAxisAlignment.start,\n                    children: [\n                      Row(\n                        children: [\n                          Container(\n                            width: 46,\n                            height: 46,\n                            decoration: BoxDecoration(\n                              color: const Color(0xFFE8F0C7),\n                              borderRadius: BorderRadius.circular(14),\n                            ),\n                            child: const Icon(\n                              Icons.self_improvement_rounded,\n                              color: Color(0xFF55721B),\n                            ),\n                          ),\n                          const SizedBox(width: 12),\n                          Expanded(\n                            child: Column(\n                              crossAxisAlignment: CrossAxisAlignment.start,\n                              children: [\n                                const Text(\n                                  'RECOVERY OPTION',\n                                  style: TextStyle(\n                                    fontSize: 11,\n                                    fontWeight: FontWeight.w900,\n                                    color: Color(0xFF55721B),\n                                  ),\n                                ),\n                                const SizedBox(height: 3),\n                                Text(\n                                  readiness!.score < 40\n                                      ? 'Recovery is the priority today'\n                                      : 'Consider a lighter recovery day',\n                                  style: const TextStyle(\n                                    fontSize: 17,\n                                    fontWeight: FontWeight.w900,\n                                    color: Color(0xFF102A43),\n                                  ),\n                                ),\n                              ],\n                            ),\n                          ),\n                        ],\n                      ),\n                      const SizedBox(height: 10),\n                      Text(\n                        'Your readiness is ${readiness.score.round()}/100. LeanIt can guide easy movement, mobility, stretching and breathing without advancing your programme or adding strength volume.',\n                        style: const TextStyle(\n                          fontSize: 13,\n                          height: 1.4,\n                          color: Color(0xFF486581),\n                        ),\n                      ),\n                      const SizedBox(height: 13),\n                      SizedBox(\n                        width: double.infinity,\n                        child: OutlinedButton.icon(\n                          onPressed: _startRecoveryDay,\n                          icon: const Icon(Icons.self_improvement_rounded),\n                          label: const Text(\n                            'START RECOVERY DAY',\n                            style: TextStyle(fontWeight: FontWeight.w900),\n                          ),\n                        ),\n                      ),\n                      const SizedBox(height: 4),\n                      const Text(\n                        'Your planned workout remains available if you decide to train.',\n                        style: TextStyle(\n                          fontSize: 11,\n                          color: Color(0xFF829AB1),\n                        ),\n                      ),\n                    ],\n                  ),\n                ),\n                const SizedBox(height: 18),\n              ],\n              InkWell(\n                borderRadius: BorderRadius.circular(20),\n                onTap: () {\n",
)

# Calendar: show recovery stats and visually distinguish recovery-only days.
replace_once(
    'lib/workout_calendar_screen.dart',
    "                    _CalendarStat(\n                      label: 'Rest days',\n                      value: '${stats.restDays}',\n                      icon: Icons.hotel_rounded,\n                    ),\n",
    "                    _CalendarStat(\n                      label: 'Recovery days',\n                      value: '${stats.recoveryDays}',\n                      icon: Icons.self_improvement_rounded,\n                    ),\n                    _CalendarStat(\n                      label: 'Rest days',\n                      value: '${stats.restDays}',\n                      icon: Icons.hotel_rounded,\n                    ),\n",
)

replace_once(
    'lib/workout_calendar_screen.dart',
    "                          final workouts = grouped[day] ?? const <WorkoutRecord>[];\n                          final trained = workouts.isNotEmpty;\n                          final selectedDay =\n",
    "                          final workouts = grouped[day] ?? const <WorkoutRecord>[];\n                          final trained = workouts.isNotEmpty;\n                          final recoveryOnly = workouts.isNotEmpty &&\n                              workouts.every(WorkoutCalendarEngine.isRecoveryRecord);\n                          final selectedDay =\n",
)

replace_once(
    'lib/workout_calendar_screen.dart',
    "                                        color: const Color(0xFF176B87),\n                                        borderRadius: BorderRadius.circular(99),\n",
    "                                        color: recoveryOnly\n                                            ? const Color(0xFF55721B)\n                                            : const Color(0xFF176B87),\n                                        borderRadius: BorderRadius.circular(99),\n",
)

replace_once(
    'lib/workout_calendar_screen.dart',
    "                      const Row(\n                        mainAxisAlignment: MainAxisAlignment.center,\n                        children: [\n                          _LegendDot(),\n                          SizedBox(width: 7),\n                          Text(\n                            'Training completed',\n                            style: TextStyle(\n                              fontSize: 12,\n                              color: Color(0xFF627D98),\n                            ),\n                          ),\n                        ],\n                      ),\n",
    "                      const Wrap(\n                        alignment: WrapAlignment.center,\n                        spacing: 18,\n                        runSpacing: 7,\n                        children: [\n                          Row(\n                            mainAxisSize: MainAxisSize.min,\n                            children: [\n                              _LegendDot(),\n                              SizedBox(width: 7),\n                              Text(\n                                'Training',\n                                style: TextStyle(\n                                  fontSize: 12,\n                                  color: Color(0xFF627D98),\n                                ),\n                              ),\n                            ],\n                          ),\n                          Row(\n                            mainAxisSize: MainAxisSize.min,\n                            children: [\n                              _LegendDot(recovery: true),\n                              SizedBox(width: 7),\n                              Text(\n                                'Recovery',\n                                style: TextStyle(\n                                  fontSize: 12,\n                                  color: Color(0xFF627D98),\n                                ),\n                              ),\n                            ],\n                          ),\n                        ],\n                      ),\n",
)

replace_once(
    'lib/workout_calendar_screen.dart',
    "                              const CircleAvatar(\n                                backgroundColor: Color(0xFFE5F4F8),\n                                child: Icon(\n                                  Icons.fitness_center_rounded,\n                                  color: Color(0xFF176B87),\n                                ),\n                              ),\n",
    "                              CircleAvatar(\n                                backgroundColor: WorkoutCalendarEngine.isRecoveryRecord(record)\n                                    ? const Color(0xFFF3F8DC)\n                                    : const Color(0xFFE5F4F8),\n                                child: Icon(\n                                  WorkoutCalendarEngine.isRecoveryRecord(record)\n                                      ? Icons.self_improvement_rounded\n                                      : Icons.fitness_center_rounded,\n                                  color: WorkoutCalendarEngine.isRecoveryRecord(record)\n                                      ? const Color(0xFF55721B)\n                                      : const Color(0xFF176B87),\n                                ),\n                              ),\n",
)

replace_once(
    'lib/workout_calendar_screen.dart',
    "                                      '${_time(record.completedAt)} • ${_duration(record.durationSeconds)} • ${record.completedSets} sets',\n",
    "                                      WorkoutCalendarEngine.isRecoveryRecord(record)\n                                          ? '${_time(record.completedAt)} • ${_duration(record.durationSeconds)} • recovery session'\n                                          : '${_time(record.completedAt)} • ${_duration(record.durationSeconds)} • ${record.completedSets} sets',\n",
)

replace_once(
    'lib/workout_calendar_screen.dart',
    "                            const Text(\n                              'Exercises',\n                              style: TextStyle(\n                                fontWeight: FontWeight.bold,\n                                color: Color(0xFF486581),\n                              ),\n                            ),\n",
    "                            Text(\n                              WorkoutCalendarEngine.isRecoveryRecord(record)\n                                  ? 'Recovery steps'\n                                  : 'Exercises',\n                              style: const TextStyle(\n                                fontWeight: FontWeight.bold,\n                                color: Color(0xFF486581),\n                              ),\n                            ),\n",
)

replace_once(
    'lib/workout_calendar_screen.dart',
    "                            'This month: ${_duration(stats.totalDurationSeconds)} training time and ${stats.completedSets} completed sets.',\n",
    "                            'This month: ${_duration(stats.totalDurationSeconds)} logged training/recovery time and ${stats.completedSets} completed working sets.',\n",
)

replace_once(
    'lib/workout_calendar_screen.dart',
    "class _LegendDot extends StatelessWidget {\n  const _LegendDot();\n\n  @override\n  Widget build(BuildContext context) {\n    return Container(\n      width: 8,\n      height: 8,\n      decoration: const BoxDecoration(\n        color: Color(0xFF176B87),\n        shape: BoxShape.circle,\n      ),\n    );\n  }\n}\n",
    "class _LegendDot extends StatelessWidget {\n  final bool recovery;\n\n  const _LegendDot({this.recovery = false});\n\n  @override\n  Widget build(BuildContext context) {\n    return Container(\n      width: 8,\n      height: 8,\n      decoration: BoxDecoration(\n        color: recovery\n            ? const Color(0xFF55721B)\n            : const Color(0xFF176B87),\n        shape: BoxShape.circle,\n      ),\n    );\n  }\n}\n",
)
