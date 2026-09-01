import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_health.dart';
import 'sync_queue.dart';
import 'unit_display.dart';

class ExerciseSetPerformance {
  final String workoutTitle;
  final String exerciseName;
  final int setNumber;
  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final String setType;
  final int? dropNumber;
  final DateTime performedAt;

  const ExerciseSetPerformance({
    this.workoutTitle = 'Workout',
    required this.exerciseName,
    required this.setNumber,
    required this.reps,
    required this.weightKg,
    required this.durationSeconds,
    this.setType = 'normal',
    this.dropNumber,
    required this.performedAt,
  });

  factory ExerciseSetPerformance.fromMap(Map<String, dynamic> map) {
    num? number(dynamic value) {
      if (value is num) return value;
      return num.tryParse(value?.toString() ?? '');
    }

    final rawSetNumber = number(map['set_number'] ?? map['setNumber']);
    final rawWeight = number(map['weight_kg'] ?? map['weightKg']);
    final rawDuration = number(map['duration_seconds'] ?? map['durationSeconds']);

    return ExerciseSetPerformance(
      workoutTitle:
          (map['workout_title'] ?? map['workoutTitle'])?.toString() ?? 'Workout',
      exerciseName:
          (map['exercise_name'] ?? map['exerciseName'])?.toString() ?? 'Exercise',
      setNumber: rawSetNumber?.toInt() ?? 1,
      reps: number(map['reps'])?.toInt(),
      weightKg: rawWeight?.toDouble(),
      durationSeconds: rawDuration?.toInt(),
      setType: (map['set_type'] ?? map['setType'])?.toString() ?? 'normal',
      dropNumber: number(map['drop_number'] ?? map['dropNumber'])?.toInt(),
      performedAt: DateTime.tryParse(
            (map['performed_at'] ?? map['performedAt'])?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'workoutTitle': workoutTitle,
        'exerciseName': exerciseName,
        'setNumber': setNumber,
        'reps': reps,
        'weightKg': weightKg,
        'durationSeconds': durationSeconds,
        'setType': setType,
        'dropNumber': dropNumber,
        'performedAt': performedAt.toIso8601String(),
      };

  bool get isDropSet => setType == 'drop';

  String get setLabel =>
      isDropSet ? 'Drop ${dropNumber ?? 1}' : 'Set $setNumber';

  String get summary {
    if (durationSeconds != null) {
      final minutes = durationSeconds! ~/ 60;
      final seconds = durationSeconds! % 60;
      return minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
    }
    if (weightKg != null && reps != null) {
      return '${UnitDisplay.formatWeight(weightKg!)} × $reps reps';
    }
    if (reps != null) return '$reps reps';
    return 'Completed set';
  }

  double get volumeKg {
    if (weightKg == null || reps == null) return 0;
    return weightKg! * reps!;
  }

  String? get nextTargetSuggestion {
    if (isDropSet) return null;

    if (durationSeconds != null) {
      final increase = durationSeconds! < 60 ? 5 : 10;
      return 'Try ${durationSeconds! + increase}s next time if form stays controlled.';
    }

    if (reps != null && weightKg != null) {
      if (reps! >= 12) {
        final nextWeight = weightKg! + 2.5;
        final resetReps = (reps! - 2).clamp(8, 10);
        return 'Try ${UnitDisplay.formatWeight(nextWeight)} × $resetReps reps next time if today felt controlled.';
      }
      return 'Try ${UnitDisplay.formatWeight(weightKg!)} × ${reps! + 1} reps next time if form stays good.';
    }

    if (reps != null) {
      return 'Try ${reps! + 1} reps next time if today felt controlled.';
    }

    return null;
  }
}

class ExercisePerformanceStore {
  static const _localHistoryKey = 'leanit_exercise_set_history_v1';
  static const _maxLocalRecords = 2000;

  final SupabaseClient client;

  const ExercisePerformanceStore(this.client);

  Future<void> saveSet({
    required String workoutTitle,
    required String exerciseName,
    required int setNumber,
    int? reps,
    double? weightKg,
    int? durationSeconds,
    bool isDropSet = false,
    int? dropNumber,
  }) async {
    final record = ExerciseSetPerformance(
      workoutTitle: workoutTitle,
      exerciseName: exerciseName,
      setNumber: setNumber,
      reps: reps,
      weightKg: weightKg,
      durationSeconds: durationSeconds,
      setType: isDropSet ? 'drop' : 'normal',
      dropNumber: isDropSet ? dropNumber : null,
      performedAt: DateTime.now(),
    );

    await _saveLocal(record);
    if (record.isDropSet) return;

    final user = client.auth.currentUser;
    if (user == null) return;
    final payload = <String, dynamic>{
      'user_id': user.id,
      'workout_title': record.workoutTitle,
      'exercise_name': record.exerciseName,
      'set_number': record.setNumber,
      'reps': record.reps,
      'weight_kg': record.weightKg,
      'duration_seconds': record.durationSeconds,
      'performed_at': record.performedAt.toIso8601String(),
    };

    try {
      await client.from('exercise_set_logs').insert(payload);
    } catch (error) {
      await SyncQueueStore(userScope: user.id).enqueue(
        table: 'exercise_set_logs',
        action: 'insert_if_absent',
        data: payload,
        matchColumn: 'performed_at',
        matchValue: payload['performed_at'],
      );
      await AppErrorStore.record('Exercise set cloud sync', error);
    }
  }

  Future<ExerciseSetPerformance?> latestForExercise(String exerciseName) async {
    final local = await _latestLocalForExercise(exerciseName);
    final user = client.auth.currentUser;
    if (user == null) return local;

    ExerciseSetPerformance? cloud;
    try {
      final row = await client
          .from('exercise_set_logs')
          .select(
            'workout_title,exercise_name,set_number,reps,weight_kg,duration_seconds,performed_at',
          )
          .eq('user_id', user.id)
          .eq('exercise_name', exerciseName)
          .order('performed_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row != null) {
        cloud = ExerciseSetPerformance.fromMap(Map<String, dynamic>.from(row));
      }
    } catch (error) {
      await AppErrorStore.record('Exercise set history load', error);
    }

    if (local == null) return cloud;
    if (cloud == null) return local;
    return local.performedAt.isAfter(cloud.performedAt) ? local : cloud;
  }

  Future<List<ExerciseSetPerformance>> loadRecent({int limit = 100}) async {
    final merged = <String, ExerciseSetPerformance>{};

    for (final record in await _loadLocal()) {
      merged[_signature(record)] = record;
    }

    final user = client.auth.currentUser;
    if (user != null) {
      try {
        final rows = await client
            .from('exercise_set_logs')
            .select(
              'workout_title,exercise_name,set_number,reps,weight_kg,duration_seconds,performed_at',
            )
            .eq('user_id', user.id)
            .order('performed_at', ascending: false)
            .limit(limit.clamp(1, 500));

        for (final row in (rows as List).whereType<Map<String, dynamic>>()) {
          final record = ExerciseSetPerformance.fromMap(row);
          merged[_signature(record)] = record;
        }
      } catch (error) {
        await AppErrorStore.record('Exercise set history load', error);
      }
    }

    final records = merged.values.toList(growable: false)
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    return records.take(limit).toList(growable: false);
  }

  Future<List<ExerciseSetPerformance>> loadAll() {
    return loadRecent(limit: _maxLocalRecords);
  }

  Future<List<ExerciseSetPerformance>> loadForExercise(
    String exerciseName, {
    int limit = 50,
  }) async {
    final lower = exerciseName.trim().toLowerCase();
    final all = await loadAll();
    return all
        .where((record) => record.exerciseName.toLowerCase() == lower)
        .take(limit)
        .toList(growable: false);
  }

  Future<void> _saveLocal(ExerciseSetPerformance record) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_localHistoryKey) ?? <String>[];
    await prefs.setStringList(
      _localHistoryKey,
      [jsonEncode(record.toJson()), ...existing]
          .take(_maxLocalRecords)
          .toList(growable: false),
    );
  }

  Future<List<ExerciseSetPerformance>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_localHistoryKey) ?? const <String>[];
    final records = <ExerciseSetPerformance>[];

    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map) {
          records.add(
            ExerciseSetPerformance.fromMap(Map<String, dynamic>.from(decoded)),
          );
        }
      } catch (_) {}
    }

    records.sort((a, b) => b.performedAt.compareTo(a.performedAt));
    return records;
  }

  Future<ExerciseSetPerformance?> _latestLocalForExercise(
    String exerciseName,
  ) async {
    final lower = exerciseName.trim().toLowerCase();
    for (final record in await _loadLocal()) {
      if (record.isDropSet) continue;
      if (record.exerciseName.toLowerCase() == lower) return record;
    }
    return null;
  }

  String _signature(ExerciseSetPerformance record) {
    return [
      record.workoutTitle,
      record.exerciseName,
      record.setNumber,
      record.reps,
      record.weightKg,
      record.durationSeconds,
      record.setType,
      record.dropNumber,
      record.performedAt.toUtc().toIso8601String(),
    ].join('|');
  }
}
