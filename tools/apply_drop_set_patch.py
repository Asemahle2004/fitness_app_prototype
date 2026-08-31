from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding='utf-8')
    if old not in text:
        raise RuntimeError(f'Expected block not found in {path}: {old[:120]!r}')
    file.write_text(text.replace(old, new, 1), encoding='utf-8')


# workout model
replace_once(
    'lib/workout_engine.dart',
    "  final String? supersetId;\n",
    "  final String? supersetId;\n  final int dropSetCount;\n  final int dropSetReductionPercent;\n",
)
replace_once(
    'lib/workout_engine.dart',
    "    this.metricLabel,\n    this.supersetId,\n  });\n",
    "    this.metricLabel,\n    this.supersetId,\n    this.dropSetCount = 0,\n    this.dropSetReductionPercent = 20,\n  });\n",
)
replace_once(
    'lib/workout_engine.dart',
    "    String? supersetId,\n    bool clearSuperset = false,\n  }) {\n",
    "    String? supersetId,\n    int? dropSetCount,\n    int? dropSetReductionPercent,\n    bool clearSuperset = false,\n    bool clearDropSet = false,\n  }) {\n",
)
replace_once(
    'lib/workout_engine.dart',
    "      metricLabel: metricLabel ?? this.metricLabel,\n      supersetId: clearSuperset ? null : (supersetId ?? this.supersetId),\n    );\n",
    "      metricLabel: metricLabel ?? this.metricLabel,\n      supersetId: clearSuperset ? null : (supersetId ?? this.supersetId),\n      dropSetCount: clearDropSet ? 0 : (dropSetCount ?? this.dropSetCount),\n      dropSetReductionPercent: clearDropSet\n          ? 20\n          : (dropSetReductionPercent ?? this.dropSetReductionPercent),\n    );\n",
)

# saved custom workouts
replace_once(
    'lib/custom_workout_store.dart',
    "        'superset_id': exercise.supersetId,\n",
    "        'superset_id': exercise.supersetId,\n        'drop_set_count': exercise.dropSetCount,\n        'drop_set_reduction_percent': exercise.dropSetReductionPercent,\n",
)
replace_once(
    'lib/custom_workout_store.dart',
    "      supersetId: json['superset_id']?.toString(),\n    );\n",
    "      supersetId: json['superset_id']?.toString(),\n      dropSetCount: (json['drop_set_count'] as num?)?.toInt() ?? 0,\n      dropSetReductionPercent:\n          (json['drop_set_reduction_percent'] as num?)?.toInt() ?? 20,\n    );\n",
)

# supersets and drop sets are intentionally mutually exclusive in v1
replace_once(
    'lib/superset_engine.dart',
    "    if (result[firstIndex].supersetId != null ||\n        result[firstIndex + 1].supersetId != null) {\n",
    "    if (result[firstIndex].supersetId != null ||\n        result[firstIndex + 1].supersetId != null ||\n        result[firstIndex].dropSetCount > 0 ||\n        result[firstIndex + 1].dropSetCount > 0) {\n",
)

