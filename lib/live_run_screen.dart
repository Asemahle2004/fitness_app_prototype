import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'personal_record_celebration.dart';
import 'personal_record_engine.dart';
import 'run_tracking_engine.dart';
import 'run_tracking_store.dart';

class LiveRunScreen extends StatefulWidget {
  const LiveRunScreen({super.key});

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
  String _gpsStatus = 'Ready';

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
      _running = true;
      _startTimer();
      await _subscribeGps();
      if (mounted) setState(() => _gpsStatus = 'GPS tracking active');
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
      setState(() => _elapsedSeconds += 1);
    });
  }

  Future<void> _subscribeGps() async {
    await _positionSubscription?.cancel();
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

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
    if (!_running || !_paused) return;
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

    final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Finish run?'),
            content: Text(
              '${(_distanceMeters / 1000).toStringAsFixed(2)} km • '
              '${RunTrackingEngine.formatDuration(_elapsedSeconds)} • '
              '${RunTrackingEngine.formatPace(RunTrackingEngine.paceSecondsPerKm(distanceMeters: _distanceMeters, durationSeconds: _elapsedSeconds))}',
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
    final record = RunRecord(
      id: 'run_${DateTime.now().microsecondsSinceEpoch}',
      startedAt: startedAt,
      durationSeconds: _elapsedSeconds,
      distanceMeters: _distanceMeters,
      source: 'gps',
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

  @override
  Widget build(BuildContext context) {
    final pace = RunTrackingEngine.paceSecondsPerKm(
      distanceMeters: _distanceMeters,
      durationSeconds: _elapsedSeconds,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF102A43),
      appBar: AppBar(
        title: const Text('Run tracker'),
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
              const Spacer(),
              _Metric(
                label: 'DISTANCE',
                value: '${(_distanceMeters / 1000).toStringAsFixed(2)} km',
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
                      value: RunTrackingEngine.formatPace(pace),
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
                    label: Text(_starting ? 'STARTING GPS...' : 'START RUN'),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _paused ? _resume : _pause,
                        icon: Icon(
                          _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        ),
                        label: Text(_paused ? 'RESUME' : 'PAUSE'),
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
                  'Foreground tracking only: keep LeanIt open while the run is active.',
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
