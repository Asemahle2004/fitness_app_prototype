import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise_repository.dart';
import 'profile_service.dart';
import 'safety_engine.dart';
import 'workout_engine.dart';

enum ExerciseSwapReason {
  equipmentUnavailable('Equipment unavailable'),
  tooDifficult('Too difficult'),
  painDiscomfort('Pain / discomfort'),
  dislike('Don’t like this exercise'),
  variation('Want variation');

  final String label;
  const ExerciseSwapReason(this.label);
}

class ExerciseSwapSuggestion {
  final ExercisePrescription exercise;
  final int score;
  final List<String> reasons;

  const ExerciseSwapSuggestion({
    required this.exercise,
    required this.score,
    required this.reasons,
  });
}

class ExerciseSwapResult {
  final List<ExerciseSwapSuggestion> suggestions;
  final bool blocked;
  final String? message;

  const ExerciseSwapResult({
    required this.suggestions,
    this.blocked = false,
    this.message,
  });
}

class ExerciseSwapService {
  static const _historyKey = 'leanit_exercise_swaps_v1';

  final SupabaseClient client;
  final ExerciseRepository repository;
  final ProfileService profiles;

  ExerciseSwapService(this.client)
      : repository = ExerciseRepository(client),
        profiles = ProfileService(client);

  Future<ExerciseSwapResult> suggestions({
    required ExercisePrescription current,
    required List<ExercisePrescription> sessionExercises,
    required ExerciseSwapReason reason,
  }) async {
    final profileMap = await _profileMapSafely();
    final safety = _safetyProfile(profileMap);

    if (reason == ExerciseSwapReason.painDiscomfort) {
      if (safety.needsMedicalReview) {
        return const ExerciseSwapResult(
          suggestions: [],
          blocked: true,
          message:
              'Your saved profile includes a warning sign. Stop app-directed training and follow the safety guidance in LeanIt before continuing.',
        );
      }
      if (!safety.hasLimitation || safety.affectedAreas.isEmpty) {
        return const ExerciseSwapResult(
          suggestions: [],
          blocked: true,
          message:
              'Stop this exercise if you have new or increasing pain. Update your Pain, injury or limitations profile first so LeanIt can filter replacements safely.',
        );
      }
    }

    final catalogue = await repository.fetchAll();
    if (catalogue.isEmpty) {
      return const ExerciseSwapResult(
        suggestions: [],
        message: 'No exercise alternatives are available right now.',
      );
    }

    final usedNames = sessionExercises
        .map((exercise) => exercise.name.trim().toLowerCase())
        .toSet();
    final preferredLocations = _strings(profileMap?['training_locations']).toSet();
    final homeEquipment = _strings(profileMap?['home_equipment']).toSet();
    final gymAccess = profileMap?['gym_access']?.toString();

    final ranked = <ExerciseSwapSuggestion>[];
    for (final candidate in catalogue) {
      final candidateName = candidate.name.trim().toLowerCase();
      if (candidateName == current.name.trim().toLowerCase()) continue;
      if (usedNames.contains(candidateName)) continue;

      if (safety.hasLimitation &&
          !SafetyEngine.exerciseNameAllowed(
            candidate.name,
            safety,
            target:
                '${candidate.primaryMuscles.join(' ')} ${candidate.secondaryMuscles.join(' ')} ${candidate.movementPattern ?? ''}',
            equipment: candidate.equipment.join(' '),
          )) {
        continue;
      }

      if (preferredLocations.isNotEmpty && candidate.locations.isNotEmpty) {
        final locationMatch =
            candidate.locations.any((location) => preferredLocations.contains(location));
        if (!locationMatch) continue;
      }

      final scoring = ExerciseSwapRanker.score(
        current: current,
        candidate: candidate,
        reason: reason,
        homeEquipment: homeEquipment,
        gymAccess: gymAccess,
      );
      if (scoring.score <= 0) continue;

      ranked.add(
        ExerciseSwapSuggestion(
          exercise: _prescriptionFromCandidate(current, candidate),
          score: scoring.score,
          reasons: scoring.reasons,
        ),
      );
    }

    ranked.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      return a.exercise.name.compareTo(b.exercise.name);
    });

    return ExerciseSwapResult(
      suggestions: ranked.take(8).toList(growable: false),
      message: ranked.isEmpty
          ? 'LeanIt could not find a suitable alternative that passes the current filters.'
          : null,
    );
  }

  Future<void> saveSwap({
    required String workoutTitle,
    required String fromExercise,
    required String toExercise,
    required ExerciseSwapReason reason,
  }) async {
    final now = DateTime.now();
    final record = {
      'workout_title': workoutTitle,
      'from_exercise': fromExercise,
      'to_exercise': toExercise,
      'reason': reason.name,
      'reason_label': reason.label,
      'swapped_at': now.toIso8601String(),
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_historyKey) ?? <String>[];
      await prefs.setStringList(
        _historyKey,
        [jsonEncode(record), ...existing].take(200).toList(growable: false),
      );
    } catch (_) {}

    final user = client.auth.currentUser;
    if (user == null) return;
    try {
      await client.from('exercise_swap_logs').insert({
        'user_id': user.id,
        ...record,
      });
    } catch (_) {
      // Local swap history is authoritative while cloud sync/table access is
      // unavailable. A missing optional analytics table must not block training.
    }
  }

  Future<Map<String, dynamic>?> _profileMapSafely() async {
    try {
      return await profiles.currentProfileMap();
    } catch (_) {
      return null;
    }
  }

  SafetyProfile _safetyProfile(Map<String, dynamic>? map) {
    return SafetyProfile(
      hasLimitation: map?['has_limitation'] == true,
      affectedAreas: _strings(map?['affected_areas']).toSet(),
      warningSigns: _strings(map?['warning_signs']).toSet(),
      notes: map?['limitation_notes']?.toString() ?? '',
    );
  }

  List<String> _strings(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  ExercisePrescription _prescriptionFromCandidate(
    ExercisePrescription current,
    OnlineExercise candidate,
  ) {
    final target = <String>{
      ...candidate.primaryMuscles,
      ...candidate.secondaryMuscles.take(2),
    }.where((value) => value.trim().isNotEmpty).join(', ');

    return ExercisePrescription(
      name: candidate.name,
      sets: current.sets,
      reps: current.reps,
      rest: current.rest,
      equipment: candidate.equipment.isEmpty
          ? 'Bodyweight'
          : candidate.equipment.join(' + '),
      target: target.isEmpty ? current.target : target,
      metricLabel: current.metricLabel,
    );
  }
}