# richer local set logging; drop sets remain local until backend columns exist
replace_once(
    'lib/exercise_performance_store.dart',
    "  final int? durationSeconds;\n  final DateTime performedAt;\n",
    "  final int? durationSeconds;\n  final String setType;\n  final int? dropNumber;\n  final DateTime performedAt;\n",
)
replace_once(
    'lib/exercise_performance_store.dart',
    "    required this.durationSeconds,\n    required this.performedAt,\n  });\n",
    "    required this.durationSeconds,\n    this.setType = 'normal',\n    this.dropNumber,\n    required this.performedAt,\n  });\n",
)
replace_once(
    'lib/exercise_performance_store.dart',
    "      durationSeconds: rawDuration?.toInt(),\n      performedAt: DateTime.tryParse(\n",
    "      durationSeconds: rawDuration?.toInt(),\n      setType: (map['set_type'] ?? map['setType'])?.toString() ?? 'normal',\n      dropNumber: number(map['drop_number'] ?? map['dropNumber'])?.toInt(),\n      performedAt: DateTime.tryParse(\n",
)
replace_once(
    'lib/exercise_performance_store.dart',
    "        'durationSeconds': durationSeconds,\n        'performedAt': performedAt.toIso8601String(),\n      };\n\n  String get summary {\n",
    "        'durationSeconds': durationSeconds,\n        'setType': setType,\n        'dropNumber': dropNumber,\n        'performedAt': performedAt.toIso8601String(),\n      };\n\n  bool get isDropSet => setType == 'drop';\n\n  String get setLabel => isDropSet\n      ? 'Drop ${dropNumber ?? 1}'\n      : 'Set $setNumber';\n\n  String get summary {\n",
)
replace_once(
    'lib/exercise_performance_store.dart',
    "    double? weightKg,\n    int? durationSeconds,\n  }) async {\n",
    "    double? weightKg,\n    int? durationSeconds,\n    bool isDropSet = false,\n    int? dropNumber,\n  }) async {\n",
)
replace_once(
    'lib/exercise_performance_store.dart',
    "      durationSeconds: durationSeconds,\n      performedAt: DateTime.now(),\n    );\n",
    "      durationSeconds: durationSeconds,\n      setType: isDropSet ? 'drop' : 'normal',\n      dropNumber: isDropSet ? dropNumber : null,\n      performedAt: DateTime.now(),\n    );\n",
)
replace_once(
    'lib/exercise_performance_store.dart',
    "    final user = client.auth.currentUser;\n    if (user == null) return;\n",
    "    // Drop-set metadata is local-only until the LeanIt Supabase table has\n    // explicit set_type/drop_number columns. Do not flatten a drop into a\n    // normal cloud set because that would corrupt progression history.\n    if (record.isDropSet) return;\n\n    final user = client.auth.currentUser;\n    if (user == null) return;\n",
)
replace_once(
    'lib/exercise_performance_store.dart',
    "    for (final record in await _loadLocal()) {\n      if (record.exerciseName.toLowerCase() == lower) return record;\n    }\n",
    "    for (final record in await _loadLocal()) {\n      if (record.isDropSet) continue;\n      if (record.exerciseName.toLowerCase() == lower) return record;\n    }\n",
)
replace_once(
    'lib/exercise_performance_store.dart',
    "      record.durationSeconds,\n      record.performedAt.toUtc().toIso8601String(),\n",
    "      record.durationSeconds,\n      record.setType,\n      record.dropNumber,\n      record.performedAt.toUtc().toIso8601String(),\n",
)

