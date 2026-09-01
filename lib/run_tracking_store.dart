import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RunRecord {
  final String id;
  final DateTime startedAt;
  final int durationSeconds;
  final double distanceMeters;
  final String source;
  final String? notes;
  final String? guidedPlanId;
  final int? guidedPlannedSeconds;
  final bool? guidedCompleted;
  final String? perceivedEffort;

  const RunRecord({
    required this.id,
    required this.startedAt,
    required this.durationSeconds,
    required this.distanceMeters,
    this.source = 'manual',
    this.notes,
    this.guidedPlanId,
    this.guidedPlannedSeconds,
    this.guidedCompleted,
    this.perceivedEffort,
  });

  double get distanceKm => distanceMeters / 1000;

  double? get averagePaceSecondsPerKm {
    if (distanceMeters <= 0 || durationSeconds <= 0) return null;
    return durationSeconds / distanceKm;
  }

  bool get isGuided => guidedPlanId != null || source == 'gps_guided';

  double? get guidedCompletionRatio {
    if (guidedCompleted == true) return 1;
    final planned = guidedPlannedSeconds;
    if (planned == null || planned <= 0) return null;
    return (durationSeconds / planned).clamp(0, 1).toDouble();
  }

  RunRecord copyWith({
    String? id,
    DateTime? startedAt,
    int? durationSeconds,
    double? distanceMeters,
    String? source,
    String? notes,
    String? guidedPlanId,
    int? guidedPlannedSeconds,
    bool? guidedCompleted,
    String? perceivedEffort,
  }) {
    return RunRecord(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      guidedPlanId: guidedPlanId ?? this.guidedPlanId,
      guidedPlannedSeconds: guidedPlannedSeconds ?? this.guidedPlannedSeconds,
      guidedCompleted: guidedCompleted ?? this.guidedCompleted,
      perceivedEffort: perceivedEffort ?? this.perceivedEffort,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'started_at': startedAt.toIso8601String(),
        'duration_seconds': durationSeconds,
        'distance_meters': distanceMeters,
        'source': source,
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
        if (guidedPlanId != null && guidedPlanId!.isNotEmpty)
          'guided_plan_id': guidedPlanId,
        if (guidedPlannedSeconds != null)
          'guided_planned_seconds': guidedPlannedSeconds,
        if (guidedCompleted != null) 'guided_completed': guidedCompleted,
        if (perceivedEffort != null && perceivedEffort!.isNotEmpty)
          'perceived_effort': perceivedEffort,
      };

  factory RunRecord.fromJson(Map<String, dynamic> json) {
    return RunRecord(
      id: json['id'] as String? ??
          'run_${DateTime.now().microsecondsSinceEpoch}',
      startedAt: DateTime.tryParse(json['started_at'] as String? ?? '') ??
          DateTime.now(),
      durationSeconds: (json['duration_seconds'] as num?)?.round() ?? 0,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0,
      source: json['source'] as String? ?? 'manual',
      notes: json['notes'] as String?,
      guidedPlanId: json['guided_plan_id'] as String?,
      guidedPlannedSeconds:
          (json['guided_planned_seconds'] as num?)?.round(),
      guidedCompleted: json['guided_completed'] as bool?,
      perceivedEffort: json['perceived_effort'] as String?,
    );
  }
}

class RunTrackingStore {
  static const _keyPrefix = 'leanit_run_history_v1';
  static const maxRecords = 500;

  static String _scope() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) return user.id;
    } catch (_) {}
    return 'local';
  }

  static String get _key => '${_keyPrefix}_${_scope()}';

  static Future<List<RunRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    final records = <RunRecord>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map) {
          records.add(RunRecord.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (_) {}
    }
    records.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return records;
  }

  static Future<void> save(RunRecord record) async {
    final records = await load();
    final withoutSame = records.where((item) => item.id != record.id).toList();
    withoutSame.add(record);
    withoutSame.sort((a, b) => b.startedAt.compareTo(a.startedAt));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      withoutSame
          .take(maxRecords)
          .map((item) => jsonEncode(item.toJson()))
          .toList(growable: false),
    );
  }

  static Future<void> delete(String id) async {
    final records = await load();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      records
          .where((item) => item.id != id)
          .map((item) => jsonEncode(item.toJson()))
          .toList(growable: false),
    );
  }
}
