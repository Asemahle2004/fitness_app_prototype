import 'dart:async';

import 'package:flutter/material.dart';

import 'exercise_media.dart';
import 'training_store.dart';
import 'workout_engine.dart';

enum RepPace {
  slow('Slow', 3.0),
  normal('Normal', 2.0),
  fast('Fast', 1.25);

  final String label;
  final double secondsPerRep;
  const RepPace(this.label, this.secondsPerRep);
}

enum LivePhase { ready, active, rest }

class LiveWorkoutScreen extends StatefulWidget {
  final GeneratedWorkout workout;

  const LiveWorkoutScreen({
    super.key,
    required this.workout,
  });

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen> {
  int currentIndex = 0;
  int currentSet = 1;
  int completedExercises = 0;
  int completedSets = 0;

  RepPace selectedPace = RepPace.normal;
  LivePhase phase = LivePhase.ready;

  Timer? _tickTimer;
  Timer? _workoutTimer;
  DateTime? _phaseStartedAt;

  int workoutSeconds = 0;
  int displayedRep = 0;
  int targetReps = 0;
  int workSecondsRemaining = 0;
  int workSecondsTarget = 0;
  int restSecondsRemaining = 0;
  bool _historySaved = false;

  bool get isComplete =>
      widget.workout.exercises.isNotEmpty &&
      completedExercises >= widget.workout.exercises.length;

  ExercisePrescription get currentExercise =>
      widget.workout.exercises[currentIndex];

  bool get currentIsTimed => _isTimedExercise(currentExercise);

  @override
  void initState() {
    super.initState();
    _prepareCurrentExercise();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || isComplete) return;
      setState(() => workoutSeconds += 1);
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _workoutTimer?.cancel();
    super.dispose();
  }

  void _prepareCurrentExercise() {
    currentSet = 1;
    phase = LivePhase.ready;
    displayedRep = 0;
    targetReps = _defaultRepTarget(currentExercise);
    workSecondsTarget = _defaultWorkSeconds(currentExercise);
    workSecondsRemaining = workSecondsTarget;
    restSecondsRemaining = _parseRestSeconds(currentExercise.rest);
    _phaseStartedAt = null;
  }

