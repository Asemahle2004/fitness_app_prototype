import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SetEffortRecord {
  final String id;
  final String workoutTitle;
  final String exerciseName;
  final int setNumber;
  final double? rpe;
  final int? rir;
  final DateTime recordedAt;

  const SetEffortRecord({
    required this.id,
    required this.workoutTitle,
    required this.exerciseName,
    required this.setNumber,
    required this.rpe,
    required this.rir,
    required this.recordedAt,
  });

  bool get hasEffort => rpe != null || rir != null;

  double get estimatedRpe {
    if (rpe != null) return rpe!.clamp(1, 10).toDouble();
    if (rir != null) {
      return (10 - rir!.clamp(0, 5).toInt()).clamp(5, 10).toDouble();
    }
    return 7.5;
  }

  int get estimatedRir {
    if (rir != null) return rir!.clamp(0, 5).toInt();
    if (rpe != null) return (10 - rpe!.round()).clamp(0, 5).toInt();
    return 2;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'workout_title': workoutTitle,
        'exercise_name': exerciseName,
        'set_number': setNumber,
        'rpe': rpe,
        'rir': rir,
        'recorded_at': recordedAt.toIso8601String(),
      };

  factory SetEffortRecord.fromJson(Map<String, dynamic> json) {
    num? number(dynamic value) {
      if (value is num) return value;
      return num.tryParse(value?.toString() ?? '');
    }

    final at = DateTime.tryParse(json['recorded_at']?.toString() ?? '') ??
        DateTime.now();
    return SetEffortRecord(
      id: json['id']?.toString() ??
          'effort_${at.microsecondsSinceEpoch}_${json['set_number'] ?? 1}',
      workoutTitle: json['workout_title']?.toString() ?? 'Workout',
      exerciseName: json['exercise_name']?.toString() ?? 'Exercise',
      setNumber: number(json['set_number'])?.toInt() ?? 1,
      rpe: number(json['rpe'])?.toDouble(),
      rir: number(json['rir'])?.toInt(),
      recordedAt: at,
    );
  }
}

class SetEffortStore {
  final String userScope;

  const SetEffortStore({required this.userScope});

  static const _prefix = 'leanit_set_effort_v1';
  static const _maxRecords = 1000;

  String get _key {
    final safe = userScope.trim().isEmpty
        ? 'guest'
        : userScope.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '${_prefix}_$safe';
  }

  Future<List<SetEffortRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    final values = <SetEffortRecord>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map) {
          values.add(
            SetEffortRecord.fromJson(Map<String, dynamic>.from(decoded)),
          );
        }
      } catch (_) {
        // One corrupt feedback item should never break training history.
      }
    }
    values.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return values;
  }

  Future<void> save(SetEffortRecord record) async {
    final current = await load();
    final next = <SetEffortRecord>[
      record,
      ...current.where((item) => item.id != record.id),
    ].take(_maxRecords).toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      next.map((item) => jsonEncode(item.toJson())).toList(growable: false),
    );
  }

  Future<SetEffortRecord> rateSet({
    String? id,
    required String workoutTitle,
    required String exerciseName,
    required int setNumber,
    double? rpe,
    int? rir,
    DateTime? recordedAt,
  }) async {
    final safeRpe = rpe == null ? null : rpe.clamp(1, 10).toDouble();
    final safeRir = rir == null ? null : rir.clamp(0, 5).toInt();
    final at = recordedAt ?? DateTime.now();
    final record = SetEffortRecord(
      id: id ?? 'effort_${at.microsecondsSinceEpoch}',
      workoutTitle: workoutTitle,
      exerciseName: exerciseName,
      setNumber: setNumber < 1 ? 1 : setNumber,
      rpe: safeRpe,
      rir: safeRir,
      recordedAt: at,
    );
    await save(record);
    return record;
  }

  Future<SetEffortRecord?> latestForExercise(String exerciseName) async {
    final key = exerciseName.trim().toLowerCase();
    for (final item in await load()) {
      if (item.exerciseName.trim().toLowerCase() == key && item.hasEffort) {
        return item;
      }
    }
    return null;
  }

  Future<void> remove(String id) async {
    final values = (await load()).where((item) => item.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      values.map((item) => jsonEncode(item.toJson())).toList(growable: false),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
