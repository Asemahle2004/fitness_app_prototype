from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding='utf-8')
    if new in text:
        return
    if old not in text:
        raise RuntimeError(f'Pattern not found in {path}: {old[:120]!r}')
    file.write_text(text.replace(old, new, 1), encoding='utf-8')


def patch_workout_engine() -> None:
    path = 'lib/workout_engine.dart'
    replace_once(
        path,
        """  final String? visualAsset;\n  final String? metricLabel;\n\n  const ExercisePrescription({\n""",
        """  final String? visualAsset;\n  final String? metricLabel;\n  final String? supersetId;\n\n  const ExercisePrescription({\n""",
    )
    replace_once(
        path,
        """    this.visualAsset,\n    this.metricLabel,\n  });\n\n  bool get isSingleDurationBlock {\n""",
        """    this.visualAsset,\n    this.metricLabel,\n    this.supersetId,\n  });\n\n  ExercisePrescription copyWith({\n    String? name,\n    int? sets,\n    String? reps,\n    String? rest,\n    String? equipment,\n    String? target,\n    String? visualAsset,\n    String? metricLabel,\n    String? supersetId,\n    bool clearSuperset = false,\n  }) {\n    return ExercisePrescription(\n      name: name ?? this.name,\n      sets: sets ?? this.sets,\n      reps: reps ?? this.reps,\n      rest: rest ?? this.rest,\n      equipment: equipment ?? this.equipment,\n      target: target ?? this.target,\n      visualAsset: visualAsset ?? this.visualAsset,\n      metricLabel: metricLabel ?? this.metricLabel,\n      supersetId: clearSuperset ? null : (supersetId ?? this.supersetId),\n    );\n  }\n\n  bool get isSingleDurationBlock {\n""",
    )


def patch_custom_workout_store() -> None:
    path = 'lib/custom_workout_store.dart'
    replace_once(
        path,
        """        'visual_asset': exercise.visualAsset,\n        'metric_label': exercise.metricLabel,\n      };\n""",
        """        'visual_asset': exercise.visualAsset,\n        'metric_label': exercise.metricLabel,\n        'superset_id': exercise.supersetId,\n      };\n""",
    )
    replace_once(
        path,
        """      visualAsset: json['visual_asset']?.toString(),\n      metricLabel: json['metric_label']?.toString(),\n    );\n""",
        """      visualAsset: json['visual_asset']?.toString(),\n      metricLabel: json['metric_label']?.toString(),\n      supersetId: json['superset_id']?.toString(),\n    );\n""",
    )


def patch_safety_engine() -> None:
    path = 'lib/safety_engine.dart'
    replace_once(
        path,
        """import 'workout_engine.dart';\n""",
        """import 'superset_engine.dart';\nimport 'workout_engine.dart';\n""",
    )
    replace_once(
        path,
        """        exercises: kept,\n""",
        """        exercises: SupersetEngine.normalize(kept),\n""",
    )


