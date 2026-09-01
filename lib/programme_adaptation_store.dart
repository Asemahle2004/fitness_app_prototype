import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ProgrammeSessionEventType { completed, skipped }

class ProgrammeSessionEvent {
  final String id;
  final int weekNumber;
  final int sessionIndex;
  final String sessionTitle;
  final ProgrammeSessionEventType type;
  final DateTime recordedAt;

  const ProgrammeSessionEvent({
    required this.id,
    required this.weekNumber,
    required this.sessionIndex,
    required this.sessionTitle,
    required this.type,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'week_number': weekNumber,
        'session_index': sessionIndex,
        'session_title': sessionTitle,
        'type': type.name,
        'recorded_at': recordedAt.toIso8601String(),
      };

  factory ProgrammeSessionEvent.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString();
    final type = ProgrammeSessionEventType.values.firstWhere(
      (value) => value.name == rawType,
      orElse: () => ProgrammeSessionEventType.completed,
    );
    return ProgrammeSessionEvent(
      id: json['id']?.toString() ?? '',
      weekNumber: (json['week_number'] as num?)?.toInt() ?? 1,
      sessionIndex: (json['session_index'] as num?)?.toInt() ?? 0,
      sessionTitle: json['session_title']?.toString() ?? 'Workout',
      type: type,
      recordedAt: DateTime.tryParse(json['recorded_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class ProgrammeWeekState {
  final int weekNumber;
  final DateTime startedAt;
  final String? previousMode;
  final String? previousSummary;

  const ProgrammeWeekState({
    required this.weekNumber,
    required this.startedAt,
    this.previousMode,
    this.previousSummary,
  });

  Map<String, dynamic> toJson() => {
        'week_number': weekNumber,
        'started_at': startedAt.toIso8601String(),
        if (previousMode != null) 'previous_mode': previousMode,
        if (previousSummary != null) 'previous_summary': previousSummary,
      };

  factory ProgrammeWeekState.fromJson(Map<String, dynamic> json) {
    return ProgrammeWeekState(
      weekNumber: (json['week_number'] as num?)?.toInt() ?? 1,
      startedAt: DateTime.tryParse(json['started_at']?.toString() ?? '') ??
          DateTime.now(),
      previousMode: json['previous_mode']?.toString(),
      previousSummary: json['previous_summary']?.toString(),
    );
  }
}

class ProgrammeAdaptationStore {
  static const _statePrefix = 'leanit_adaptive_week_state_v1';
  static const _eventsPrefix = 'leanit_adaptive_week_events_v1';
  static const _maxEvents = 300;

  static String _scope() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) return user.id;
    } catch (_) {}
    return 'local';
  }

  static String get _stateKey => '${_statePrefix}_${_scope()}';
  static String get _eventsKey => '${_eventsPrefix}_${_scope()}';

  static Future<ProgrammeWeekState?> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stateKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return ProgrammeWeekState.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }

  static Future<ProgrammeWeekState> ensureWeek(int weekNumber) async {
    final existing = await loadState();
    if (existing != null && existing.weekNumber == weekNumber) {
      return existing;
    }

    // When the adaptive feature first meets an already-running programme,
    // inspect a conservative seven-day lookback rather than pretending there
    // is no history. Newly generated programmes call resetForWeek instead.
    final state = ProgrammeWeekState(
      weekNumber: weekNumber,
      startedAt: DateTime.now().subtract(const Duration(days: 7)),
      previousMode: existing?.previousMode,
      previousSummary: existing?.previousSummary,
    );
    await _saveState(state);
    return state;
  }

  static Future<void> resetForWeek(
    int weekNumber, {
    DateTime? startedAt,
    String? previousMode,
    String? previousSummary,
    bool clearEvents = false,
  }) async {
    final state = ProgrammeWeekState(
      weekNumber: weekNumber,
      startedAt: startedAt ?? DateTime.now(),
      previousMode: previousMode,
      previousSummary: previousSummary,
    );
    await _saveState(state);
    if (clearEvents) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_eventsKey);
    }
  }

  static Future<void> _saveState(ProgrammeWeekState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateKey, jsonEncode(state.toJson()));
  }

  static Future<void> recordSessionEvent({
    required int weekNumber,
    required int sessionIndex,
    required String sessionTitle,
    required ProgrammeSessionEventType type,
    DateTime? recordedAt,
  }) async {
    final event = ProgrammeSessionEvent(
      id: '$weekNumber:$sessionIndex:${type.name}',
      weekNumber: weekNumber,
      sessionIndex: sessionIndex,
      sessionTitle: sessionTitle,
      type: type,
      recordedAt: recordedAt ?? DateTime.now(),
    );

    final events = await loadEvents();
    final withoutSame = events.where((item) => item.id != event.id).toList();
    withoutSame.add(event);
    withoutSame.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _eventsKey,
      withoutSame
          .take(_maxEvents)
          .map((item) => jsonEncode(item.toJson()))
          .toList(growable: false),
    );
  }

  static Future<List<ProgrammeSessionEvent>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_eventsKey) ?? const <String>[];
    final events = <ProgrammeSessionEvent>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map) {
          events.add(
            ProgrammeSessionEvent.fromJson(Map<String, dynamic>.from(decoded)),
          );
        }
      } catch (_) {}
    }
    events.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return events;
  }

  static Future<List<ProgrammeSessionEvent>> eventsForWeek(int weekNumber) async {
    final events = await loadEvents();
    return events
        .where((event) => event.weekNumber == weekNumber)
        .toList(growable: false);
  }
}
