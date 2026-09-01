import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutRecord {
  final String title;
  final DateTime completedAt;
  final int durationSeconds;
  final int completedSets;
  final List<String> exercises;

  const WorkoutRecord({
    required this.title,
    required this.completedAt,
    required this.durationSeconds,
    required this.completedSets,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'completedAt': completedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'completedSets': completedSets,
        'exercises': exercises,
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
  static const _cloudTimeout = Duration(seconds: 4);

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
        }).timeout(_cloudTimeout);
      } catch (_) {
        // Local history remains available if cloud sync is temporarily offline.
      }
    }
  }

  static Future<List<WorkoutRecord>> loadWorkouts() async {
    final local = await _loadLocalWorkouts();
    if (local.isNotEmpty) {
      // Do not make an offline screen wait for the cloud. A best-effort refresh
      // may fill an empty cache on another online launch, but this device's
      // completed workouts are already authoritative locally.
      unawaited(_refreshWorkoutCloud().catchError((_) => <WorkoutRecord>[]));
      return local;
    }

    final cloud = await _refreshWorkoutCloud();
    if (cloud.isNotEmpty) {
      await _cacheWorkouts(cloud);
      return cloud;
    }
    return local;
  }

  static Future<void> saveReadiness(ReadinessRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_readinessKey) ?? <String>[];
    await prefs.setStringList(
      _readinessKey,
      [jsonEncode(record.toJson()), ...existing].take(90).toList(),
    );

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
        }).timeout(_cloudTimeout);
      } catch (_) {}
    }
  }

  static Future<List<ReadinessRecord>> loadReadiness() async {
    final local = await _loadLocalReadiness();
    if (local.isNotEmpty) {
      unawaited(_refreshReadinessCloud().catchError((_) => <ReadinessRecord>[]));
      return local;
    }

    final cloud = await _refreshReadinessCloud();
    if (cloud.isNotEmpty) {
      await _cacheReadiness(cloud);
      return cloud;
    }
    return local;
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

  static Future<List<WorkoutRecord>> _refreshWorkoutCloud() async {
    final client = _clientOrNull;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return const <WorkoutRecord>[];
    try {
      final rows = await client
          .from('workout_logs')
          .select(
            'title,completed_at,duration_seconds,completed_sets,exercises',
          )
          .eq('user_id', user.id)
          .order('completed_at', ascending: false)
          .limit(200)
          .timeout(_cloudTimeout);
      return (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(WorkoutRecord.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const <WorkoutRecord>[];
    }
  }

  static Future<List<ReadinessRecord>> _refreshReadinessCloud() async {
    final client = _clientOrNull;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return const <ReadinessRecord>[];
    try {
      final rows = await client
          .from('readiness_logs')
          .select('recorded_at,sleep,energy,soreness,stress')
          .eq('user_id', user.id)
          .order('recorded_at', ascending: false)
          .limit(90)
          .timeout(_cloudTimeout);
      return (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(ReadinessRecord.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const <ReadinessRecord>[];
    }
  }

  static Future<void> _cacheWorkouts(List<WorkoutRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _workoutsKey,
      records
          .take(200)
          .map((record) => jsonEncode(record.toJson()))
          .toList(growable: false),
    );
  }

  static Future<void> _cacheReadiness(List<ReadinessRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _readinessKey,
      records
          .take(90)
          .map((record) => jsonEncode(record.toJson()))
          .toList(growable: false),
    );
  }
}
