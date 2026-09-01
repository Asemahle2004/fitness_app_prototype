import 'dart:math' as math;

import 'superset_engine.dart';
import 'workout_engine.dart';

class ShortOnTimePlan {
  final List<ExercisePrescription> exercises;
  final List<int> completedSets;
  final int currentIndex;
  final int requestedMinutes;
  final int estimatedMinutes;
  final int originalRemainingSets;
  final int adaptedRemainingSets;
  final List<String> removedExercises;
  final List<String> reducedExercises;

  const ShortOnTimePlan({
    required this.exercises,
    required this.completedSets,
    required this.currentIndex,
    required this.requestedMinutes,
    required this.estimatedMinutes,
    required this.originalRemainingSets,
    required this.adaptedRemainingSets,
    required this.removedExercises,
    required this.reducedExercises,
  });

  bool get changed =>
      removedExercises.isNotEmpty ||
      reducedExercises.isNotEmpty ||
      adaptedRemainingSets < originalRemainingSets;

  String get summary {
    final parts = <String>[
      'about $estimatedMinutes min',
      '$adaptedRemainingSets remaining set${adaptedRemainingSets == 1 ? '' : 's'}',
    ];
    if (removedExercises.isNotEmpty) {
      parts.add('${removedExercises.length} lower-priority exercise${removedExercises.length == 1 ? '' : 's'} removed');
    }
    return parts.join(' • ');
  }
}

class ShortOnTimeEngine {
  static const int minimumMinutes = 5;
  static const int maximumMinutes = 90;

  static ShortOnTimePlan adapt({
    required List<ExercisePrescription> exercises,
    required List<int> completedSets,
    required int currentIndex,
    required int minutesRemaining,
  }) {
    if (exercises.isEmpty) {
      return ShortOnTimePlan(
        exercises: const [],
        completedSets: const [],
        currentIndex: 0,
        requestedMinutes: minutesRemaining.clamp(minimumMinutes, maximumMinutes),
        estimatedMinutes: 0,
        originalRemainingSets: 0,
        adaptedRemainingSets: 0,
        removedExercises: const [],
        reducedExercises: const [],
      );
    }

    final requested = minutesRemaining.clamp(minimumMinutes, maximumMinutes);
    final normalized = SupersetEngine.normalize(exercises);
    final safeCompleted = List<int>.generate(
      normalized.length,
      (index) => index < completedSets.length
          ? completedSets[index].clamp(0, normalized[index].sets)
          : 0,
    );
    final workingSets = normalized.map((e) => e.sets).toList();
    final originalRemaining = _remainingSetCount(workingSets, safeCompleted);
    final budgetSeconds = requested * 60;

    final protectedIndexes = <int>{};
    if (currentIndex >= 0 && currentIndex < normalized.length) {
      protectedIndexes.add(currentIndex);
      protectedIndexes.addAll(SupersetEngine.membersFor(normalized, currentIndex));
    }

    int estimate() => _estimateSessionSeconds(
          normalized,
          workingSets,
          safeCompleted,
          currentIndex,
        );

    // Stage 1: remove optional volume from low-priority movements first.
    while (estimate() > budgetSeconds) {
      final index = _bestSetToTrim(
        normalized,
        workingSets,
        safeCompleted,
        currentIndex,
        protectedIndexes,
        allowLastUnstartedSet: false,
      );
      if (index == null) break;
      _trimOneSetRespectingPair(
        normalized,
        workingSets,
        safeCompleted,
        index,
      );
    }

    // Stage 2: if needed, remove whole low-priority unstarted movements.
    while (estimate() > budgetSeconds) {
      final index = _bestSetToTrim(
        normalized,
        workingSets,
        safeCompleted,
        currentIndex,
        protectedIndexes,
        allowLastUnstartedSet: true,
      );
      if (index == null) break;
      _trimOneSetRespectingPair(
        normalized,
        workingSets,
        safeCompleted,
        index,
      );
    }

    final removed = <String>[];
    final reduced = <String>[];
    final adaptedExercises = <ExercisePrescription>[];
    final adaptedCompleted = <int>[];

    for (var i = 0; i < normalized.length; i += 1) {
      final original = normalized[i];
      final targetSets = workingSets[i];
      final completed = safeCompleted[i];

      if (targetSets <= 0 && completed == 0) {
        removed.add(original.name);
        continue;
      }

      final safeTarget = math.max(targetSets, completed);
      if (safeTarget < original.sets) reduced.add(original.name);
      adaptedExercises.add(original.copyWith(sets: safeTarget));
      adaptedCompleted.add(completed.clamp(0, safeTarget));
    }

    final adaptedRemaining = _remainingSetCount(
      adaptedExercises.map((e) => e.sets).toList(),
      adaptedCompleted,
    );
    final estimatedSeconds = _estimateSessionSeconds(
      adaptedExercises,
      adaptedExercises.map((e) => e.sets).toList(),
      adaptedCompleted,
      _mappedCurrentIndex(
        normalized,
        workingSets,
        safeCompleted,
        currentIndex,
      ),
    );

    return ShortOnTimePlan(
      exercises: adaptedExercises,
      completedSets: adaptedCompleted,
      currentIndex: _mappedCurrentIndex(
        normalized,
        workingSets,
        safeCompleted,
        currentIndex,
      ),
      requestedMinutes: requested,
      estimatedMinutes: math.max(1, (estimatedSeconds / 60).ceil()),
      originalRemainingSets: originalRemaining,
      adaptedRemainingSets: adaptedRemaining,
      removedExercises: removed,
      reducedExercises: reduced.toSet().toList(growable: false),
    );
  }

