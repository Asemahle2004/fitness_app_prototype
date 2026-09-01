from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f'Expected snippet not found: {label}')
    return text.replace(old, new, 1)


# --- live_run_screen.dart ---
path = Path('lib/live_run_screen.dart')
text = path.read_text()
text = replace_once(
    text,
    "import 'package:flutter/material.dart';\n",
    "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';\n",
    'services import',
)
text = replace_once(
    text,
    "import 'personal_record_celebration.dart';\n",
    "import 'guided_run_engine.dart';\nimport 'personal_record_celebration.dart';\n",
    'guided run import',
)
text = replace_once(
    text,
    """class LiveRunScreen extends StatefulWidget {
  const LiveRunScreen({super.key});
""",
    """class LiveRunScreen extends StatefulWidget {
  final GuidedRunPlan? guidedPlan;

  const LiveRunScreen({super.key, this.guidedPlan});
""",
    'guided plan constructor',
)
text = replace_once(
    text,
    """  bool _starting = false;
  String _gpsStatus = 'Ready';
""",
    """  bool _starting = false;
  bool _soundCues = true;
  bool _hapticCues = true;
  bool _guidedCompleteHandled = false;
  int _lastGuidedStepIndex = -2;
  String _gpsStatus = 'Ready';

  GuidedRunProgress? get _guidedProgress {
    final plan = widget.guidedPlan;
    if (plan == null) return null;
    return GuidedRunEngine.progressFor(plan, _elapsedSeconds);
  }
""",
    'guided state',
)
text = replace_once(
    text,
    """      _previousPosition = null;
      _paused = false;
      _running = true;
      _startTimer();
""",
    """      _previousPosition = null;
      _paused = false;
      _guidedCompleteHandled = false;
      _lastGuidedStepIndex = -2;
      _running = true;
      _startTimer();
""",
    'reset guided start',
)
text = replace_once(
    text,
    """      await _subscribeGps();
      if (mounted) setState(() => _gpsStatus = 'GPS tracking active');
""",
    """      await _subscribeGps();
      if (mounted) {
        setState(() => _gpsStatus = 'GPS tracking active');
        if (widget.guidedPlan != null) {
          _handleGuidedTick(-1);
        }
      }
""",
    'first guided cue',
)
text = replace_once(
    text,
    """  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_running || _paused) return;
      setState(() => _elapsedSeconds += 1);
    });
  }
""",
    """  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_running || _paused) return;
      final previousElapsed = _elapsedSeconds;
      setState(() => _elapsedSeconds += 1);
      _handleGuidedTick(previousElapsed);
    });
  }

  void _emitGuidedCue({bool countdown = false}) {
    if (_soundCues) {
      SystemSound.play(SystemSoundType.click);
    }
    if (_hapticCues) {
      if (countdown) {
        HapticFeedback.selectionClick();
      } else {
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _handleGuidedTick(int previousElapsed) {
    final plan = widget.guidedPlan;
    if (plan == null || _guidedCompleteHandled || !mounted) return;

    final progress = GuidedRunEngine.progressFor(plan, _elapsedSeconds);
    final previous = previousElapsed < 0
        ? null
        : GuidedRunEngine.progressFor(plan, previousElapsed);

    if (progress.complete) {
      unawaited(_completeGuidedSession());
      return;
    }

    if (progress.stepIndex != _lastGuidedStepIndex) {
      _lastGuidedStepIndex = progress.stepIndex;
      _emitGuidedCue();
    } else if (progress.secondsRemainingInStep <= 3 &&
        progress.secondsRemainingInStep > 0 &&
        previous?.secondsRemainingInStep != progress.secondsRemainingInStep) {
      _emitGuidedCue(countdown: true);
    }
  }

  Future<void> _completeGuidedSession() async {
    if (_guidedCompleteHandled || !mounted) return;
    _guidedCompleteHandled = true;
    _emitGuidedCue();
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    if (!mounted) return;
    setState(() {
      _paused = true;
      _previousPosition = null;
      _gpsStatus = 'Guided session complete';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Guided run complete. Tap FINISH to review and save it.'),
      ),
    );
  }
""",
    'guided timer handling',
)
text = replace_once(
    text,
    """    final record = RunRecord(
      id: 'run_${DateTime.now().microsecondsSinceEpoch}',
      startedAt: startedAt,
      durationSeconds: _elapsedSeconds,
      distanceMeters: _distanceMeters,
      source: 'gps',
    );
""",
    """    final guidedPlan = widget.guidedPlan;
    final record = RunRecord(
      id: 'run_${DateTime.now().microsecondsSinceEpoch}',
      startedAt: startedAt,
      durationSeconds: _elapsedSeconds,
      distanceMeters: _distanceMeters,
      source: guidedPlan == null ? 'gps' : 'gps_guided',
      notes: guidedPlan == null
          ? null
          : 'Guided: ${guidedPlan.title} • ${_guidedCompleteHandled ? 'completed' : 'ended early'}',
    );
""",
    'guided run history metadata',
)
text = replace_once(
    text,
    """      appBar: AppBar(
        title: const Text('Run tracker'),
""",
    """      appBar: AppBar(
        title: Text(widget.guidedPlan?.title ?? 'Run tracker'),
""",
    'guided app bar title',
)
text = replace_once(
    text,
    """              ),
              const Spacer(),
              _Metric(
""",
    """              ),
              if (widget.guidedPlan != null) ...[
                const SizedBox(height: 14),
                _guidedRunCard(),
              ],
              const Spacer(),
              _Metric(
""",
    'guided card placement',
)
text = replace_once(
    text,
    """                    label: Text(_starting ? 'STARTING GPS...' : 'START RUN'),
""",
    """                    label: Text(
                      _starting
                          ? 'STARTING GPS...'
                          : widget.guidedPlan == null
                              ? 'START RUN'
                              : 'START GUIDED RUN',
                    ),
""",
    'guided start label',
)
insert_anchor = """  @override
  Widget build(BuildContext context) {
"""
guided_method = """  Widget _guidedRunCard() {
    final plan = widget.guidedPlan!;
    final progress = _guidedProgress!;
    final step = progress.step;
    final next = GuidedRunEngine.nextStep(plan, progress);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.headphones_rounded, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progress.complete
                      ? 'GUIDED SESSION COMPLETE'
                      : GuidedRunEngine.phaseLabel(step!.type),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (!progress.complete)
                Text(
                  '${progress.stepIndex + 1}/${plan.steps.length}',
                  style: const TextStyle(color: Colors.white60),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (progress.complete)
            const Text(
              'You reached the end of the guided session. Review and save your run when ready.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            )
          else ...[
            Text(
              step!.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              step.instruction,
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  RunTrackingEngine.formatDuration(
                    progress.secondsRemainingInStep,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (next != null)
                  Flexible(
                    child: Text(
                      'Next: ${next.label}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.stepProgress,
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: Colors.white12,
              color: Colors.white,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              FilterChip(
                selected: _soundCues,
                onSelected: (value) => setState(() => _soundCues = value),
                avatar: const Icon(Icons.volume_up_outlined, size: 18),
                label: const Text('Sound cues'),
              ),
              FilterChip(
                selected: _hapticCues,
                onSelected: (value) => setState(() => _hapticCues = value),
                avatar: const Icon(Icons.vibration_rounded, size: 18),
                label: const Text('Vibration'),
              ),
            ],
          ),
        ],
      ),
    );
  }

"""
text = replace_once(text, insert_anchor, guided_method + insert_anchor, 'guided run card method')
path.write_text(text)