# workout editor UI
replace_once(
    'lib/workout_editor_screen.dart',
    "import 'custom_exercise_store.dart';\n",
    "import 'custom_exercise_store.dart';\nimport 'drop_set_engine.dart';\n",
)
replace_once(
    'lib/workout_editor_screen.dart',
    "  void _reset() {\n",
    "  Future<void> _configureDropSet(int index) async {\n    final current = _exercises[index];\n    if (!DropSetEngine.isLoadTrackedStrength(current)) {\n      ScaffoldMessenger.of(context).showSnackBar(\n        const SnackBar(content: Text('Drop sets are available for load-tracked strength exercises.')),\n      );\n      return;\n    }\n    if (current.supersetId != null) {\n      ScaffoldMessenger.of(context).showSnackBar(\n        const SnackBar(content: Text('Remove the superset pairing before adding a drop set.')),\n      );\n      return;\n    }\n\n    var drops = current.dropSetCount > 0 ? current.dropSetCount : 1;\n    var reduction = current.dropSetReductionPercent;\n    final config = await showDialog<DropSetConfig>(\n      context: context,\n      builder: (dialogContext) => StatefulBuilder(\n        builder: (context, setDialogState) => AlertDialog(\n          title: Text(current.dropSetCount > 0 ? 'Edit drop set' : 'Add drop set'),\n          content: Column(\n            mainAxisSize: MainAxisSize.min,\n            children: [\n              const Text('After the final normal set, reduce the load and continue immediately without rest.'),\n              const SizedBox(height: 16),\n              DropdownButtonFormField<int>(\n                value: drops,\n                decoration: const InputDecoration(labelText: 'Number of drops'),\n                items: const [1, 2, 3]\n                    .map((value) => DropdownMenuItem(value: value, child: Text('$value')))\n                    .toList(),\n                onChanged: (value) {\n                  if (value != null) setDialogState(() => drops = value);\n                },\n              ),\n              const SizedBox(height: 12),\n              DropdownButtonFormField<int>(\n                value: reduction,\n                decoration: const InputDecoration(labelText: 'Load reduction each drop'),\n                items: const [10, 15, 20, 25, 30]\n                    .map((value) => DropdownMenuItem(value: value, child: Text('$value%')))\n                    .toList(),\n                onChanged: (value) {\n                  if (value != null) setDialogState(() => reduction = value);\n                },\n              ),\n            ],\n          ),\n          actions: [\n            if (current.dropSetCount > 0)\n              TextButton(\n                onPressed: () => Navigator.pop(\n                  dialogContext,\n                  const DropSetConfig(drops: 0, reductionPercent: 20),\n                ),\n                child: const Text('REMOVE'),\n              ),\n            TextButton(\n              onPressed: () => Navigator.pop(dialogContext),\n              child: const Text('CANCEL'),\n            ),\n            ElevatedButton(\n              onPressed: () => Navigator.pop(\n                dialogContext,\n                DropSetConfig(drops: drops, reductionPercent: reduction),\n              ),\n              child: const Text('SAVE'),\n            ),\n          ],\n        ),\n      ),\n    );\n    if (config == null || !mounted) return;\n    setState(() {\n      _exercises[index] = DropSetEngine.configure(current, config);\n    });\n  }\n\n  void _reset() {\n",
)
replace_once(
    'lib/workout_editor_screen.dart',
    "                              const SizedBox(height: 3),\n                              Text(\n                                '${exercise.target} • ${exercise.equipment}',\n",
    "                              if (exercise.dropSetCount > 0) ...[\n                                const SizedBox(height: 3),\n                                Text(\n                                  'DROP SET • ${DropSetEngine.badge(exercise)}',\n                                  style: const TextStyle(\n                                    fontSize: 11,\n                                    fontWeight: FontWeight.w800,\n                                    color: Color(0xFF9A6700),\n                                  ),\n                                ),\n                              ],\n                              const SizedBox(height: 3),\n                              Text(\n                                '${exercise.target} • ${exercise.equipment}',\n",
)
replace_once(
    'lib/workout_editor_screen.dart',
    "                                    (index < _exercises.length - 1 &&\n                                        _exercises[index].supersetId == null &&\n                                        _exercises[index + 1].supersetId == null))\n",
    "                                    (index < _exercises.length - 1 &&\n                                        _exercises[index].supersetId == null &&\n                                        _exercises[index + 1].supersetId == null &&\n                                        _exercises[index].dropSetCount == 0 &&\n                                        _exercises[index + 1].dropSetCount == 0))\n",
)
replace_once(
    'lib/workout_editor_screen.dart',
    "                                  ),\n                                IconButton(\n                                  tooltip: 'Remove exercise',\n",
    "                                  ),\n                                if (DropSetEngine.isLoadTrackedStrength(exercise) &&\n                                    exercise.supersetId == null)\n                                  IconButton(\n                                    tooltip: exercise.dropSetCount > 0\n                                        ? 'Edit drop set'\n                                        : 'Add drop set',\n                                    onPressed: () => _configureDropSet(index),\n                                    icon: Icon(\n                                      Icons.trending_down_rounded,\n                                      color: exercise.dropSetCount > 0\n                                          ? const Color(0xFF9A6700)\n                                          : null,\n                                    ),\n                                  ),\n                                IconButton(\n                                  tooltip: 'Remove exercise',\n",
)

