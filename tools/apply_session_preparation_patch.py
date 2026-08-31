from pathlib import Path

path = Path('lib/live_workout_screen.dart')
text = path.read_text(encoding='utf-8')

replacements = []

replacements.append((
"import 'progression_engine.dart';\nimport 'superset_engine.dart';\n",
"import 'progression_engine.dart';\nimport 'session_phase_flow_screen.dart';\nimport 'session_preparation_engine.dart';\nimport 'superset_engine.dart';\n",
))

replacements.append((
"  bool _swapping = false;\n  bool _editingWorkout = false;\n",
"  bool _swapping = false;\n  bool _editingWorkout = false;\n  bool _preparationCompleted = false;\n  bool _coolDownCompleted = false;\n  bool _openingPreparation = false;\n  bool _openingCoolDown = false;\n",
))

replacements.append((
"  bool get canEditStructure =>\n      phase == LivePhase.ready &&\n      currentIndex == 0 &&\n      currentSet == 1 &&\n      completedSets == 0;\n",
"  bool get canEditStructure =>\n      phase == LivePhase.ready &&\n      currentIndex == 0 &&\n      currentSet == 1 &&\n      completedSets == 0 &&\n      !_preparationCompleted;\n\n  GeneratedWorkout get _currentSessionWorkout => GeneratedWorkout(\n        title: widget.workout.title,\n        exercises: List<ExercisePrescription>.unmodifiable(_sessionExercises),\n      );\n\n  SessionPreparationPlan get _sessionPreparationPlan =>\n      SessionPreparationEngine.forWorkout(_currentSessionWorkout);\n",
))

replacements.append((
"  void _startSet() {\n    if (_editingWorkout || _swapping) return;\n    _tickTimer?.cancel();\n",
"  void _startSet() {\n    if (_editingWorkout || _swapping) return;\n    if (!_preparationCompleted &&\n        completedSets == 0 &&\n        currentIndex == 0 &&\n        currentSet == 1 &&\n        !inDropSet) {\n      unawaited(_openPreparationFlow());\n      return;\n    }\n    _tickTimer?.cancel();\n",
))

replacements.append((
"  Future<void> _finishSet() async {\n",
"  Future<void> _openPreparationFlow() async {\n    if (_openingPreparation || _preparationCompleted || !mounted) return;\n    final steps = _sessionPreparationPlan.warmUp;\n    if (steps.isEmpty) {\n      setState(() => _preparationCompleted = true);\n      return;\n    }\n\n    setState(() => _openingPreparation = true);\n    final completed = await Navigator.push<bool>(\n      context,\n      MaterialPageRoute(\n        builder: (_) => SessionPhaseFlowScreen(\n          title: 'Warm-up + mobility',\n          subtitle:\n              'LeanIt prepared these steps from the movements in today’s workout. They prepare you for the main session and are not added to strength volume or progression history.',\n          steps: steps,\n          completeLabel: 'WARM-UP COMPLETE',\n        ),\n      ),\n    );\n\n    if (!mounted) return;\n    setState(() {\n      _openingPreparation = false;\n      if (completed == true) _preparationCompleted = true;\n    });\n    if (completed == true) {\n      ScaffoldMessenger.of(context).showSnackBar(\n        const SnackBar(\n          content: Text('Warm-up complete. Start your first working set when ready.'),\n        ),\n      );\n    }\n  }\n\n  Future<void> _openCoolDownFlow() async {\n    if (_openingCoolDown || _coolDownCompleted || !mounted) return;\n    final steps = _sessionPreparationPlan.coolDown;\n    if (steps.isEmpty) {\n      setState(() => _coolDownCompleted = true);\n      return;\n    }\n\n    setState(() => _openingCoolDown = true);\n    final completed = await Navigator.push<bool>(\n      context,\n      MaterialPageRoute(\n        builder: (_) => SessionPhaseFlowScreen(\n          title: 'Cool-down + stretching',\n          subtitle:\n              'Bring the session down gradually with easy recovery, comfortable stretching and breathing. These steps do not change your workout-performance records.',\n          steps: steps,\n          completeLabel: 'COOL-DOWN COMPLETE',\n        ),\n      ),\n    );\n\n    if (!mounted) return;\n    setState(() {\n      _openingCoolDown = false;\n      if (completed == true) _coolDownCompleted = true;\n    });\n  }\n\n  Future<void> _finishSet() async {\n",
))

replacements.append((
"    if (completedExercises >= _sessionExercises.length) {\n      setState(() => phase = LivePhase.ready);\n      unawaited(_saveHistory());\n      return;\n    }\n",
"    if (completedExercises >= _sessionExercises.length) {\n      setState(() => phase = LivePhase.ready);\n      unawaited(_saveHistory());\n      unawaited(_openCoolDownFlow());\n      return;\n    }\n",
))