def patch_workout_editor() -> None:
    path = 'lib/workout_editor_screen.dart'
    replace_once(
        path,
        """import 'safety_engine.dart';\nimport 'workout_engine.dart';\n""",
        """import 'safety_engine.dart';\nimport 'superset_engine.dart';\nimport 'workout_engine.dart';\n""",
    )
    replace_once(
        path,
        """    setState(() => _exercises.addAll(additions));\n""",
        """    setState(() {\n      _exercises.addAll(additions);\n      final normalized = SupersetEngine.normalize(_exercises);\n      _exercises\n        ..clear()\n        ..addAll(normalized);\n    });\n""",
    )
    replace_once(
        path,
        """    final removed = _exercises[index];\n    setState(() => _exercises.removeAt(index));\n""",
        """    final removed = _exercises[index];\n    setState(() {\n      _exercises.removeAt(index);\n      final normalized = SupersetEngine.normalize(_exercises);\n      _exercises\n        ..clear()\n        ..addAll(normalized);\n    });\n""",
    )
    replace_once(
        path,
        """      final exercise = _exercises.removeAt(oldIndex);\n      _exercises.insert(newIndex, exercise);\n    });\n  }\n\n  void _reset() {\n""",
        """      final exercise = _exercises.removeAt(oldIndex);\n      _exercises.insert(newIndex, exercise);\n      final normalized = SupersetEngine.normalize(_exercises);\n      _exercises\n        ..clear()\n        ..addAll(normalized);\n    });\n  }\n\n  void _toggleSuperset(int index) {\n    setState(() {\n      final paired = SupersetEngine.hasValidPair(_exercises, index);\n      final next = paired\n          ? SupersetEngine.unpairAt(_exercises, index)\n          : SupersetEngine.pairWithNext(_exercises, index);\n      _exercises\n        ..clear()\n        ..addAll(next);\n    });\n  }\n\n  void _reset() {\n""",
    )
    replace_once(
        path,
        """        exercises: List<ExercisePrescription>.unmodifiable(_exercises),\n""",
        """        exercises: List<ExercisePrescription>.unmodifiable(\n          SupersetEngine.normalize(_exercises),\n        ),\n""",
    )
    replace_once(
        path,
        """                        IconButton(\n                          tooltip: 'Remove exercise',\n                          onPressed: () => _removeExercise(index),\n                          icon: const Icon(Icons.delete_outline_rounded),\n                        ),\n""",
        """                        Column(\n                          mainAxisSize: MainAxisSize.min,\n                          children: [\n                            if (SupersetEngine.hasValidPair(_exercises, index))\n                              Text(\n                                'SUPERSET ${SupersetEngine.positionLabel(_exercises, index)}',\n                                style: const TextStyle(\n                                  fontSize: 9,\n                                  fontWeight: FontWeight.w900,\n                                  color: Color(0xFF176B87),\n                                ),\n                              ),\n                            Row(\n                              mainAxisSize: MainAxisSize.min,\n                              children: [\n                                if (SupersetEngine.hasValidPair(_exercises, index) ||\n                                    (index < _exercises.length - 1 &&\n                                        _exercises[index].supersetId == null &&\n                                        _exercises[index + 1].supersetId == null))\n                                  IconButton(\n                                    tooltip: SupersetEngine.hasValidPair(_exercises, index)\n                                        ? 'Remove superset'\n                                        : 'Pair with next exercise',\n                                    onPressed: () => _toggleSuperset(index),\n                                    icon: Icon(\n                                      SupersetEngine.hasValidPair(_exercises, index)\n                                          ? Icons.link_off_rounded\n                                          : Icons.link_rounded,\n                                    ),\n                                  ),\n                                IconButton(\n                                  tooltip: 'Remove exercise',\n                                  onPressed: () => _removeExercise(index),\n                                  icon: const Icon(Icons.delete_outline_rounded),\n                                ),\n                              ],\n                            ),\n                          ],\n                        ),\n""",
    )