  static int _mappedCurrentIndex(
    List<ExercisePrescription> exercises,
    List<int> targetSets,
    List<int> completed,
    int currentIndex,
  ) {
    if (currentIndex < 0 || currentIndex >= exercises.length) return 0;
    var mapped = 0;
    for (var i = 0; i < currentIndex; i += 1) {
      if (targetSets[i] > 0 || completed[i] > 0) mapped += 1;
    }
    return mapped;
  }

  static int _remainingSetCount(List<int> targets, List<int> completed) {
    var total = 0;
    for (var i = 0; i < targets.length; i += 1) {
      final done = i < completed.length ? completed[i] : 0;
      total += math.max(0, targets[i] - done);
    }
    return total;
  }

  static int _estimateSessionSeconds(
    List<ExercisePrescription> exercises,
    List<int> targetSets,
    List<int> completed,
    int currentIndex,
  ) {
    if (exercises.isEmpty) return 0;
    var total = 0;
    for (var i = 0; i < exercises.length; i += 1) {
      final remaining = math.max(0, targetSets[i] - completed[i]);
      if (remaining == 0) continue;
      total += _exerciseSeconds(exercises[i], remaining);
      if (i != exercises.length - 1) total += 20; // transition/setup time
    }
    // Small fixed allowance for the user to log sets and move between stations.
    if (total > 0) total += 45;
    return total;
  }

  static int _exerciseSeconds(ExercisePrescription exercise, int remainingSets) {
    if (remainingSets <= 0) return 0;
    if (exercise.isSingleDurationBlock) {
      return _durationTargetSeconds(exercise.reps).clamp(60, 45 * 60);
    }

    final workPerSet = _estimatedWorkSeconds(exercise.reps);
    final rest = _restSeconds(exercise.rest);
    return (workPerSet * remainingSets) + (rest * math.max(0, remainingSets - 1));
  }

  static int _estimatedWorkSeconds(String reps) {
    final numbers = RegExp(r'\d+').allMatches(reps).map((m) => int.parse(m.group(0)!)).toList();
    final target = numbers.isEmpty ? 10 : numbers.last.clamp(1, 30);
    return (target * 3).clamp(20, 90);
  }

