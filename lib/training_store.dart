import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.now(),
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      completedSets: json['completedSets'] as int? ?? 0,
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
    if (score >= 60) return 'Train, but keep 1–2 reps in reserve and avoid unnecessary extra volume.';
    if (score >= 40) return 'Use a lighter session, reduce sets, or choose mobility / easy cardio.';
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
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
          DateTime.now(),
      sleep: value('sleep'),
      energy: value('energy'),
      soreness: value('soreness'),
      stress: value('stress'),
    );
  }
}

class TrainingStore {
  static const _workoutsKey = 'leanit_workout_history_v1';
  static const _readinessKey = 'leanit_readiness_history_v1';

  static Future<void> saveWorkout(WorkoutRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_workoutsKey) ?? <String>[];
    final updated = [jsonEncode(record.toJson()), ...existing].take(200).toList();
    await prefs.setStringList(_workoutsKey, updated);
  }

  static Future<List<WorkoutRecord>> loadWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_workoutsKey) ?? const <String>[];
    final records = <WorkoutRecord>[];
    for (final item in raw) {
      try {
        records.add(WorkoutRecord.fromJson(
          Map<String, dynamic>.from(jsonDecode(item) as Map),
        ));
      } catch (_) {}
    }
    records.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return records;
  }

  static Future<void> saveReadiness(ReadinessRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_readinessKey) ?? <String>[];
    final updated = [jsonEncode(record.toJson()), ...existing].take(90).toList();
    await prefs.setStringList(_readinessKey, updated);
  }

  static Future<List<ReadinessRecord>> loadReadiness() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_readinessKey) ?? const <String>[];
    final records = <ReadinessRecord>[];
    for (final item in raw) {
      try {
        records.add(ReadinessRecord.fromJson(
          Map<String, dynamic>.from(jsonDecode(item) as Map),
        ));
      } catch (_) {}
    }
    records.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return records;
  }
}