# custom workout builder UI and persistence preservation while editing prescriptions
replace_once(
    'lib/custom_workouts_screen.dart',
    "import 'custom_workout_store.dart';\n",
    "import 'custom_workout_store.dart';\nimport 'drop_set_engine.dart';\n",
)
replace_once(
    'lib/custom_workouts_screen.dart',
    "  Future<void> _editPrescription(int index) async {\n",
    "  Future<void> _configureDropSet(int index) async {\n    final current = _exercises[index];\n    if (!DropSetEngine.isLoadTrackedStrength(current)) return;\n    if (current.supersetId != null) {\n      ScaffoldMessenger.of(context).showSnackBar(\n        const SnackBar(content: Text('Remove the superset pairing before adding a drop set.')),\n      );\n      return;\n    }\n\n    var drops = current.dropSetCount > 0 ? current.dropSetCount : 1;\n    var reduction = current.dropSetReductionPercent;\n    final config = await showDialog<DropSetConfig>(\n      context: context,\n      builder: (dialogContext) => StatefulBuilder(\n        builder: (context, setDialogState) => AlertDialog(\n          title: Text(current.dropSetCount > 0 ? 'Edit drop set' : 'Add drop set'),\n          content: Column(\n            mainAxisSize: MainAxisSize.min,\n            children: [\n              const Text('The drop starts after the final normal set with no rest between load reductions.'),\n              const SizedBox(height: 16),\n              DropdownButtonFormField<int>(\n                value: drops,\n                decoration: const InputDecoration(labelText: 'Number of drops'),\n                items: const [1, 2, 3]\n                    .map((value) => DropdownMenuItem(value: value, child: Text('$value')))\n                    .toList(),\n                onChanged: (value) {\n                  if (value != null) setDialogState(() => drops = value);\n                },\n              ),\n              const SizedBox(height: 12),\n              DropdownButtonFormField<int>(\n                value: reduction,\n                decoration: const InputDecoration(labelText: 'Load reduction each drop'),\n                items: const [10, 15, 20, 25, 30]\n                    .map((value) => DropdownMenuItem(value: value, child: Text('$value%')))\n                    .toList(),\n                onChanged: (value) {\n                  if (value != null) setDialogState(() => reduction = value);\n                },\n              ),\n            ],\n          ),\n          actions: [\n            if (current.dropSetCount > 0)\n              TextButton(\n                onPressed: () => Navigator.pop(\n                  dialogContext,\n                  const DropSetConfig(drops: 0, reductionPercent: 20),\n                ),\n                child: const Text('REMOVE'),\n              ),\n            TextButton(\n              onPressed: () => Navigator.pop(dialogContext),\n              child: const Text('CANCEL'),\n            ),\n            ElevatedButton(\n              onPressed: () => Navigator.pop(\n                dialogContext,\n                DropSetConfig(drops: drops, reductionPercent: reduction),\n              ),\n              child: const Text('SAVE'),\n            ),\n          ],\n        ),\n      ),\n    );\n    if (config == null || !mounted) return;\n    setState(() {\n      _exercises[index] = DropSetEngine.configure(current, config);\n    });\n  }\n\n  Future<void> _editPrescription(int index) async {\n",
)
replace_once(
    'lib/custom_workouts_screen.dart',
    "                  metricLabel: current.metricLabel,\n                  supersetId: current.supersetId,\n                ),\n",
    "                  metricLabel: current.metricLabel,\n                  supersetId: current.supersetId,\n                  dropSetCount: current.dropSetCount,\n                  dropSetReductionPercent: current.dropSetReductionPercent,\n                ),\n",
)
replace_once(
    'lib/custom_workouts_screen.dart',
    "                                      const SizedBox(height: 3),\n                                      const Text(\n                                        'Tap to edit sets, reps/time and rest',\n",
    "                                      if (exercise.dropSetCount > 0) ...[\n                                        const SizedBox(height: 3),\n                                        Text(\n                                          'DROP SET • ${DropSetEngine.badge(exercise)}',\n                                          style: const TextStyle(\n                                            fontSize: 11,\n                                            fontWeight: FontWeight.w800,\n                                            color: Color(0xFF9A6700),\n                                          ),\n                                        ),\n                                      ],\n                                      const SizedBox(height: 3),\n                                      const Text(\n                                        'Tap to edit sets, reps/time and rest',\n",
)
replace_once(
    'lib/custom_workouts_screen.dart',
    "                                          (index < _exercises.length - 1 &&\n                                              _exercises[index].supersetId == null &&\n                                              _exercises[index + 1].supersetId == null))\n",
    "                                          (index < _exercises.length - 1 &&\n                                              _exercises[index].supersetId == null &&\n                                              _exercises[index + 1].supersetId == null &&\n                                              _exercises[index].dropSetCount == 0 &&\n                                              _exercises[index + 1].dropSetCount == 0))\n",
)
replace_once(
    'lib/custom_workouts_screen.dart',
    "                                        ),\n                                      IconButton(\n                                        tooltip: 'Remove exercise',\n",
    "                                        ),\n                                      if (DropSetEngine.isLoadTrackedStrength(exercise) &&\n                                          exercise.supersetId == null)\n                                        IconButton(\n                                          tooltip: exercise.dropSetCount > 0\n                                              ? 'Edit drop set'\n                                              : 'Add drop set',\n                                          onPressed: () => _configureDropSet(index),\n                                          icon: Icon(\n                                            Icons.trending_down_rounded,\n                                            color: exercise.dropSetCount > 0\n                                                ? const Color(0xFF9A6700)\n                                                : null,\n                                          ),\n                                        ),\n                                      IconButton(\n                                        tooltip: 'Remove exercise',\n",
)