def patch_custom_workouts() -> None:
    path = 'lib/custom_workouts_screen.dart'
    replace_once(
        path,
        """import 'safety_engine.dart';\nimport 'workout_editor_screen.dart';\n""",
        """import 'safety_engine.dart';\nimport 'superset_engine.dart';\nimport 'workout_editor_screen.dart';\n""",
    )
    replace_once(
        path,
        """    setState(() => _exercises.addAll(additions));\n  }\n\n  void _reorder(int oldIndex, int newIndex) {\n""",
        """    setState(() {\n      _exercises.addAll(additions);\n      final normalized = SupersetEngine.normalize(_exercises);\n      _exercises\n        ..clear()\n        ..addAll(normalized);\n    });\n  }\n\n  void _reorder(int oldIndex, int newIndex) {\n""",
    )
    replace_once(
        path,
        """      final exercise = _exercises.removeAt(oldIndex);\n      _exercises.insert(newIndex, exercise);\n    });\n  }\n\n  void _remove(int index) {\n    setState(() => _exercises.removeAt(index));\n  }\n\n  Future<void> _editPrescription(int index) async {\n""",
        """      final exercise = _exercises.removeAt(oldIndex);\n      _exercises.insert(newIndex, exercise);\n      final normalized = SupersetEngine.normalize(_exercises);\n      _exercises\n        ..clear()\n        ..addAll(normalized);\n    });\n  }\n\n  void _remove(int index) {\n    setState(() {\n      _exercises.removeAt(index);\n      final normalized = SupersetEngine.normalize(_exercises);\n      _exercises\n        ..clear()\n        ..addAll(normalized);\n    });\n  }\n\n  void _toggleSuperset(int index) {\n    setState(() {\n      final paired = SupersetEngine.hasValidPair(_exercises, index);\n      final next = paired\n          ? SupersetEngine.unpairAt(_exercises, index)\n          : SupersetEngine.pairWithNext(_exercises, index);\n      _exercises\n        ..clear()\n        ..addAll(next);\n    });\n  }\n\n  Future<void> _editPrescription(int index) async {\n""",
    )
    replace_once(
        path,
        """                  visualAsset: current.visualAsset,\n                  metricLabel: current.metricLabel,\n                ),\n""",
        """                  visualAsset: current.visualAsset,\n                  metricLabel: current.metricLabel,\n                  supersetId: current.supersetId,\n                ),\n""",
    )
    replace_once(
        path,
        """      exercises: List<ExercisePrescription>.unmodifiable(_exercises),\n""",
        """      exercises: List<ExercisePrescription>.unmodifiable(\n        SupersetEngine.normalize(_exercises),\n      ),\n""",
    )
    replace_once(
        path,
        """                              IconButton(\n                                tooltip: 'Remove exercise',\n                                onPressed: () => _remove(index),\n                                icon: const Icon(Icons.delete_outline_rounded),\n                              ),\n""",
        """                              Column(\n                                mainAxisSize: MainAxisSize.min,\n                                children: [\n                                  if (SupersetEngine.hasValidPair(_exercises, index))\n                                    Text(\n                                      'SS ${SupersetEngine.positionLabel(_exercises, index)}',\n                                      style: const TextStyle(\n                                        fontSize: 9,\n                                        fontWeight: FontWeight.w900,\n                                        color: Color(0xFF176B87),\n                                      ),\n                                    ),\n                                  Row(\n                                    mainAxisSize: MainAxisSize.min,\n                                    children: [\n                                      if (SupersetEngine.hasValidPair(_exercises, index) ||\n                                          (index < _exercises.length - 1 &&\n                                              _exercises[index].supersetId == null &&\n                                              _exercises[index + 1].supersetId == null))\n                                        IconButton(\n                                          tooltip: SupersetEngine.hasValidPair(_exercises, index)\n                                              ? 'Remove superset'\n                                              : 'Pair with next exercise',\n                                          onPressed: () => _toggleSuperset(index),\n                                          icon: Icon(\n                                            SupersetEngine.hasValidPair(_exercises, index)\n                                                ? Icons.link_off_rounded\n                                                : Icons.link_rounded,\n                                          ),\n                                        ),\n                                      IconButton(\n                                        tooltip: 'Remove exercise',\n                                        onPressed: () => _remove(index),\n                                        icon: const Icon(Icons.delete_outline_rounded),\n                                      ),\n                                    ],\n                                  ),\n                                ],\n                              ),\n""",
    )