# --- run_tracking_screen.dart ---
path = Path('lib/run_tracking_screen.dart')
text = path.read_text()
text = replace_once(
    text,
    "import 'live_run_screen.dart';\n",
    "import 'guided_run_plan_screen.dart';\nimport 'live_run_screen.dart';\n",
    'guided plan screen import',
)
text = replace_once(
    text,
    """  Future<void> _openLiveRun() async {
""",
    """  Future<void> _openGuidedRun() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const GuidedRunPlanScreen()),
    );
    if (changed == true) await _refresh();
  }

  Future<void> _openLiveRun() async {
""",
    'guided run navigation',
)
text = replace_once(
    text,
    """                  'Track outdoor runs with foreground GPS or log treadmill/watch runs manually. LeanIt keeps your distance, time and pace history together.',
""",
    """                  'Choose a guided interval session, track a free outdoor run with foreground GPS, or log treadmill/watch runs manually. LeanIt keeps distance, time and pace history together.',
""",
    'running description',
)
old_buttons = """                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _openLiveRun,
                        icon: const Icon(Icons.gps_fixed),
                        label: const Text('START GPS RUN'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openManualRun,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('ADD RUN'),
                      ),
                    ),
                  ],
                ),
"""
new_buttons = """                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _openGuidedRun,
                        icon: const Icon(Icons.timer_outlined),
                        label: const Text('GUIDED RUN'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openLiveRun,
                        icon: const Icon(Icons.gps_fixed),
                        label: const Text('FREE GPS RUN'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openManualRun,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('ADD TREADMILL / WATCH RUN'),
                  ),
                ),
"""
text = replace_once(text, old_buttons, new_buttons, 'run action buttons')
text = replace_once(
    text,
    """            run.source == 'gps' ? Icons.gps_fixed : Icons.edit_location_alt_outlined,
""",
    """            run.source.startsWith('gps')
                ? Icons.gps_fixed
                : Icons.edit_location_alt_outlined,
""",
    'guided gps history icon',
)
path.write_text(text)