# live workout execution
replace_once(
    'lib/live_workout_screen.dart',
    "import 'exercise_media.dart';\n",
    "import 'drop_set_engine.dart';\nimport 'exercise_media.dart';\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "  int _activeRestSeconds = 0;\n",
    "  int _activeRestSeconds = 0;\n  int _activeDropNumber = 0;\n  double? _dropSetBaseWeightKg;\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "  bool get currentIsTimed => _isTimedExercise(currentExercise);\n\n  bool get canEditStructure =>\n",
    "  bool get currentIsTimed => _isTimedExercise(currentExercise);\n\n  bool get inDropSet => _activeDropNumber > 0;\n\n  bool get canEditStructure =>\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "    _activeSetWeightKg = null;\n    _previousPerformance = null;\n",
    "    _activeSetWeightKg = null;\n    _activeDropNumber = 0;\n    _dropSetBaseWeightKg = null;\n    _previousPerformance = null;\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "    final exercise = currentExercise;\n    final setNumber = currentSet;\n",
    "    final exercise = currentExercise;\n    final setNumber = currentSet;\n    final finishingDropSet = inDropSet;\n    final dropNumber = _activeDropNumber;\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "    _lastSavedSummary = '${exercise.name} • Set $setNumber • $savedSummary';\n",
    "    _lastSavedSummary = finishingDropSet\n        ? '${exercise.name} • Drop $dropNumber • $savedSummary'\n        : '${exercise.name} • Set $setNumber • $savedSummary';\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "        durationSeconds: durationSeconds,\n      ),\n    );\n\n    _completedSetsByExercise[currentIndex] =\n",
    "        durationSeconds: durationSeconds,\n        isDropSet: finishingDropSet,\n        dropNumber: finishingDropSet ? dropNumber : null,\n      ),\n    );\n\n    if (finishingDropSet) {\n      _finishingSet = false;\n      if (dropNumber < exercise.dropSetCount) {\n        _prepareDropSet(dropNumber + 1);\n        return;\n      }\n\n      _activeDropNumber = 0;\n      _dropSetBaseWeightKg = null;\n      final hasMoreExercises = currentIndex < _sessionExercises.length - 1;\n      if (hasMoreExercises) {\n        _startRest();\n      } else {\n        _finishExerciseAndAdvance();\n      }\n      return;\n    }\n\n    _completedSetsByExercise[currentIndex] =\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "            .toInt();\n\n    if (SupersetEngine.hasValidPair(_sessionExercises, currentIndex)) {\n",
    "            .toInt();\n\n    if (currentSet >= exercise.sets &&\n        exercise.dropSetCount > 0 &&\n        DropSetEngine.canConfigure(exercise)) {\n      _finishingSet = false;\n      _dropSetBaseWeightKg = weightKg;\n      _prepareDropSet(1);\n      return;\n    }\n\n    if (SupersetEngine.hasValidPair(_sessionExercises, currentIndex)) {\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "    required int? durationSeconds,\n  }) async {\n",
    "    required int? durationSeconds,\n    bool isDropSet = false,\n    int? dropNumber,\n  }) async {\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "        durationSeconds: durationSeconds,\n      );\n",
    "        durationSeconds: durationSeconds,\n        isDropSet: isDropSet,\n        dropNumber: dropNumber,\n      );\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "  void _startRest({int? nextIndex, int? secondsOverride}) {\n",
    "  void _prepareDropSet(int dropNumber) {\n    final suggested = DropSetEngine.suggestedWeight(\n      workingWeightKg: _dropSetBaseWeightKg,\n      reductionPercent: currentExercise.dropSetReductionPercent,\n      dropNumber: dropNumber,\n    );\n    setState(() {\n      _activeDropNumber = dropNumber;\n      phase = LivePhase.ready;\n      displayedRep = 0;\n      targetReps = _defaultRepTarget(currentExercise);\n      workSecondsTarget = _defaultWorkSeconds(currentExercise);\n      workSecondsRemaining = workSecondsTarget;\n      _activeSetWeightKg = null;\n      _progressionSuggestion = null;\n      _performanceLoading = false;\n      if (suggested != null) {\n        _weightController.text = _formatWeight(suggested);\n      } else {\n        _weightController.clear();\n      }\n    });\n  }\n\n  void _startRest({int? nextIndex, int? secondsOverride}) {\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "    if (_swapping || _editingWorkout || phase != LivePhase.ready || currentSet != 1) {\n",
    "    if (_swapping ||\n        _editingWorkout ||\n        phase != LivePhase.ready ||\n        currentSet != 1 ||\n        inDropSet) {\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "    final previousName = currentExercise.name;\n    final replacement = selected.exercise.copyWith(\n      supersetId: currentExercise.supersetId,\n    );\n",
    "    final previousName = currentExercise.name;\n    var replacement = selected.exercise.copyWith(\n      supersetId: currentExercise.supersetId,\n    );\n    if (currentExercise.dropSetCount > 0 &&\n        DropSetEngine.canConfigure(replacement)) {\n      replacement = replacement.copyWith(\n        dropSetCount: currentExercise.dropSetCount,\n        dropSetReductionPercent: currentExercise.dropSetReductionPercent,\n      );\n    }\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "              Text(\n                'Set $currentSet of ${exercise.sets}',\n",
    "              Text(\n                inDropSet\n                    ? 'Drop $_activeDropNumber of ${exercise.dropSetCount}'\n                    : 'Set $currentSet of ${exercise.sets}',\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "                    if (SupersetEngine.hasValidPair(\n                      _sessionExercises,\n                      currentIndex,\n                    )) ...[\n",
    "                    if (inDropSet) ...[\n                      _dropSetBanner(),\n                      const SizedBox(height: 12),\n                    ],\n                    if (SupersetEngine.hasValidPair(\n                      _sessionExercises,\n                      currentIndex,\n                    )) ...[\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "                    if (_progressionSuggestion != null) ...[\n",
    "                    if (!inDropSet && _progressionSuggestion != null) ...[\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "          if (phase == LivePhase.ready && currentSet == 1)\n",
    "          if (phase == LivePhase.ready && currentSet == 1 && !inDropSet)\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "          if (phase == LivePhase.ready && currentSet == 1)\n            const SizedBox(height: 10),\n",
    "          if (phase == LivePhase.ready && currentSet == 1 && !inDropSet)\n            const SizedBox(height: 10),\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "                  currentIsTimed ? 'START TIMER' : 'START SET',\n",
    "                  inDropSet\n                      ? 'START DROP $_activeDropNumber'\n                      : (currentIsTimed ? 'START TIMER' : 'START SET'),\n",
)
replace_once(
    'lib/live_workout_screen.dart',
    "  Widget _supersetBanner() {\n",
    "  Widget _dropSetBanner() {\n    final suggested = _weightController.text.trim();\n    return Container(\n      width: double.infinity,\n      padding: const EdgeInsets.all(13),\n      decoration: BoxDecoration(\n        color: const Color(0xFFFFF7E6),\n        borderRadius: BorderRadius.circular(14),\n        border: Border.all(color: const Color(0xFFFFD58A)),\n      ),\n      child: Row(\n        children: [\n          const Icon(Icons.trending_down_rounded, color: Color(0xFF9A6700)),\n          const SizedBox(width: 10),\n          Expanded(\n            child: Text(\n              'DROP $_activeDropNumber OF ${currentExercise.dropSetCount} • reduce about ${currentExercise.dropSetReductionPercent}% • no rest'\n              '${suggested.isEmpty ? '' : ' • target $suggested kg'}',\n              style: const TextStyle(\n                fontSize: 12,\n                fontWeight: FontWeight.w700,\n                color: Color(0xFF9A6700),\n              ),\n            ),\n          ),\n        ],\n      ),\n    );\n  }\n\n  Widget _supersetBanner() {\n",
)

print('Drop set integration applied.')