class ExerciseSwapScore {
  final int score;
  final List<String> reasons;

  const ExerciseSwapScore(this.score, this.reasons);
}

class ExerciseSwapRanker {
  static ExerciseSwapScore score({
    required ExercisePrescription current,
    required OnlineExercise candidate,
    required ExerciseSwapReason reason,
    Set<String> homeEquipment = const {},
    String? gymAccess,
  }) {
    var score = 0;
    final why = <String>[];

    final currentMuscles = _muscleTokens('${current.target} ${current.name}');
    final candidateMuscles = _muscleTokens(
      '${candidate.primaryMuscles.join(' ')} ${candidate.secondaryMuscles.join(' ')}',
    );
    final muscleOverlap = currentMuscles.intersection(candidateMuscles).length;
    if (muscleOverlap > 0) {
      score += muscleOverlap * 12;
      why.add('same target area');
    }

    final currentPatterns = _movementTokens('${current.name} ${current.target}');
    final candidatePatterns = _movementTokens(
      '${candidate.name} ${candidate.movementPattern ?? ''} ${candidate.category ?? ''}',
    );
    final patternOverlap = currentPatterns.intersection(candidatePatterns).length;
    if (patternOverlap > 0) {
      score += patternOverlap * 9;
      why.add('similar movement');
    }

    final currentEquipment = _normaliseEquipment(current.equipment);
    final candidateEquipment =
        _normaliseEquipment(candidate.equipment.join(' '));

    if (reason == ExerciseSwapReason.equipmentUnavailable) {
      if (candidateEquipment.contains('bodyweight')) {
        score += 14;
        why.add('no equipment needed');
      }
      if (candidateEquipment.intersection(currentEquipment).isEmpty) {
        score += 8;
        why.add('different equipment');
      } else {
        score -= 8;
      }
      final available = _normaliseEquipment(homeEquipment.join(' '));
      if (available.isNotEmpty &&
          candidateEquipment.intersection(available).isNotEmpty) {
        score += 8;
        why.add('matches saved equipment');
      }
      if (gymAccess != null && candidate.locations.contains('Gym')) {
        score += 3;
      }
    } else if (candidateEquipment.intersection(currentEquipment).isNotEmpty) {
      score += 4;
      why.add('similar setup');
    }

    if (reason == ExerciseSwapReason.tooDifficult) {
      final difficulty = candidate.difficulty?.toLowerCase() ?? '';
      if (difficulty == 'beginner') {
        score += 12;
        why.add('beginner-friendly');
      } else if (difficulty == 'intermediate') {
        score += 3;
      } else if (difficulty == 'expert') {
        score -= 10;
      }
      if (candidateEquipment.contains('bodyweight')) score += 3;
    }

    if (reason == ExerciseSwapReason.variation) {
      if (muscleOverlap > 0 && patternOverlap == 0) {
        score += 5;
        why.add('new variation for the same target');
      }
    }

    if (reason == ExerciseSwapReason.painDiscomfort) {
      // SafetyEngine filtering happens before scoring. Keep the ranking modest
      // so matching the target does not override the conservative safety gate.
      score += 2;
      why.add('passes saved limitation filter');
    }

    if (reason == ExerciseSwapReason.dislike && muscleOverlap > 0) {
      score += 3;
    }

    return ExerciseSwapScore(score, why.toSet().take(3).toList(growable: false));
  }

