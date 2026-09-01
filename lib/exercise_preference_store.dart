import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ExercisePreferenceRecord {
  final String exerciseName;
  final int score;
  final int dislikeCount;
  final int rejectedSuggestionCount;
  final int selectedAlternativeCount;
  final DateTime? updatedAt;

  const ExercisePreferenceRecord({
    required this.exerciseName,
    required this.score,
    required this.dislikeCount,
    required this.rejectedSuggestionCount,
    required this.selectedAlternativeCount,
    this.updatedAt,
  });

  bool get stronglyAvoided => dislikeCount >= 2 || score <= -45;
  bool get preferred => selectedAlternativeCount >= 2 || score >= 16;

  ExercisePreferenceRecord copyWith({
    int? score,
    int? dislikeCount,
    int? rejectedSuggestionCount,
    int? selectedAlternativeCount,
    DateTime? updatedAt,
  }) {
    return ExercisePreferenceRecord(
      exerciseName: exerciseName,
      score: score ?? this.score,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      rejectedSuggestionCount:
          rejectedSuggestionCount ?? this.rejectedSuggestionCount,
      selectedAlternativeCount:
          selectedAlternativeCount ?? this.selectedAlternativeCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'exercise_name': exerciseName,
        'score': score,
        'dislike_count': dislikeCount,
        'rejected_suggestion_count': rejectedSuggestionCount,
        'selected_alternative_count': selectedAlternativeCount,
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory ExercisePreferenceRecord.fromJson(Map<String, dynamic> json) {
    return ExercisePreferenceRecord(
      exerciseName: json['exercise_name']?.toString() ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      dislikeCount: (json['dislike_count'] as num?)?.toInt() ?? 0,
      rejectedSuggestionCount:
          (json['rejected_suggestion_count'] as num?)?.toInt() ?? 0,
      selectedAlternativeCount:
          (json['selected_alternative_count'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}

class ExercisePreferenceSnapshot {
  final Map<String, ExercisePreferenceRecord> records;

  const ExercisePreferenceSnapshot(this.records);

  ExercisePreferenceRecord? forExercise(String exerciseName) =>
      records[ExercisePreferenceStore.normaliseName(exerciseName)];

  int scoreFor(String exerciseName) => forExercise(exerciseName)?.score ?? 0;

  bool stronglyAvoids(String exerciseName) =>
      forExercise(exerciseName)?.stronglyAvoided ?? false;

  bool prefers(String exerciseName) =>
      forExercise(exerciseName)?.preferred ?? false;
}

/// Local-first memory of exercise choices.
///
/// Preference never bypasses safety, equipment or movement-role filters. It is
/// only used as a ranking signal after a candidate is already suitable.
class ExercisePreferenceStore {
  static const _baseKey = 'leanit_exercise_preferences_v1';

  final String userScope;

  const ExercisePreferenceStore({required this.userScope});

  String get _storageKey {
    final safe = userScope.trim().isEmpty ? 'guest' : userScope.trim();
    return '${_baseKey}_$safe';
  }

  Future<ExercisePreferenceSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const ExercisePreferenceSnapshot(<String, ExercisePreferenceRecord>{});
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final records = <String, ExercisePreferenceRecord>{};
      for (final entry in decoded.entries) {
        if (entry.value is! Map) continue;
        final record = ExercisePreferenceRecord.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
        if (record.exerciseName.trim().isEmpty) continue;
        records[normaliseName(record.exerciseName)] = record;
      }
      return ExercisePreferenceSnapshot(records);
    } catch (_) {
      return const ExercisePreferenceSnapshot(<String, ExercisePreferenceRecord>{});
    }
  }

  Future<void> recordDislike(String exerciseName) => _update(
        exerciseName,
        scoreDelta: -28,
        dislikeDelta: 1,
      );

  Future<void> recordRejectedSuggestion(String exerciseName) => _update(
        exerciseName,
        scoreDelta: -10,
        rejectedDelta: 1,
      );

  Future<void> recordSelectedAlternative(String exerciseName) => _update(
        exerciseName,
        scoreDelta: 8,
        selectedDelta: 1,
      );

  Future<void> clearExercise(String exerciseName) async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = await load();
    final records = Map<String, ExercisePreferenceRecord>.from(snapshot.records);
    records.remove(normaliseName(exerciseName));
    await _write(prefs, records);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _update(
    String exerciseName, {
    required int scoreDelta,
    int dislikeDelta = 0,
    int rejectedDelta = 0,
    int selectedDelta = 0,
  }) async {
    final name = exerciseName.trim();
    if (name.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final snapshot = await load();
    final records = Map<String, ExercisePreferenceRecord>.from(snapshot.records);
    final key = normaliseName(name);
    final existing = records[key] ??
        ExercisePreferenceRecord(
          exerciseName: name,
          score: 0,
          dislikeCount: 0,
          rejectedSuggestionCount: 0,
          selectedAlternativeCount: 0,
        );

    records[key] = existing.copyWith(
      score: (existing.score + scoreDelta).clamp(-100, 100).toInt(),
      dislikeCount: existing.dislikeCount + dislikeDelta,
      rejectedSuggestionCount:
          existing.rejectedSuggestionCount + rejectedDelta,
      selectedAlternativeCount:
          existing.selectedAlternativeCount + selectedDelta,
      updatedAt: DateTime.now(),
    );
    await _write(prefs, records);
  }

  Future<void> _write(
    SharedPreferences prefs,
    Map<String, ExercisePreferenceRecord> records,
  ) async {
    final json = <String, dynamic>{
      for (final entry in records.entries) entry.key: entry.value.toJson(),
    };
    await prefs.setString(_storageKey, jsonEncode(json));
  }

  static String normaliseName(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