  static int _durationTargetSeconds(String value) {
    final lower = value.toLowerCase();
    final number = RegExp(r'\d+').firstMatch(lower);
    if (number == null) return 10 * 60;
    final amount = int.tryParse(number.group(0)!) ?? 10;
    if (lower.contains('min')) return amount * 60;
    if (lower.contains('sec')) return amount;
    if (lower.contains('km')) return amount * 7 * 60;
    return 10 * 60;
  }

  static int _restSeconds(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('none')) return 0;
    if (lower.contains('as needed')) return 60;
    final number = RegExp(r'\d+').firstMatch(lower);
    if (number == null) return 60;
    final amount = int.tryParse(number.group(0)!) ?? 60;
    return lower.contains('min') ? amount * 60 : amount;
  }

  static int? _bestSetToTrim(
    List<ExercisePrescription> exercises,
    List<int> targetSets,
    List<int> completed,
    int currentIndex,
    Set<int> protectedIndexes, {
    required bool allowLastUnstartedSet,
  }) {
    int? bestIndex;
    double bestScore = double.infinity;

    for (var i = 0; i < exercises.length; i += 1) {
      if (i < currentIndex && completed[i] >= targetSets[i]) continue;
      final remaining = targetSets[i] - completed[i];
      if (remaining <= 0) continue;

      final pair = SupersetEngine.membersFor(exercises, i);
      if (pair.length == 2 && i != pair.first) continue;

      final minimum = _minimumTargetSets(
        exercises,
        targetSets,
        completed,
        i,
        protectedIndexes,
        allowLastUnstartedSet: allowLastUnstartedSet,
      );
      if (targetSets[i] <= minimum) continue;

      if (pair.length == 2) {
        final partner = pair.last;
        final partnerMin = _minimumTargetSets(
          exercises,
          targetSets,
          completed,
          partner,
          protectedIndexes,
          allowLastUnstartedSet: allowLastUnstartedSet,
        );
        if (targetSets[partner] <= partnerMin) continue;
      }

      final score = _priorityScore(exercises[i], i, currentIndex, completed[i]);
      if (score < bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  static int _minimumTargetSets(
    List<ExercisePrescription> exercises,
    List<int> targets,
    List<int> completed,
    int index,
    Set<int> protectedIndexes, {
    required bool allowLastUnstartedSet,
  }) {
    final done = completed[index];
    if (protectedIndexes.contains(index)) {
      return math.min(targets[index], done + 1);
    }
    if (done > 0) return done;
    if (!allowLastUnstartedSet) return 1;
    return 0;
  }

  static void _trimOneSetRespectingPair(
    List<ExercisePrescription> exercises,
    List<int> targets,
    List<int> completed,
    int index,
  ) {
    final pair = SupersetEngine.membersFor(exercises, index);
    if (pair.length == 2) {
      for (final member in pair) {
        targets[member] = math.max(completed[member], targets[member] - 1);
      }
      return;
    }
    targets[index] = math.max(completed[index], targets[index] - 1);
  }

  static double _priorityScore(
    ExercisePrescription exercise,
    int index,
    int currentIndex,
    int completed,
  ) {
    var score = 100.0 - (index * 7.0);
    if (index == currentIndex) score += 80;
    if (completed > 0) score += 45;
    if (_isPrimaryMovement(exercise)) score += 35;
    if (_isAccessoryMovement(exercise)) score -= 25;
    if (exercise.dropSetCount > 0) score -= 8;
    return score;
  }

  static bool _isPrimaryMovement(ExercisePrescription exercise) {
    final text = '${exercise.name} ${exercise.target}'.toLowerCase();
    return const [
      'squat',
      'deadlift',
      'bench press',
      'chest press',
      'shoulder press',
      'overhead press',
      'row',
      'pull-up',
      'pull up',
      'pulldown',
      'lunge',
      'hip thrust',
      'leg press',
    ].any(text.contains);
  }

  static bool _isAccessoryMovement(ExercisePrescription exercise) {
    final text = exercise.name.toLowerCase();
    return const [
      'curl',
      'lateral raise',
      'reverse fly',
      'fly',
      'pushdown',
      'extension',
      'calf raise',
      'kickback',
    ].any(text.contains);
  }
}