  static Set<String> _muscleTokens(String value) {
    final text = value.toLowerCase();
    const groups = <String, List<String>>{
      'chest': ['chest', 'pec'],
      'back': ['back', 'lat', 'lats', 'traps'],
      'shoulders': ['shoulder', 'shoulders', 'delts', 'rear delts'],
      'biceps': ['biceps', 'bicep'],
      'triceps': ['triceps', 'tricep'],
      'quads': ['quads', 'quadriceps'],
      'hamstrings': ['hamstring', 'hamstrings'],
      'glutes': ['glute', 'glutes'],
      'calves': ['calf', 'calves'],
      'core': ['core', 'abdominals', 'abs'],
      'hips': ['hip', 'hips', 'abductors', 'adductors'],
      'forearms': ['forearm', 'forearms'],
    };

    final result = <String>{};
    for (final entry in groups.entries) {
      if (entry.value.any(text.contains)) result.add(entry.key);
    }
    return result;
  }

  static Set<String> _movementTokens(String value) {
    final text = value.toLowerCase();
    final result = <String>{};
    const groups = <String, List<String>>{
      'push': ['push', 'press'],
      'pull': ['pull', 'row', 'curl'],
      'squat': ['squat', 'leg press'],
      'lunge': ['lunge', 'split squat', 'step-up', 'step up'],
      'hinge': ['deadlift', 'romanian', 'hinge', 'good morning'],
      'bridge': ['bridge', 'hip thrust'],
      'core': ['plank', 'dead bug', 'bird dog', 'core'],
      'cardio': ['run', 'walk', 'cycle', 'cardio', 'interval'],
    };
    for (final entry in groups.entries) {
      if (entry.value.any(text.contains)) result.add(entry.key);
    }
    return result;
  }

  static Set<String> _normaliseEquipment(String value) {
    final text = value.toLowerCase();
    final result = <String>{};
    if (text.contains('body') || text.contains('none')) result.add('bodyweight');
    if (text.contains('dumbbell')) result.add('dumbbell');
    if (text.contains('barbell')) result.add('barbell');
    if (text.contains('band')) result.add('band');
    if (text.contains('kettlebell')) result.add('kettlebell');
    if (text.contains('bench')) result.add('bench');
    if (text.contains('cable')) result.add('cable');
    if (text.contains('machine')) result.add('machine');
    if (text.contains('pull-up') || text.contains('pull up')) result.add('pullupbar');
    if (text.contains('medicine ball')) result.add('medicineball');
    if (text.contains('exercise ball')) result.add('exerciseball');
    return result;
  }
}