def patch_live_workout() -> None:
    path = 'lib/live_workout_screen.dart'
    replace_once(
        path,
        """import 'progression_engine.dart';\nimport 'training_store.dart';\n""",
        """import 'progression_engine.dart';\nimport 'superset_engine.dart';\nimport 'training_store.dart';\n""",
    )
    replace_once(
        path,
        """  bool _swapping = false;\n  bool _editingWorkout = false;\n\n  late final List<ExercisePrescription> _sessionExercises;\n""",
        """  bool _swapping = false;\n  bool _editingWorkout = false;\n  int? _nextIndexAfterRest;\n  int _activeRestSeconds = 0;\n\n  late final List<ExercisePrescription> _sessionExercises;\n  late List<int> _completedSetsByExercise;\n""",
    )
    replace_once(
        path,
        """    _sessionExercises = List<ExercisePrescription>.from(widget.workout.exercises);\n    final client = Supabase.instance.client;\n""",
        """    _sessionExercises = SupersetEngine.normalize(widget.workout.exercises);\n    _completedSetsByExercise = List<int>.filled(_sessionExercises.length, 0);\n    final client = Supabase.instance.client;\n""",
    )
    replace_once(
        path,
        """  void _resetCurrentExerciseState() {\n    currentSet = 1;\n""",
        """  void _resetCurrentExerciseState({int setNumber = 1}) {\n    currentSet = setNumber;\n""",
    )
    replace_once(
        path,
        """    final hasMoreSets = currentSet < currentExercise.sets;\n    final hasMoreExercises = currentIndex < _sessionExercises.length - 1;\n\n    _finishingSet = false;\n\n    if (hasMoreSets || hasMoreExercises) {\n      _startRest();\n    } else {\n      _finishExerciseAndAdvance();\n    }\n""",
        """    _completedSetsByExercise[currentIndex] =\n        (_completedSetsByExercise[currentIndex] + 1).clamp(0, exercise.sets);\n\n    if (SupersetEngine.hasValidPair(_sessionExercises, currentIndex)) {\n      if (_completedSetsByExercise[currentIndex] == exercise.sets) {\n        completedExercises += 1;\n      }\n      _finishingSet = false;\n\n      final immediate = SupersetEngine.immediateNextAfterSet(\n        exercises: _sessionExercises,\n        completedSets: _completedSetsByExercise,\n        currentIndex: currentIndex,\n      );\n      if (immediate != null) {\n        _switchToExercise(immediate);\n        return;\n      }\n\n      final nextRound = SupersetEngine.nextRoundMember(\n        exercises: _sessionExercises,\n        completedSets: _completedSetsByExercise,\n        currentIndex: currentIndex,\n      );\n      if (nextRound != null) {\n        _startRest(\n          nextIndex: nextRound,\n          secondsOverride: _supersetRestSeconds(currentIndex),\n        );\n        return;\n      }\n\n      final afterPair = SupersetEngine.indexAfterPair(\n        _sessionExercises,\n        currentIndex,\n      );\n      if (afterPair != null) {\n        _startRest(\n          nextIndex: afterPair,\n          secondsOverride: _supersetRestSeconds(currentIndex),\n        );\n        return;\n      }\n\n      setState(() => phase = LivePhase.ready);\n      unawaited(_saveHistory());\n      return;\n    }\n\n    final hasMoreSets = currentSet < currentExercise.sets;\n    final hasMoreExercises = currentIndex < _sessionExercises.length - 1;\n\n    _finishingSet = false;\n\n    if (hasMoreSets || hasMoreExercises) {\n      _startRest();\n    } else {\n      _finishExerciseAndAdvance();\n    }\n""",
    )
    replace_once(
        path,
        """  void _startRest() {\n    final seconds = _parseRestSeconds(currentExercise.rest);\n    if (seconds <= 0) {\n      _advanceAfterRest();\n      return;\n    }\n\n    setState(() {\n""",
        """  void _startRest({int? nextIndex, int? secondsOverride}) {\n    _nextIndexAfterRest = nextIndex;\n    final seconds = secondsOverride ?? _parseRestSeconds(currentExercise.rest);\n    _activeRestSeconds = seconds;\n    if (seconds <= 0) {\n      _advanceAfterRest();\n      return;\n    }\n\n    setState(() {\n""",
    )
    replace_once(
        path,
        """  void _advanceAfterRest() {\n    _tickTimer?.cancel();\n    if (currentSet < currentExercise.sets) {\n""",
        """  void _advanceAfterRest() {\n    _tickTimer?.cancel();\n    final requestedIndex = _nextIndexAfterRest;\n    _nextIndexAfterRest = null;\n    if (requestedIndex != null) {\n      _switchToExercise(requestedIndex);\n      return;\n    }\n    if (currentSet < currentExercise.sets) {\n""",
    )
    replace_once(
        path,
        """  void _finishExerciseAndAdvance() {\n""",
        """  void _switchToExercise(int index) {\n    if (index < 0 || index >= _sessionExercises.length) return;\n    setState(() {\n      currentIndex = index;\n      _resetCurrentExerciseState(\n        setNumber: _completedSetsByExercise[index] + 1,\n      );\n    });\n    unawaited(_loadPreviousPerformance(currentExercise.name));\n  }\n\n  int _supersetRestSeconds(int index) {\n    final members = SupersetEngine.membersFor(_sessionExercises, index);\n    if (members.length != 2) return _parseRestSeconds(currentExercise.rest);\n    var seconds = 0;\n    for (final member in members) {\n      final parsed = _parseRestSeconds(_sessionExercises[member].rest);\n      if (parsed > seconds) seconds = parsed;\n    }\n    return seconds > 0 ? seconds : 60;\n  }\n\n  void _finishExerciseAndAdvance() {\n""",
    )
    replace_once(
        path,
        """          seconds: _parseRestSeconds(currentExercise.rest) -\n              restSecondsRemaining,\n""",
        """          seconds: _activeRestSeconds - restSecondsRemaining,\n""",
    )
    replace_once(
        path,
        """      currentIndex = 0;\n      completedExercises = 0;\n      _resetCurrentExerciseState();\n""",
        """      currentIndex = 0;\n      completedExercises = 0;\n      _completedSetsByExercise = List<int>.filled(_sessionExercises.length, 0);\n      _resetCurrentExerciseState();\n""",
    )
    replace_once(
        path,
        """    final previousName = currentExercise.name;\n    final replacement = selected.exercise;\n    setState(() {\n      _sessionExercises[currentIndex] = replacement;\n      _resetCurrentExerciseState();\n    });\n""",
        """    final previousName = currentExercise.name;\n    final replacement = selected.exercise.copyWith(\n      supersetId: currentExercise.supersetId,\n    );\n    setState(() {\n      _sessionExercises[currentIndex] = replacement;\n      _resetCurrentExerciseState(\n        setNumber: _completedSetsByExercise[currentIndex] + 1,\n      );\n    });\n""",
    )
    replace_once(
        path,
        """                    const SizedBox(height: 14),\n                    _previousPerformanceCard(),\n""",
        """                    const SizedBox(height: 14),\n                    if (SupersetEngine.hasValidPair(\n                      _sessionExercises,\n                      currentIndex,\n                    )) ...[\n                      _supersetBanner(),\n                      const SizedBox(height: 12),\n                    ],\n                    _previousPerformanceCard(),\n""",
    )
    replace_once(
        path,
        """  Widget _previousPerformanceCard() {\n""",
        """  Widget _supersetBanner() {\n    final label = SupersetEngine.positionLabel(_sessionExercises, currentIndex);\n    final partner = SupersetEngine.partnerName(_sessionExercises, currentIndex);\n    final isFirst = label == 'A';\n    return Container(\n      width: double.infinity,\n      padding: const EdgeInsets.all(13),\n      decoration: BoxDecoration(\n        color: const Color(0xFFEAF7FA),\n        borderRadius: BorderRadius.circular(14),\n        border: Border.all(color: const Color(0xFFB9E2EA)),\n      ),\n      child: Row(\n        children: [\n          const Icon(Icons.link_rounded, color: Color(0xFF176B87)),\n          const SizedBox(width: 10),\n          Expanded(\n            child: Text(\n              isFirst\n                  ? 'SUPERSET A • Next: $partner • no rest between exercises'\n                  : 'SUPERSET B • Rest after this set, then repeat the pair',\n              style: const TextStyle(\n                fontSize: 12,\n                fontWeight: FontWeight.w700,\n                color: Color(0xFF176B87),\n              ),\n            ),\n          ),\n        ],\n      ),\n    );\n  }\n\n  Widget _previousPerformanceCard() {\n""",
    )


def main() -> None:
    patch_workout_engine()
    patch_custom_workout_store()
    patch_safety_engine()
    patch_workout_editor()
    patch_custom_workouts()
    patch_live_workout()
    print('Superset integration applied.')


if __name__ == '__main__':
    main()
