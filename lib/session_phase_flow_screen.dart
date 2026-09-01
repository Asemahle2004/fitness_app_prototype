import 'dart:async';

import 'package:flutter/material.dart';

import 'exercise_media.dart';
import 'session_preparation_engine.dart';
import 'session_step_visuals.dart';

class SessionPhaseFlowScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<SessionPhaseStep> steps;
  final String completeLabel;

  const SessionPhaseFlowScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.completeLabel,
  });

  @override
  State<SessionPhaseFlowScreen> createState() => _SessionPhaseFlowScreenState();
}

class _SessionPhaseFlowScreenState extends State<SessionPhaseFlowScreen> {
  int _index = 0;
  int _remaining = 0;
  bool _running = false;
  Timer? _timer;

  SessionPhaseStep get _current => widget.steps[_index];

  @override
  void initState() {
    super.initState();
    if (widget.steps.isNotEmpty) {
      _remaining = widget.steps.first.durationSeconds;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }

    if (_remaining <= 0) {
      setState(() => _remaining = _current.durationSeconds);
    }

    setState(() => _running = true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining <= 1) {
        timer.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
        });
        return;
      }
      setState(() => _remaining -= 1);
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = _current.durationSeconds;
    });
  }

  void _next() {
    _timer?.cancel();
    if (_index >= widget.steps.length - 1) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _index += 1;
      _running = false;
      _remaining = _current.durationSeconds;
    });
  }

  IconData _icon(SessionStepType type) {
    switch (type) {
      case SessionStepType.raiseTemperature:
        return Icons.local_fire_department_outlined;
      case SessionStepType.mobility:
        return Icons.accessibility_new_rounded;
      case SessionStepType.activation:
        return Icons.bolt_rounded;
      case SessionStepType.recovery:
        return Icons.directions_walk_rounded;
      case SessionStepType.stretch:
        return Icons.self_improvement_rounded;
      case SessionStepType.breathing:
        return Icons.air_rounded;
    }
  }

  String _clock(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = safe ~/ 60;
    final remainder = safe % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  Widget _stepVisual() {
    final demonstration = SessionStepVisuals.forStep(_current);
    if (demonstration == null) {
      return Container(
        width: double.infinity,
        height: 178,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD9E2EC)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: const Color(0xFFE5F4F8),
              child: Icon(
                _icon(_current.type),
                size: 36,
                color: const Color(0xFF176B87),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'COACHED MOVEMENT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Color(0xFF176B87),
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'Follow the technique cue below. LeanIt will only show an exercise photo when the movement has a reviewed or approved reference.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: Color(0xFF627D98),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 225,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ExerciseMedia(
              exerciseName: demonstration.exerciseName,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.ondemand_video_outlined,
              size: 16,
              color: Color(0xFF176B87),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${demonstration.label.toUpperCase()} • ${demonstration.exerciseName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                  color: Color(0xFF176B87),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _nextStepPreview() {
    if (_index >= widget.steps.length - 1) return const SizedBox.shrink();
    final next = widget.steps[_index + 1];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon(next.type), color: const Color(0xFF176B87)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UP NEXT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Color(0xFF829AB1),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  next.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _clock(next.durationSeconds),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF486581),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.completeLabel),
          ),
        ),
      );
    }

    final progress = (_index + 1) / widget.steps.length;
    final isLast = _index == widget.steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              widget.subtitle,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Color(0xFF627D98),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(10),
                    backgroundColor: const Color(0xFFD9E2EC),
                    color: const Color(0xFF176B87),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_index + 1}/${widget.steps.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF486581),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD9E2EC)),
              ),
              child: Column(
                children: [
                  _stepVisual(),
                  const SizedBox(height: 16),
                  Text(
                    _current.type.label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF176B87),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _current.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _current.target,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF486581),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _clock(_remaining),
                    style: const TextStyle(
                      fontSize: 58,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF176B87),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _current.cue,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF627D98),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetTimer,
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text('RESET'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleTimer,
                          icon: Icon(
                            _running
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF176B87),
                            foregroundColor: Colors.white,
                          ),
                          label: Text(_running ? 'PAUSE' : 'START'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _nextStepPreview(),
            if (!isLast) const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Keep preparation and recovery comfortable. These steps are not performance tests. Stop or change the movement if discomfort increases.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Color(0xFF486581),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _next,
                icon: Icon(isLast ? Icons.check_rounded : Icons.arrow_forward_rounded),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF102A43),
                  foregroundColor: Colors.white,
                ),
                label: Text(
                  isLast ? widget.completeLabel : 'NEXT STEP',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _next,
              child: Text(isLast ? widget.completeLabel : 'SKIP THIS STEP'),
            ),
          ],
        ),
      ),
    );
  }
}
