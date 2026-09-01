import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutRecord {
  final String title;
  final DateTime completedAt;
  final int durationSeconds;
  final int completedSets;
  final List<String> exercises;
  final String? perceivedEffort;

  const WorkoutRecord({
    required this.title,
    required this.completedAt,
    required this.durationSeconds,
    required this.completedSets,
    required this.exercises,
    this.perceivedEffort,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'completedAt': completedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'completedSets': completedSets,
        'exercises': exercises,
        if (perceivedEffort != null) 'perceivedEffort': perceivedEffort,
      };

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) {
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
    );
  }

  WorkoutRecord copyWith({String? perceivedEffort}) {
    return WorkoutRecord(
      title: title,
      completedAt: completedAt,
      durationSeconds: durationSeconds,
      completedSets: completedSets,
      exercises: exercises,
      perceivedEffort: perceivedEffort ?? this.perceivedEffort,
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

    final client = _clientOrNull;
    final user = client?.auth.currentUser;
    if (client != null && user != null) {
      try {
        await client.from('workout_logs').insert({
          'user_id': user.id,
          'title': record.title,
          'completed_at': record.completedAt.toIso8601String(),
          'duration_seconds': record.durationSeconds,
          'completed_sets': record.completedSets,
          'exercises': record.exercises,
        });
      } catch (_) {
        // Perceived effort stays local-first until the backend table gains an
        // explicit column. Other workout data remains safe locally as well.
      }
    }
  }

  static Future<void> updateWorkoutEffort({
    required DateTime completedAt,
    required String effort,
  }) async {
    if (!const {'easy', 'about_right', 'hard'}.contains(effort)) return;
    final records = await _loadLocalWorkouts();
    final updated = records
        .map(
          (record) => _sameWorkoutTime(record.completedAt, completedAt)
              ? record.copyWith(perceivedEffort: effort)
              : record,
        )
        .toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _workoutsKey,
      updated.map((record) => jsonEncode(record.toJson())).toList(growable: false),
    );
    revision.value += 1;
  }

  static Future<List<WorkoutRecord>> loadWorkouts() async {
    final local = await _loadLocalWorkouts();
    final merged = <String, WorkoutRecord>{};

    for (final record in local) {
      merged[_workoutSignature(record)] = record;
    }

    final client = _clientOrNull;
    final user = client?.auth.currentUser;
    if (client != null && user != null) {
      try {
        final rows = await client
            .from('workout_logs')
            .select('title,completed_at,duration_seconds,completed_sets,exercises')
            .eq('user_id', user.id)
            .order('completed_at', ascending: false)
            .limit(200);
        final cloud = (rows as List)
            .whereType<Map<String, dynamic>>()
            .map(WorkoutRecord.fromJson);
        for (final record in cloud) {
          final signature = _workoutSignature(record);
          final existing = merged[signature];
          if (existing == null) {
            merged[signature] = record;
          }
        }
      } catch (_) {}
    }

    final records = merged.values.toList(growable: false)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return records.take(200).toList(growable: false);
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

    final client = _clientOrNull;
    final user = client?.auth.currentUser;
    if (client != null && user != null) {
      try {
        await client.from('readiness_logs').insert({
          'user_id': user.id,
          'recorded_at': record.recordedAt.toIso8601String(),
          'sleep': record.sleep,
          'energy': record.energy,
          'soreness': record.soreness,
          'stress': record.stress,
          'readiness_score': record.score,
        });
      } catch (_) {}
    }
  }

  static Future<List<ReadinessRecord>> loadReadiness() async {
    final client = _clientOrNull;
    final user = client?.auth.currentUser;
    if (client != null && user != null) {
      try {
        final rows = await client
            .from('readiness_logs')
            .select('recorded_at,sleep,energy,soreness,stress')
            .eq('user_id', user.id)
            .order('recorded_at', ascending: false)
            .limit(90);
        final cloud = (rows as List)
            .whereType<Map<String, dynamic>>()
            .map(ReadinessRecord.fromJson)
            .toList(growable: false);
        if (cloud.isNotEmpty) return cloud;
      } catch (_) {}
    }

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
}
