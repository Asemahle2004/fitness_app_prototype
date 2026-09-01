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
    final source = json['source'] as String? ?? 'manual';
    final notes = json['notes'] as String?;
    final storedPlanId = json['guided_plan_id'] as String?;
    final inferredPlanId = source == 'gps_guided'
        ? _legacyGuidedPlanId(notes)
        : null;
    final planId = storedPlanId ?? inferredPlanId;
    final storedPlanned = (json['guided_planned_seconds'] as num?)?.round();
    final planned = storedPlanned ?? _legacyPlannedSeconds(planId);
    final storedCompleted = json['guided_completed'] as bool?;
    final completed = storedCompleted ??
        (source == 'gps_guided' ? _legacyCompletion(notes) : null);

    return RunRecord(
      id: json['id'] as String? ??
          'run_${DateTime.now().microsecondsSinceEpoch}',
      startedAt: DateTime.tryParse(json['started_at'] as String? ?? '') ??
          DateTime.now(),
      durationSeconds: (json['duration_seconds'] as num?)?.round() ?? 0,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0,
      source: source,
      notes: notes,
      guidedPlanId: planId,
      guidedPlannedSeconds: planned,
      guidedCompleted: completed,
      perceivedEffort: json['perceived_effort'] as String?,
    );
  }

  static String? _legacyGuidedPlanId(String? notes) {
    final lower = notes?.toLowerCase() ?? '';
    if (lower.contains('run-walk foundation')) return 'run_walk_foundation';
    if (lower.contains('steady intervals')) return 'steady_intervals';
    if (lower.contains('speed intervals')) return 'speed_intervals';
    return null;
  }

  static int? _legacyPlannedSeconds(String? planId) {
    switch (planId) {
      case 'run_walk_foundation':
        return 1800;
      case 'steady_intervals':
        return 1680;
      case 'speed_intervals':
        return 1860;
      default:
        return null;
    }
  }

  static bool? _legacyCompletion(String? notes) {
    final lower = notes?.toLowerCase() ?? '';
    if (lower.contains('ended early')) return false;
    if (lower.contains('• completed') || lower.endsWith('completed')) return true;
    return null;
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