  void _startSet() {
    _tickTimer?.cancel();
    setState(() {
      phase = LivePhase.active;
      displayedRep = 0;
      targetReps = targetReps <= 0 ? _defaultRepTarget(currentExercise) : targetReps;
      workSecondsTarget = workSecondsTarget <= 0
          ? _defaultWorkSeconds(currentExercise)
          : workSecondsTarget;
      workSecondsRemaining = workSecondsTarget;
      _phaseStartedAt = DateTime.now();
    });

    if (currentIsTimed) {
      _tickTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted || phase != LivePhase.active) return;
        final elapsed = DateTime.now().difference(_phaseStartedAt!).inMilliseconds;
        final remaining = workSecondsTarget - (elapsed / 1000).floor();
        if (remaining <= 0) {
          setState(() => workSecondsRemaining = 0);
          _finishSet();
          return;
        }
        if (remaining != workSecondsRemaining) {
          setState(() => workSecondsRemaining = remaining);
        }
      });
    } else {
      _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted || phase != LivePhase.active) return;
        final elapsed = DateTime.now().difference(_phaseStartedAt!).inMilliseconds / 1000;
        final rep = (elapsed / selectedPace.secondsPerRep).floor() + 1;
        final clamped = rep.clamp(1, targetReps);
        if (clamped != displayedRep) {
          setState(() => displayedRep = clamped);
        }
        if (elapsed >= targetReps * selectedPace.secondsPerRep) {
          setState(() => displayedRep = targetReps);
          _finishSet();
        }
      });
    }
  }

  void _finishSet() {
    _tickTimer?.cancel();
    completedSets += 1;

    final hasMoreSets = currentSet < currentExercise.sets;
    final hasMoreExercises = currentIndex < widget.workout.exercises.length - 1;

    if (hasMoreSets || hasMoreExercises) {
      _startRest();
    } else {
      _finishExerciseAndAdvance();
    }
  }

  void _startRest() {
    final seconds = _parseRestSeconds(currentExercise.rest);
    if (seconds <= 0) {
      _advanceAfterRest();
      return;
    }

    setState(() {
      phase = LivePhase.rest;
      restSecondsRemaining = seconds;
      _phaseStartedAt = DateTime.now();
    });

    _tickTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || phase != LivePhase.rest) return;
      final elapsed = DateTime.now().difference(_phaseStartedAt!).inMilliseconds;
      final remaining = seconds - (elapsed / 1000).floor();
      if (remaining <= 0) {
        setState(() => restSecondsRemaining = 0);
        _advanceAfterRest();
        return;
      }
      if (remaining != restSecondsRemaining) {
        setState(() => restSecondsRemaining = remaining);
      }
    });
  }

  void _advanceAfterRest() {
    _tickTimer?.cancel();
    if (currentSet < currentExercise.sets) {
      setState(() {
        currentSet += 1;
        phase = LivePhase.ready;
        displayedRep = 0;
        workSecondsRemaining = workSecondsTarget;
      });
      return;
    }
    _finishExerciseAndAdvance();
  }

  void _finishExerciseAndAdvance() {
    _tickTimer?.cancel();
    completedExercises += 1;

    if (completedExercises >= widget.workout.exercises.length) {
      setState(() => phase = LivePhase.ready);
      _saveHistory();
      return;
    }

    setState(() {
      currentIndex += 1;
      _prepareCurrentExercise();
    });
  }

  Future<void> _saveHistory() async {
    if (_historySaved) return;
    _historySaved = true;
    await TrainingStore.saveWorkout(
      WorkoutRecord(
        title: widget.workout.title,
        completedAt: DateTime.now(),
        durationSeconds: workoutSeconds,
        completedSets: completedSets,
        exercises: widget.workout.exercises
            .map((exercise) => exercise.name)
            .toList(growable: false),
      ),
    );
  }

  void _skipRest() => _advanceAfterRest();

  void _adjustRest(int delta) {
    setState(() {
      restSecondsRemaining = (restSecondsRemaining + delta).clamp(0, 600);
      _phaseStartedAt = DateTime.now().subtract(
        Duration(seconds: _parseRestSeconds(currentExercise.rest) - restSecondsRemaining),
      );
    });
  }

  void _skipSet() {
    _tickTimer?.cancel();
    _finishSet();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.workout.exercises;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text('Workout • ${_formatClock(workoutSeconds)}'),
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
      ),
      body: SafeArea(
        child: exercises.isEmpty
            ? const Center(child: Text('No exercises are available for this workout.'))
            : isComplete
                ? _completeView(context)
                : phase == LivePhase.rest
                    ? _restView()
                    : _activeView(currentExercise),
      ),
    );
  }

  Widget _activeView(ExercisePrescription exercise) {
    final total = widget.workout.exercises.length;
    final progress = completedExercises / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.workout.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF176B87),
                  ),
                ),
              ),
              Text(
                'Set $currentSet of ${exercise.sets}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF486581),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Exercise ${currentIndex + 1} of $total',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: const Color(0xFFD9E2EC),
            color: const Color(0xFF176B87),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD9E2EC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 290,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: ExerciseMedia(
                          exerciseName: exercise.name,
                          localAsset: exercise.visualAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      exercise.target,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF176B87),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (currentIsTimed)
                      _timedControls(exercise)
                    else
                      _repControls(exercise),
                    const SizedBox(height: 18),
                    _detailRow('Prescription', exercise.summary),
                    _detailRow('Rest', exercise.rest),
                    _detailRow('Equipment', exercise.equipment),
                    const Text(
                      'Move with control and stop if you experience unusual or increasing pain.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF627D98),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (phase == LivePhase.active)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _skipSet,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: const Text('FINISH SET NOW'),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startSet,
                icon: const Icon(Icons.play_arrow_rounded),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: const Color(0xFF176B87),
                  foregroundColor: Colors.white,
                ),
                label: Text(
                  currentIsTimed ? 'START TIMER' : 'START SET',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _repControls(ExercisePrescription exercise) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          if (phase == LivePhase.active) ...[
            const Text(
              'REP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF627D98),
              ),
            ),
            Text(
              '$displayedRep / $targetReps',
              style: const TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.bold,
                color: Color(0xFF176B87),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${selectedPace.label} pace • ${selectedPace.secondsPerRep.toStringAsFixed(selectedPace == RepPace.fast ? 2 : 0)} sec per rep',
              style: const TextStyle(color: Color(0xFF486581)),
            ),
          ] else ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Target reps',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: targetReps > 1
                      ? () => setState(() => targetReps -= 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$targetReps',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => targetReps += 1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Count pace',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<RepPace>(
              segments: RepPace.values
                  .map(
                    (pace) => ButtonSegment<RepPace>(
                      value: pace,
                      label: Text(pace.label),
                    ),
                  )
                  .toList(),
              selected: {selectedPace},
              onSelectionChanged: (value) {
                setState(() => selectedPace = value.first);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _timedControls(ExercisePrescription exercise) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          if (phase == LivePhase.active) ...[
            const Text(
              'TIME REMAINING',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF627D98),
              ),
            ),
            Text(
              _formatClock(workSecondsRemaining),
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Color(0xFF176B87),
              ),
            ),
          ] else ...[
            const Text(
              'Set duration',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: workSecondsTarget > 10
                      ? () => setState(() {
                            workSecondsTarget -= 5;
                            workSecondsRemaining = workSecondsTarget;
                          })
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  _formatClock(workSecondsTarget),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF176B87),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    workSecondsTarget += 5;
                    workSecondsRemaining = workSecondsTarget;
                  }),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _restView() {
    final nextSet = currentSet < currentExercise.sets;
    final nextExercise = currentIndex < widget.workout.exercises.length - 1
        ? widget.workout.exercises[currentIndex + 1].name
        : 'Workout complete';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 520;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            compact ? 14 : 28,
            24,
            24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - (compact ? 38 : 52))
                  .clamp(0.0, double.infinity),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: compact ? 54 : 74,
                    color: const Color(0xFF176B87),
                  ),
                  SizedBox(height: compact ? 8 : 18),
                  const Text(
                    'REST',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF627D98),
                    ),
                  ),
                  Text(
                    _formatClock(restSecondsRemaining),
                    style: TextStyle(
                      fontSize: compact ? 58 : 72,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nextSet
                        ? 'Next: Set ${currentSet + 1} of ${currentExercise.sets} • ${currentExercise.name}'
                        : 'Next exercise: $nextExercise',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF486581),
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => _adjustRest(-15),
                        child: const Text('-15 sec'),
                      ),
                      OutlinedButton(
                        onPressed: () => _adjustRest(15),
                        child: const Text('+15 sec'),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 10 : 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _skipRest,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: const Color(0xFF176B87),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'SKIP REST',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _completeView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFE5F4F8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 50,
                color: Color(0xFF176B87),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Workout complete',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102A43),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.workout.exercises.length} exercises • $completedSets sets • ${_formatClock(workoutSeconds)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF627D98),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: const Color(0xFF176B87),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'BACK TO WORKOUT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF829AB1),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF102A43),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static bool _isTimedExercise(ExercisePrescription exercise) {
    final value = exercise.reps.toLowerCase();
    return value.contains(' sec') ||
        value.endsWith('sec') ||
        value.contains(' min') ||
        value.contains('minute');
  }

  static int _defaultRepTarget(ExercisePrescription exercise) {
    final matches = RegExp(r'\d+').allMatches(exercise.reps).toList();
    if (matches.isEmpty) return 10;
    final numbers = matches
        .map((m) => int.tryParse(m.group(0) ?? '') ?? 0)
        .where((n) => n > 0)
        .toList();
    if (numbers.isEmpty) return 10;
    if (numbers.length == 1) return numbers.first;
    return ((numbers.first + numbers[1]) / 2).round();
  }

  static int _defaultWorkSeconds(ExercisePrescription exercise) {
    final value = exercise.reps.toLowerCase();
    final matches = RegExp(r'\d+').allMatches(value).toList();
    if (matches.isEmpty) return 30;
    final numbers = matches
        .map((m) => int.tryParse(m.group(0) ?? '') ?? 0)
        .where((n) => n > 0)
        .toList();
    if (numbers.isEmpty) return 30;
    final selected = numbers.length == 1
        ? numbers.first
        : ((numbers.first + numbers[1]) / 2).round();
    return value.contains('min') ? selected * 60 : selected;
  }

  static int _parseRestSeconds(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('none')) return 0;
    final match = RegExp(r'\d+').firstMatch(lower);
    if (match == null) return lower.contains('needed') ? 30 : 60;
    final number = int.tryParse(match.group(0) ?? '') ?? 60;
    return lower.contains('min') ? number * 60 : number;
  }

  static String _formatClock(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = safe ~/ 60;
    final secs = safe % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
