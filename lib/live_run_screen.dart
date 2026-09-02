import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'guided_run_engine.dart';
import 'personal_record_celebration.dart';
import 'personal_record_engine.dart';
import 'run_location_settings.dart';
import 'run_tracking_engine.dart';
import 'run_tracking_store.dart';
import 'training_settings.dart';
import 'training_tools_engine.dart';

class LiveRunScreen extends StatefulWidget {
  final GuidedRunPlan? guidedPlan;

  const LiveRunScreen({super.key, this.guidedPlan});

  @override
  State<LiveRunScreen> createState() => _LiveRunScreenState();
}

class _LiveRunScreenState extends State<LiveRunScreen> {
  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;
  Position? _previousPosition;
  DateTime? _startedAt;
  int _elapsedSeconds = 0;
  double _distanceMeters = 0;
  bool _running = false;
  bool _paused = false;
  bool _starting = false;
  bool _soundCues = true;
  bool _hapticCues = true;
  bool _countdownCues = true;
  bool _guidedCompleteHandled = false;
  int _lastGuidedStepIndex = -2;
  String _gpsStatus = 'Ready';
  TrainingSettings _settings = const TrainingSettings();

  GuidedRunProgress? get _guidedProgress {
    final plan = widget.guidedPlan;
    if (plan == null) return null;
    return GuidedRunEngine.progressFor(plan, _elapsedSeconds);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadTrainingSettings());
  }

  Future<void> _loadTrainingSettings() async {
    final settings = await TrainingSettingsStore(
      userScope: Supabase.instance.client.auth.currentUser?.id ?? 'guest',
    ).load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _soundCues = settings.soundCues;
      _hapticCues = settings.hapticCues;
      _countdownCues = settings.countdownCues;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<bool> _ensureLocationPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (mounted) {
        setState(() => _gpsStatus = 'Location services are turned off');
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      if (mounted) setState(() => _gpsStatus = 'Location permission denied');
      return false;
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() =>
            _gpsStatus = 'Location permission blocked in device settings');
      }
      return false;
    }
    return true;
  }

  Future<void> _start() async {
    if (_starting || _running) return;
    setState(() {
      _starting = true;
      _gpsStatus = 'Checking GPS...';
    });

    try {
      if (!await _ensureLocationPermission()) return;
      _startedAt = DateTime.now();
      _elapsedSeconds = 0;
      _distanceMeters = 0;
      _previousPosition = null;
      _paused = false;
      _guidedCompleteHandled = false;
      _lastGuidedStepIndex = -2;
      _running = true;
      _startTimer();
      await _subscribeGps();
      if (mounted) {
        setState(() => _gpsStatus = 'GPS tracking active');
        if (widget.guidedPlan != null) {
          _handleGuidedTick(-1);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _running = false;
          _paused = false;
          _gpsStatus = 'Could not start GPS tracking';
        });
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _startTimer() {
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
    } else if (_countdownCues &&
        progress.secondsRemainingInStep <= 3 &&
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

  Future<void> _subscribeGps() async {
    await _positionSubscription?.cancel();
    final settings = buildRunLocationSettings();

    try {
      final initial = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
      _previousPosition = initial;
    } catch (_) {
      _previousPosition = null;
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      _onPosition,
      onError: (_) {
        if (mounted && _running && !_paused) {
          setState(() => _gpsStatus = 'GPS signal interrupted');
        }
      },
    );
  }

  void _onPosition(Position position) {
    if (!_running || _paused) return;
    if (position.accuracy > 50) {
      if (mounted) setState(() => _gpsStatus = 'Waiting for better GPS signal');
      return;
    }

    final previous = _previousPosition;
    _previousPosition = position;
    if (previous == null) return;

    final segment = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      position.latitude,
      position.longitude,
    );

    // Ignore implausible single jumps. The next good point becomes the new anchor.
    if (segment <= 0 || segment > 200) return;
    if (!mounted) return;
    setState(() {
      _distanceMeters += segment;
      _gpsStatus = 'GPS tracking active';
    });
  }

  Future<void> _pause() async {
    if (!_running || _paused) return;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    if (!mounted) return;
    setState(() {
      _paused = true;
      _previousPosition = null;
      _gpsStatus = 'Paused';
    });
  }

  Future<void> _resume() async {
    if (!_running || !_paused || _guidedCompleteHandled) return;
    setState(() {
      _paused = false;
      _gpsStatus = 'Reconnecting GPS...';
    });
    try {
      await _subscribeGps();
      if (mounted) setState(() => _gpsStatus = 'GPS tracking active');
    } catch (_) {
      if (mounted) setState(() => _gpsStatus = 'Could not reconnect GPS');
    }
  }

  Future<void> _finish() async {
    if (!_running) return;
    if (_distanceMeters < 50 || _elapsedSeconds < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Track at least 50 m and 10 seconds before saving.'),
        ),
      );
      return;
    }

    final pace = RunTrackingEngine.paceSecondsPerKm(
      distanceMeters: _distanceMeters,
      durationSeconds: _elapsedSeconds,
    );
    final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Finish run?'),
            content: Text(
              '${TrainingToolsEngine.formatDistanceMeters(_distanceMeters, _settings.unitSystem)} • '
              '${RunTrackingEngine.formatDuration(_elapsedSeconds)} • '
              '${TrainingToolsEngine.formatPace(pace, _settings.unitSystem)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('KEEP RUNNING'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('FINISH & SAVE'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldSave) return;

    _timer?.cancel();
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    final startedAt = _startedAt ?? DateTime.now();
    final guidedPlan = widget.guidedPlan;
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
    final previous = await RunTrackingStore.load();
    final achievements = PersonalRecordEngine.newRunRecords(
      current: record,
      previous: previous,
    );
    await RunTrackingStore.save(record);
    if (!mounted) return;
    await PersonalRecordCelebration.showDialogIfNeeded(context, achievements);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _guidedRunCard() {
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
              FilterChip(
                selected: _countdownCues,
                onSelected: (value) => setState(() => _countdownCues = value),
                avatar: const Icon(Icons.timer_outlined, size: 18),
                label: const Text('3-2-1'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pace = RunTrackingEngine.paceSecondsPerKm(
      distanceMeters: _distanceMeters,
      durationSeconds: _elapsedSeconds,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF102A43),
      appBar: AppBar(
        title: Text(widget.guidedPlan?.title ?? 'Run tracker'),
        backgroundColor: const Color(0xFF102A43),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      _paused ? Icons.pause_circle_outline : Icons.gps_fixed,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _gpsStatus,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.guidedPlan != null) ...[
                const SizedBox(height: 14),
                _guidedRunCard(),
              ],
              const Spacer(),
              _Metric(
                label: 'DISTANCE',
                value: TrainingToolsEngine.formatDistanceMeters(
                  _distanceMeters,
                  _settings.unitSystem,
                ),
              ),
              const SizedBox(height: 34),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'TIME',
                      value: RunTrackingEngine.formatDuration(_elapsedSeconds),
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _Metric(
                      label: 'AVG PACE',
                      value: TrainingToolsEngine.formatPace(
                        pace,
                        _settings.unitSystem,
                      ),
                      compact: true,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (!_running)
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: _starting ? null : _start,
                    icon: _starting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      _starting
                          ? 'STARTING GPS...'
                          : widget.guidedPlan == null
                              ? 'START RUN'
                              : 'START GUIDED RUN',
                    ),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _guidedCompleteHandled
                            ? null
                            : (_paused ? _resume : _pause),
                        icon: Icon(
                          _guidedCompleteHandled
                              ? Icons.check_rounded
                              : _paused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                        ),
                        label: Text(
                          _guidedCompleteHandled
                              ? 'COMPLETE'
                              : _paused
                                  ? 'RESUME'
                                  : 'PAUSE',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          minimumSize: const Size.fromHeight(54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _finish,
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('FINISH'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'On Android, LeanIt keeps an active-run notification so GPS can continue when you press Home or turn the screen off. Pause or finish the run to stop tracking.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;

  const _Metric({
    required this.label,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 30 : 56,
            ),
          ),
        ),
      ],
    );
  }
}
