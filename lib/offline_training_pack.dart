import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'evidence_rule_engine.dart';
import 'exercise_repository.dart';
import 'programme_library_engine.dart';
import 'programme_store.dart';

class OfflineTrainingPackStatus {
  final DateTime preparedAt;
  final int exercises;
  final int programmeSessions;
  final int approvedEvidenceRules;
  final int curatedTemplates;

  const OfflineTrainingPackStatus({
    required this.preparedAt,
    required this.exercises,
    required this.programmeSessions,
    required this.approvedEvidenceRules,
    required this.curatedTemplates,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'prepared_at': preparedAt.toIso8601String(),
        'exercises': exercises,
        'programme_sessions': programmeSessions,
        'approved_evidence_rules': approvedEvidenceRules,
        'curated_templates': curatedTemplates,
      };

  factory OfflineTrainingPackStatus.fromJson(Map<String, dynamic> json) =>
      OfflineTrainingPackStatus(
        preparedAt: DateTime.tryParse(json['prepared_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        exercises: (json['exercises'] as num?)?.toInt() ?? 0,
        programmeSessions: (json['programme_sessions'] as num?)?.toInt() ?? 0,
        approvedEvidenceRules:
            (json['approved_evidence_rules'] as num?)?.toInt() ?? 0,
        curatedTemplates: (json['curated_templates'] as num?)?.toInt() ?? 0,
      );
}

class OfflineTrainingPack {
  final SupabaseClient client;
  final String userScope;

  const OfflineTrainingPack({required this.client, required this.userScope});

  static const _manifestPrefix = 'leanit_offline_pack_manifest_v1';
  static const _exercisePrefix = 'leanit_offline_pack_exercises_v1';
  static const _programmePrefix = 'leanit_offline_pack_programme_v1';

  String _key(String prefix) {
    final safe = userScope.trim().isEmpty
        ? 'guest'
        : userScope.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '${prefix}_$safe';
  }

  Future<OfflineTrainingPackStatus> prepare() async {
    final exercisesFuture = ExerciseRepository(client).fetchAll();
    final programmeFuture = ProgrammeStore(client).loadCurrent();
    final exercises = await exercisesFuture;
    final programme = await programmeFuture;
    final approvedRules = EvidenceRuleRegistry.rules.where((rule) => rule.canDriveAutomation).length;
    final approvedTemplates = ProgrammeLibraryEngine.templates.where((item) => item.approved).length;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _key(_exercisePrefix),
      jsonEncode(exercises.map((item) => item.toCacheMap()).toList(growable: false)),
    );
    if (programme != null) {
      await prefs.setString(
        _key(_programmePrefix),
        jsonEncode(<String, dynamic>{
          'goal': programme.programme.goal,
          'structure': programme.programme.structure,
          'explanation': programme.programme.explanation,
          'current_week': programme.currentWeek,
          'current_session_index': programme.currentSessionIndex,
          'sessions': programme.programme.sessions.map((session) => <String, dynamic>{
                'day': session.day,
                'title': session.title,
                'location': session.location,
                'duration': session.duration,
                'focus': session.focus,
                'intensity': session.intensity,
                'personalisation_note': session.personalisationNote,
              }).toList(growable: false),
        }),
      );
    }

    final status = OfflineTrainingPackStatus(
      preparedAt: DateTime.now(),
      exercises: exercises.length,
      programmeSessions: programme?.programme.sessions.length ?? 0,
      approvedEvidenceRules: approvedRules,
      curatedTemplates: approvedTemplates,
    );
    await prefs.setString(_key(_manifestPrefix), jsonEncode(status.toJson()));
    return status;
  }

  Future<OfflineTrainingPackStatus?> status() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(_manifestPrefix));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return OfflineTrainingPackStatus.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {}
    return null;
  }

  Future<List<OnlineExercise>> cachedExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(_exercisePrefix));
    if (raw == null || raw.isEmpty) return const <OnlineExercise>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <OnlineExercise>[];
      return decoded
          .whereType<Map>()
          .map((item) => OnlineExercise.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } catch (_) {
      return const <OnlineExercise>[];
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(_manifestPrefix));
    await prefs.remove(_key(_exercisePrefix));
    await prefs.remove(_key(_programmePrefix));
  }
}
