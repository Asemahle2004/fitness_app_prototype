import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise_media.dart';
import 'exercise_performance_store.dart';
import 'exercise_swap_service.dart';
import 'progression_engine.dart';
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
  bool _finishingSet = false;
  bool _swapping = false;

  late final List<ExercisePrescription> _sessionExercises;
  late final ExercisePerformanceStore _performanceStore;
  late final ExerciseSwapService _swapService;

  final TextEditingController _weightController = TextEditingController();
  ExerciseSetPerformance? _previousPerformance;
  ProgressionSuggestion? _progressionSuggestion;
  bool _performanceLoading = false;
  double? _activeSetWeightKg;
  String? _lastSavedSummary;

  bool get isComplete =>
      _sessionExercises.isNotEmpty &&
      completedExercises >= _sessionExercises.length;

  ExercisePrescription get currentExercise => _sessionExercises[currentIndex];

  bool get currentIsTimed => _isTimedExercise(currentExercise);

  @override
  void initState() {
    super.initState();
    _sessionExercises = List<ExercisePrescription>.from(widget.workout.exercises);
    final client = Supabase.instance.client;
    _performanceStore = ExercisePerformanceStore(client);
    _swapService = ExerciseSwapService(client);

    if (_sessionExercises.isNotEmpty) {
      _resetCurrentExerciseState();
      unawaited(_loadPreviousPerformance(currentExercise.name));
    }

    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || isComplete || _sessionExercises.isEmpty) return;
      setState(() => workoutSeconds += 1);
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _workoutTimer?.cancel();
    _weightController.dispose();
    super.dispose();
  }

  void _resetCurrentExerciseState() {
    currentSet = 1;
    phase = LivePhase.ready;
    displayedRep = 0;
    targetReps = _defaultRepTarget(currentExercise);
    workSecondsTarget = _defaultWorkSeconds(currentExercise);
    workSecondsRemaining = workSecondsTarget;
    restSecondsRemaining = _parseRestSeconds(currentExercise.rest);
    _phaseStartedAt = null;
    _activeSetWeightKg = null;
    _previousPerformance = null;
    _progressionSuggestion = null;
    _performanceLoading = true;
    _weightController.clear();
  }

  Future<void> _loadPreviousPerformance(String exerciseName) async {
    try {
      final previous = await _performanceStore.latestForExercise(exerciseName);
      if (!mounted || isComplete || currentExercise.name != exerciseName) return;
      setState(() {
        _previousPerformance = previous;
        _progressionSuggestion = ProgressionEngine.suggest(
          exercise: currentExercise,
          previous: previous,
        );
        _performanceLoading = false;

        final suggestion = _progressionSuggestion;
        if (suggestion?.targetReps != null) {
          targetReps = suggestion!.targetReps!;
        }
        if (suggestion?.targetDurationSeconds != null) {
          workSecondsTarget = suggestion!.targetDurationSeconds!;
          workSecondsRemaining = workSecondsTarget;
        }

        final suggestedWeight = suggestion?.targetWeightKg;
        if (suggestedWeight != null && _weightController.text.isEmpty) {
          _weightController.text = _formatWeight(suggestedWeight);
        } else if (previous?.weightKg != null && _weightController.text.isEmpty) {
          _weightController.text = _formatWeight(previous!.weightKg!);
        }
      });
    } catch (_) {
      if (!mounted || isComplete || currentExercise.name != exerciseName) return;
      setState(() => _performanceLoading = false);
    }
  }

  double? _enteredWeightKg() {
    final raw = _weightController.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    if (value == null || value < 0) return null;
    return value;
  }

  void _startSet() {
    _tickTimer?.cancel();
    _activeSetWeightKg = currentIsTimed ? null : _enteredWeightKg();

    setState(() {
      phase = LivePhase.active;
      displayedRep = 0;
      targetReps = targetReps <= 0
          ? _defaultRepTarget(currentExercise)
          : targetReps;
      workSecondsTarget = workSecondsTarget <= 0
          ? _defaultWorkSeconds(currentExercise)
          : workSecondsTarget;
      workSecondsRemaining = workSecondsTarget;
      _phaseStartedAt = DateTime.now();
    });

    if (currentIsTimed) {
      _tickTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted || phase != LivePhase.active || _finishingSet) return;
        final elapsed = DateTime.now().difference(_phaseStartedAt!).inMilliseconds;
        final remaining = workSecondsTarget - (elapsed / 1000).floor();
        if (remaining <= 0) {
          setState(() => workSecondsRemaining = 0);
          unawaited(_finishSet());
          return;
        }
        if (remaining != workSecondsRemaining) {
          setState(() => workSecondsRemaining = remaining);
        }
      });
    } else {
      _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted || phase != LivePhase.active || _finishingSet) return;
        final elapsed =
            DateTime.now().difference(_phaseStartedAt!).inMilliseconds / 1000;
        final rep = (elapsed / selectedPace.secondsPerRep).floor() + 1;
        final clamped = rep.clamp(1, targetReps);
        if (clamped != displayedRep) {
          setState(() => displayedRep = clamped);
        }
        if (elapsed >= targetReps * selectedPace.secondsPerRep) {
          setState(() => displayedRep = targetReps);
          unawaited(_finishSet());
        }
      });
    }
  }

  Future<void> _finishSet() async {
    if (_finishingSet) return;
    _finishingSet = true;
    _tickTimer?.cancel();

    final exercise = currentExercise;
    final setNumber = currentSet;
    final actualReps = currentIsTimed
        ? null
        : (displayedRep > 0 ? displayedRep : targetReps);
    final durationSeconds = currentIsTimed
        ? (workSecondsTarget - workSecondsRemaining).clamp(0, workSecondsTarget)
        : null;
    final weightKg = _activeSetWeightKg;

    completedSets += 1;

    final savedSummary = currentIsTimed
        ? _durationSummary(durationSeconds ?? workSecondsTarget)
        : _setSummary(actualReps ?? targetReps, weightKg);
    _lastSavedSummary = '${exercise.name} • Set $setNumber • $savedSummary';

    unawaited(
      _saveSetPerformance(
        exerciseName: exercise.name,
        setNumber: setNumber,
        reps: actualReps,
        weightKg: weightKg,
        durationSeconds: durationSeconds,
      ),
    );

    final hasMoreSets = currentSet < currentExercise.sets;
    final hasMoreExercises = currentIndex < _sessionExercises.length - 1;

    _finishingSet = false;

    if (hasMoreSets || hasMoreExercises) {
      _startRest();
    } else {
      _finishExerciseAndAdvance();
    }
  }

  Future<void> _saveSetPerformance({
    required String exerciseName,
    required int setNumber,
    required int? reps,
    required double? weightKg,
    required int? durationSeconds,
  }) async {
    try {
      await _performanceStore.saveSet(
        workoutTitle: widget.workout.title,
        exerciseName: exerciseName,
        setNumber: setNumber,
        reps: reps,
        weightKg: weightKg,
        durationSeconds: durationSeconds,
      );
    } catch (_) {
      // Workout flow continues if local/cloud logging has a temporary issue.
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
        _activeSetWeightKg = null;
      });
      return;
    }
    _finishExerciseAndAdvance();
  }

  void _finishExerciseAndAdvance() {
    _tickTimer?.cancel();
    completedExercises += 1;

    if (completedExercises >= _sessionExercises.length) {
      setState(() => phase = LivePhase.ready);
      unawaited(_saveHistory());
      return;
    }

    setState(() {
      currentIndex += 1;
      _resetCurrentExerciseState();
    });
    unawaited(_loadPreviousPerformance(currentExercise.name));
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
        exercises: _sessionExercises
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
        Duration(
          seconds: _parseRestSeconds(currentExercise.rest) -
              restSecondsRemaining,
        ),
      );
    });
  }

  void _skipSet() {
    _tickTimer?.cancel();
    unawaited(_finishSet());
  }

  Future<void> _openSwapFlow() async {
    if (_swapping || phase != LivePhase.ready || currentSet != 1) return;

    final reason = await showModalBottomSheet<ExerciseSwapReason>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Why replace this exercise?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'LeanIt uses the reason to rank safer and more useful alternatives.',
                  style: TextStyle(color: Color(0xFF627D98)),
                ),
                const SizedBox(height: 12),
                ...ExerciseSwapReason.values.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_swapReasonIcon(item)),
                    title: Text(item.label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(sheetContext, item),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (reason == null || !mounted) return;

    setState(() => _swapping = true);
    ExerciseSwapResult result;
    try {
      result = await _swapService.suggestions(
        current: currentExercise,
        sessionExercises: _sessionExercises,
        reason: reason,
      );
    } catch (_) {
      result = const ExerciseSwapResult(
        suggestions: [],
        message: 'LeanIt could not load replacement options right now.',
      );
    }
    if (!mounted) return;
    setState(() => _swapping = false);

    if (result.blocked || result.suggestions.isEmpty) {
      await _showSwapMessage(
        result.message ?? 'No suitable replacement was found.',
        warning: result.blocked,
      );
      return;
    }

    final selected = await showModalBottomSheet<ExerciseSwapSuggestion>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Text(
                  'Replace ${currentExercise.name}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Reason: ${reason.label}',
                  style: const TextStyle(color: Color(0xFF627D98)),
                ),
                const SizedBox(height: 14),
                ...result.suggestions.map(
                  (suggestion) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE5F4F8),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          color: Color(0xFF176B87),
                        ),
                      ),
                      title: Text(
                        suggestion.exercise.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          [
                            suggestion.exercise.target,
                            suggestion.exercise.equipment,
                            if (suggestion.reasons.isNotEmpty)
                              suggestion.reasons.join(' • '),
                          ].join('\n'),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pop(sheetContext, suggestion),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected == null || !mounted) return;

    final previousName = currentExercise.name;
    final replacement = selected.exercise;
    setState(() {
      _sessionExercises[currentIndex] = replacement;
      _resetCurrentExerciseState();
    });
    unawaited(_loadPreviousPerformance(replacement.name));
    unawaited(
      _swapService.saveSwap(
        workoutTitle: widget.workout.title,
        fromExercise: previousName,
        toExercise: replacement.name,
        reason: reason,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$previousName replaced with ${replacement.name}.'),
      ),
    );
  }

  Future<void> _showSwapMessage(String message, {bool warning = false}) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          warning ? Icons.health_and_safety_outlined : Icons.info_outline,
          color: warning ? const Color(0xFF9A6700) : const Color(0xFF176B87),
        ),
        title: Text(warning ? 'Safety check' : 'No replacement available'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  IconData _swapReasonIcon(ExerciseSwapReason reason) {
    switch (reason) {
      case ExerciseSwapReason.equipmentUnavailable:
        return Icons.fitness_center_outlined;
      case ExerciseSwapReason.tooDifficult:
        return Icons.trending_down_rounded;
      case ExerciseSwapReason.painDiscomfort:
        return Icons.health_and_safety_outlined;
      case ExerciseSwapReason.dislike:
        return Icons.thumb_down_alt_outlined;
      case ExerciseSwapReason.variation:
        return Icons.shuffle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = _sessionExercises;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text('Workout • ${_formatClock(workoutSeconds)}'),
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
      ),
      body: SafeArea(
        child: exercises.isEmpty
            ? const Center(
                child: Text('No exercises are available for this workout.'),
              )
            : isComplete
                ? _completeView(context)
                : phase == LivePhase.rest
                    ? _restView()
                    : _activeView(currentExercise),
      ),
    );
  }

  Widget _activeView(ExercisePrescription exercise) {
    final total = _sessionExercises.length;
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
                    const SizedBox(height: 14),
                    _previousPerformanceCard(),
                    if (_progressionSuggestion != null) ...[
                      const SizedBox(height: 10),
                      _progressionSuggestionCard(),
                    ],
                    const SizedBox(height: 14),
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
          const SizedBox(height: 12),
          if (phase == LivePhase.ready && currentSet == 1)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _swapping ? null : _openSwapFlow,
                icon: _swapping
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.swap_horiz_rounded),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                label: Text(_swapping ? 'FINDING ALTERNATIVES…' : 'REPLACE EXERCISE'),
              ),
            ),
          if (phase == LivePhase.ready && currentSet == 1)
            const SizedBox(height: 10),
          if (phase == LivePhase.active)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _finishingSet ? null : _skipSet,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                child: const Text('FINISH SET NOW'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _swapping ? null : _startSet,
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

  Widget _previousPerformanceCard() {
    if (_performanceLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            'Checking your previous performance…',
            style: TextStyle(color: Color(0xFF627D98)),
          ),
        ],
      );
    }

    final previous = _previousPerformance;
    if (previous == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'First logged session for this exercise. LeanIt will remember today’s sets for next time.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Color(0xFF627D98),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB9E2EA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: Color(0xFF176B87)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Last logged set',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF627D98),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${previous.summary} • ${_shortDate(previous.performedAt)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _progressionSuggestionCard() {
    final suggestion = _progressionSuggestion;
    if (suggestion == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8DC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E89A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.trending_up_rounded, color: Color(0xFF0F6B4B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LeanEat progression suggestion',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF55721B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.headline,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.explanation,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF627D98),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This is a suggested starting target, not a requirement. Reduce it if form, comfort or readiness is worse today.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: Color(0xFF829AB1),
                  ),
                ),
              ],
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
            if (_activeSetWeightKg != null) ...[
              const SizedBox(height: 8),
              Text(
                'Load: ${_formatWeight(_activeSetWeightKg!)} kg',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF102A43),
                ),
              ),
            ],
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
            const SizedBox(height: 10),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Load in kg (optional)',
                hintText: 'Example: 10',
                prefixIcon: Icon(Icons.monitor_weight_outlined),
              ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 10),
            const Text(
              'When the set finishes, LeanIt saves the completed reps and optional load to your history.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF627D98),
              ),
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
            const SizedBox(height: 8),
            const Text(
              'Completed time is saved to your exercise history.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF627D98),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _restView() {
    final nextSet = currentSet < currentExercise.sets;
    final nextExercise = currentIndex < _sessionExercises.length - 1
        ? _sessionExercises[currentIndex + 1].name
        : 'Workout complete';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 520;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, compact ? 14 : 28, 24, 24),
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
                  if (_lastSavedSummary != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Saved: $_lastSavedSummary',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF176B87),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
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
              '${_sessionExercises.length} exercises • $completedSets sets • ${_formatClock(workoutSeconds)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF627D98),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your completed set performance has been saved to LeanIt history.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF486581),
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
                  'BACK TO HOME',
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

  static String _shortDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = value.toLocal();
    return '${local.day} ${months[local.month - 1]}';
  }

  static String _formatWeight(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  static String _setSummary(int reps, double? weightKg) {
    if (weightKg == null) return '$reps reps';
    return '${_formatWeight(weightKg)} kg × $reps reps';
  }

  static String _durationSummary(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = safe ~/ 60;
    final remainder = safe % 60;
    return minutes > 0 ? '${minutes}m ${remainder}s' : '${remainder}s';
  }
}