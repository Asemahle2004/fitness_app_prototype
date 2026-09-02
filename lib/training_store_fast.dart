import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_health.dart';
import 'sync_queue.dart';

class WorkoutRecord {
  final String title;
  final DateTime completedAt;
  final int durationSeconds;
  final int completedSets;
  final List<String> exercises;
  final String? perceivedEffort;
  final int? sessionRpe;
  final String? feedbackNote;

  const WorkoutRecord({
    required this.title,
    required this.completedAt,
    required this.durationSeconds,
    required this.completedSets,
    required this.exercises,
    this.perceivedEffort,
    this.sessionRpe,
    this.feedbackNote,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'completedAt': completedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'completedSets': completedSets,
        'exercises': exercises,
        if (perceivedEffort != null) 'perceivedEffort': perceivedEffort,
        if (sessionRpe != null) 'sessionRpe': sessionRpe,
        if (feedbackNote != null && feedbackNote!.isNotEmpty)
          'feedbackNote': feedbackNote,
      };

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) {
    final rawRpe = json['sessionRpe'] ?? json['session_rpe'];
    final parsedRpe = rawRpe is num ? rawRpe.toInt() : int.tryParse('$rawRpe');
    return WorkoutRecord(
      title: json['title'] as String? ?? 'Workout',
      completedAt: DateTime.tryParse(
            (json['completedAt'] ?? json['completed_at'] ?? '') as String,
          ) ??
          DateTime.now(),
      durationSeconds:
          (json['durationSeconds'] ?? json['duration_seconds'] ?? 0) as int,
      completedSets:
          (json['completedSets'] ?? json['completed_sets'] ?? 0) as int,
      exercises: (json['exercises'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      perceivedEffort:
          (json['perceivedEffort'] ?? json['perceived_effort']) as String?,
      sessionRpe:
          parsedRpe == null ? null : parsedRpe.clamp(1, 10).toInt(),
      feedbackNote:
          (json['feedbackNote'] ?? json['feedback_note'])?.toString(),
    );
  }

  WorkoutRecord copyWith({
    String? perceivedEffort,
    int? sessionRpe,
    String? feedbackNote,
  }) {
    return WorkoutRecord(
      title: title,
      completedAt: completedAt,
      durationSeconds: durationSeconds,
      completedSets: completedSets,
      exercises: exercises,
      perceivedEffort: perceivedEffort ?? this.perceivedEffort,
      sessionRpe: sessionRpe ?? this.sessionRpe,
      feedbackNote: feedbackNote ?? this.feedbackNote,
    );
  }
}

class ReadinessRecord {
  final DateTime recordedAt;
  final double sleep;
  final double energy;
  final double soreness;
  final double stress;

  const ReadinessRecord({
    required this.recordedAt,
    required this.sleep,
    required this.energy,
    required this.soreness,
    required this.stress,
  });

  double get score {
    final raw = (sleep + energy + (6 - soreness) + (6 - stress)) / 4;
    return ((raw / 5) * 100).clamp(0, 100);
  }

  String get recommendation {
    if (score >= 80) return 'Ready for your planned session.';
    if (score >= 60) {
      return 'Train, but keep 1–2 reps in reserve and avoid unnecessary extra volume.';
    }
    if (score >= 40) {
      return 'Use a lighter session, reduce sets, or choose mobility / easy cardio.';
    }
    return 'Recovery is low. Consider rest or a very easy recovery session.';
  }

  Map<String, dynamic> toJson() => {
        'recordedAt': recordedAt.toIso8601String(),
        'sleep': sleep,
        'energy': energy,
        'soreness': soreness,
        'stress': stress,
      };

  factory ReadinessRecord.fromJson(Map<String, dynamic> json) {
    double value(String key) => (json[key] as num?)?.toDouble() ?? 3;
    return ReadinessRecord(
      recordedAt: DateTime.tryParse(
            (json['recordedAt'] ?? json['recorded_at'] ?? '') as String,
          ) ??
          DateTime.now(),
      sleep: value('sleep'),
      energy: value('energy'),
      soreness: value('soreness'),
      stress: value('stress'),
    );
  }
}

class TrainingStore {
  static const _workoutsKey = 'leaneat_workout_history_v2';
  static const _readinessKey = 'leaneat_readiness_history_v2';
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);
  static Future<void>? _workoutRefresh;
  static Future<void>? _readinessRefresh;

  static SupabaseClient? get _clientOrNull {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveWorkout(WorkoutRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_workoutsKey) ?? <String>[];
    await prefs.setStringList(
      _workoutsKey,
      [jsonEncode(record.toJson()), ...existing].take(200).toList(),
    );
    revision.value += 1;
    unawaited(_syncWorkout(record));
  }

  static Future<void> _syncWorkout(WorkoutRecord record) async {
    final client = _clientOrNull;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;
    final payload = <String, dynamic>{
      'user_id': user.id,
      'title': record.title,
      'completed_at': record.completedAt.toIso8601String(),
      'duration_seconds': record.durationSeconds,
      'completed_sets': record.completedSets,
      'exercises': record.exercises,
    };
    try {
      await client
          .from('workout_logs')
          .insert(payload)
          .timeout(const Duration(seconds: 4));
    } catch (error) {
      await SyncQueueStore(userScope: user.id).enqueue(
        table: 'workout_logs',
        action: 'insert_if_absent',
        data: payload,
        matchColumn: 'completed_at',
        matchValue: payload['completed_at'],
      );
      await AppErrorStore.record('Workout cloud sync', error);
    }
  }

  static Future<void> updateWorkoutEffort({
    required DateTime completedAt,
    required String effort,
  }) {
    return updateWorkoutFeedback(completedAt: completedAt, effort: effort);
  }

  static Future<void> updateWorkoutFeedback({
    required DateTime completedAt,
    String? effort,
    int? sessionRpe,
    String? note,
  }) async {
    if (effort != null &&
        !const {'easy', 'about_right', 'hard'}.contains(effort)) {
      return;
    }
    if (sessionRpe != null && (sessionRpe < 1 || sessionRpe > 10)) return;

    final records = await _loadLocalWorkouts();
    var changed = false;
    final updated = records.map((record) {
      if (!_sameWorkoutTime(record.completedAt, completedAt)) return record;
      changed = true;
      return record.copyWith(
        perceivedEffort: effort,
        sessionRpe: sessionRpe,
        feedbackNote: note?.trim(),
      );
    }).toList(growable: false);
    if (!changed) return;

    await _writeLocalWorkouts(updated);
    revision.value += 1;
  }

  /// Returns device history immediately. Cloud hydration runs in the background
  /// and never holds Home/Progress hostage to network quality.
  static Future<List<WorkoutRecord>> loadWorkouts() async {
    final local = await _loadLocalWorkouts();
    _scheduleWorkoutRefresh();
    return local;
  }

  static void _scheduleWorkoutRefresh() {
    if (_workoutRefresh != null) return;
    final task = _refreshWorkoutsFromCloud();
    _workoutRefresh = task;
    unawaited(task.whenComplete(() => _workoutRefresh = null));
  }

  static Future<void> _refreshWorkoutsFromCloud() async {
    final client = _clientOrNull;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;
    try {
      final rows = await client
          .from('workout_logs')
          .select('title,completed_at,duration_seconds,completed_sets,exercises')
          .eq('user_id', user.id)
          .order('completed_at', ascending: false)
          .limit(200)
          .timeout(const Duration(seconds: 4));
      final local = await _loadLocalWorkouts();
      final merged = <String, WorkoutRecord>{
        for (final record in local) _workoutSignature(record): record,
      };
      for (final row in (rows as List).whereType<Map<String, dynamic>>()) {
        final record = WorkoutRecord.fromJson(row);
        merged.putIfAbsent(_workoutSignature(record), () => record);
      }
      final records = merged.values.toList(growable: false)
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
      await _writeLocalWorkouts(records.take(200).toList(growable: false));
      revision.value += 1;
    } catch (error) {
      await AppErrorStore.record('Workout history refresh', error);
    }
  }

  static Future<List<WorkoutRecord>> _loadLocalWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_workoutsKey) ?? const <String>[];
    final records = <WorkoutRecord>[];
    for (final item in raw) {
      try {
        records.add(
          WorkoutRecord.fromJson(
            Map<String, dynamic>.from(jsonDecode(item) as Map),
          ),
        );
      } catch (_) {}
    }
    records.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return records;
  }

  static Future<void> _writeLocalWorkouts(List<WorkoutRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _workoutsKey,
      records.map((record) => jsonEncode(record.toJson())).toList(growable: false),
    );
  }

  static String _workoutSignature(WorkoutRecord record) => [
        record.title,
        record.completedAt.toUtc().toIso8601String(),
        record.durationSeconds,
        record.completedSets,
      ].join('|');

  static bool _sameWorkoutTime(DateTime a, DateTime b) =>
      (a.toUtc().difference(b.toUtc()).inMilliseconds).abs() < 5;

  static Future<void> saveReadiness(ReadinessRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_readinessKey) ?? <String>[];
    await prefs.setStringList(
      _readinessKey,
      [jsonEncode(record.toJson()), ...existing].take(90).toList(),
    );
    revision.value += 1;
    unawaited(_syncReadiness(record));
  }

  static Future<void> _syncReadiness(ReadinessRecord record) async {
    final client = _clientOrNull;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;
    final payload = <String, dynamic>{
      'user_id': user.id,
      'recorded_at': record.recordedAt.toIso8601String(),
      'sleep': record.sleep,
      'energy': record.energy,
      'soreness': record.soreness,
      'stress': record.stress,
      'readiness_score': record.score,
    };
    try {
      await client
          .from('readiness_logs')
          .insert(payload)
          .timeout(const Duration(seconds: 4));
    } catch (error) {
      await SyncQueueStore(userScope: user.id).enqueue(
        table: 'readiness_logs',
        action: 'insert_if_absent',
        data: payload,
        matchColumn: 'recorded_at',
        matchValue: payload['recorded_at'],
      );
      await AppErrorStore.record('Readiness cloud sync', error);
    }
  }

  static Future<List<ReadinessRecord>> loadReadiness() async {
    final local = await _loadLocalReadiness();
    _scheduleReadinessRefresh();
    return local;
  }

  static void _scheduleReadinessRefresh() {
    if (_readinessRefresh != null) return;
    final task = _refreshReadinessFromCloud();
    _readinessRefresh = task;
    unawaited(task.whenComplete(() => _readinessRefresh = null));
  }

  static Future<void> _refreshReadinessFromCloud() async {
    final client = _clientOrNull;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;
    try {
      final rows = await client
          .from('readiness_logs')
          .select('recorded_at,sleep,energy,soreness,stress')
          .eq('user_id', user.id)
          .order('recorded_at', ascending: false)
          .limit(90)
          .timeout(const Duration(seconds: 4));
      final local = await _loadLocalReadiness();
      final merged = <String, ReadinessRecord>{
        for (final record in local)
          record.recordedAt.toUtc().toIso8601String(): record,
      };
      for (final row in (rows as List).whereType<Map<String, dynamic>>()) {
        final record = ReadinessRecord.fromJson(row);
        merged.putIfAbsent(
          record.recordedAt.toUtc().toIso8601String(),
          () => record,
        );
      }
      final records = merged.values.toList(growable: false)
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      await _writeLocalReadiness(records.take(90).toList(growable: false));
      revision.value += 1;
    } catch (error) {
      await AppErrorStore.record('Readiness history refresh', error);
    }
  }

  static Future<List<ReadinessRecord>> _loadLocalReadiness() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_readinessKey) ?? const <String>[];
    final records = <ReadinessRecord>[];
    for (final item in raw) {
      try {
        records.add(
          ReadinessRecord.fromJson(
            Map<String, dynamic>.from(jsonDecode(item) as Map),
          ),
        );
      } catch (_) {}
    }
    records.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return records;
  }

  static Future<void> _writeLocalReadiness(List<ReadinessRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _readinessKey,
      records.map((record) => jsonEncode(record.toJson())).toList(growable: false),
    );
  }
}