replacements.append((
"                    if (SupersetEngine.hasValidPair(\n                      _sessionExercises,\n                      currentIndex,\n                    )) ...[\n                      _supersetBanner(),\n                      const SizedBox(height: 12),\n                    ],\n                    _previousPerformanceCard(),\n",
"                    if (SupersetEngine.hasValidPair(\n                      _sessionExercises,\n                      currentIndex,\n                    )) ...[\n                      _supersetBanner(),\n                      const SizedBox(height: 12),\n                    ],\n                    if (!_preparationCompleted &&\n                        completedSets == 0 &&\n                        currentIndex == 0) ...[\n                      _preparationPreviewCard(),\n                      const SizedBox(height: 12),\n                    ],\n                    _previousPerformanceCard(),\n",
))

replacements.append((
"                label: Text(\n                  inDropSet\n                      ? 'START DROP $_activeDropNumber'\n                      : (currentIsTimed ? 'START TIMER' : 'START SET'),\n                  style: const TextStyle(fontWeight: FontWeight.bold),\n                ),\n",
"                label: Text(\n                  !_preparationCompleted &&\n                          completedSets == 0 &&\n                          currentIndex == 0 &&\n                          currentSet == 1\n                      ? 'START WARM-UP'\n                      : inDropSet\n                          ? 'START DROP $_activeDropNumber'\n                          : (currentIsTimed ? 'START TIMER' : 'START SET'),\n                  style: const TextStyle(fontWeight: FontWeight.bold),\n                ),\n",
))

replacements.append((
"  Widget _dropSetBanner() {\n",
"  Widget _preparationPreviewCard() {\n    final plan = _sessionPreparationPlan;\n    final minutes = (plan.warmUpSeconds / 60).ceil();\n    return Container(\n      width: double.infinity,\n      padding: const EdgeInsets.all(14),\n      decoration: BoxDecoration(\n        color: const Color(0xFFF3F8DC),\n        borderRadius: BorderRadius.circular(16),\n        border: Border.all(color: const Color(0xFFD8E89A)),\n      ),\n      child: Row(\n        crossAxisAlignment: CrossAxisAlignment.start,\n        children: [\n          const Icon(Icons.directions_run_rounded, color: Color(0xFF55721B)),\n          const SizedBox(width: 12),\n          Expanded(\n            child: Column(\n              crossAxisAlignment: CrossAxisAlignment.start,\n              children: [\n                const Text(\n                  'Preparation before working sets',\n                  style: TextStyle(\n                    fontWeight: FontWeight.bold,\n                    color: Color(0xFF102A43),\n                  ),\n                ),\n                const SizedBox(height: 4),\n                Text(\n                  '${plan.warmUp.length} guided steps • about $minutes min • warm-up, mobility and activation',\n                  style: const TextStyle(\n                    fontSize: 12,\n                    height: 1.4,\n                    color: Color(0xFF627D98),\n                  ),\n                ),\n              ],\n            ),\n          ),\n        ],\n      ),\n    );\n  }\n\n  Widget _dropSetBanner() {\n",
))

replacements.append((
"            const Text(\n              'Your completed set performance has been saved to LeanIt history.',\n              textAlign: TextAlign.center,\n              style: TextStyle(\n                fontSize: 14,\n                color: Color(0xFF486581),\n              ),\n            ),\n            const SizedBox(height: 30),\n            SizedBox(\n",
"            Text(\n              _coolDownCompleted\n                  ? 'Your workout is saved and your guided cool-down is complete.'\n                  : 'Your workout is saved. Finish with LeanIt’s guided cool-down and stretching when you are ready.',\n              textAlign: TextAlign.center,\n              style: const TextStyle(\n                fontSize: 14,\n                color: Color(0xFF486581),\n              ),\n            ),\n            const SizedBox(height: 22),\n            if (!_coolDownCompleted && _sessionPreparationPlan.coolDown.isNotEmpty) ...[\n              SizedBox(\n                width: double.infinity,\n                child: OutlinedButton.icon(\n                  onPressed: _openingCoolDown ? null : _openCoolDownFlow,\n                  icon: _openingCoolDown\n                      ? const SizedBox(\n                          width: 18,\n                          height: 18,\n                          child: CircularProgressIndicator(strokeWidth: 2),\n                        )\n                      : const Icon(Icons.self_improvement_rounded),\n                  style: OutlinedButton.styleFrom(\n                    minimumSize: const Size.fromHeight(54),\n                  ),\n                  label: const Text(\n                    'DO COOL-DOWN + STRETCHING',\n                    style: TextStyle(fontWeight: FontWeight.bold),\n                  ),\n                ),\n              ),\n              const SizedBox(height: 12),\n            ],\n            SizedBox(\n",
))

for old, new in replacements:
    if old not in text:
        raise RuntimeError(f'patch anchor missing:\n{old[:180]}')
    text = text.replace(old, new, 1)

path.write_text(text, encoding='utf-8')
