import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'programme_engine.dart';

class WeeklyScheduleSnapshot {
  final List<PlannedSession> sessions;
  final List<String> skippedSessions;
  final bool restored;

  const WeeklyScheduleSnapshot({
    required this.sessions,
    required this.skippedSessions,
    required this.restored,
  });
}

class WeeklyScheduleStore {
  final String userScope;

  const WeeklyScheduleStore({required this.userScope});

  Future<WeeklyScheduleSnapshot> load({
    required List<PlannedSession> baseSessions,
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(now ?? DateTime.now());
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return WeeklyScheduleSnapshot(
        sessions: List<PlannedSession>.from(baseSessions),
        skippedSessions: const <String>[],
        restored: false,
      );
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['base_signature'] != _signature(baseSessions)) {
        await prefs.remove(key);
        return WeeklyScheduleSnapshot(
          sessions: List<PlannedSession>.from(baseSessions),
          skippedSessions: const <String>[],
          restored: false,
        );
      }
      final sessionJson = (json['sessions'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final sessions = sessionJson.map(_sessionFromJson).toList(growable: true);
      final skipped = (json['skipped_sessions'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false);
      return WeeklyScheduleSnapshot(
        sessions: sessions,
        skippedSessions: skipped,
        restored: true,
      );
    } catch (_) {
      await prefs.remove(key);
      return WeeklyScheduleSnapshot(
        sessions: List<PlannedSession>.from(baseSessions),
        skippedSessions: const <String>[],
        restored: false,
      );
    }
  }

  Future<void> save({
    required List<PlannedSession> baseSessions,
    required List<PlannedSession> sessions,
    required List<String> skippedSessions,
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(now ?? DateTime.now());
    await prefs.setString(
      key,
      jsonEncode(<String, dynamic>{
        'base_signature': _signature(baseSessions),
        'sessions': sessions.map(_sessionToJson).toList(growable: false),
        'skipped_sessions': skippedSessions,
      }),
    );
  }

  Future<void> reset({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey(now ?? DateTime.now()));
  }

  String _storageKey(DateTime now) {
    final start = _weekStart(now);
    final date = '${start.year.toString().padLeft(4, '0')}'
        '${start.month.toString().padLeft(2, '0')}'
        '${start.day.toString().padLeft(2, '0')}';
    final safeScope = userScope.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return 'leanit_week_schedule_v1_${safeScope}_$date';
  }

  static DateTime _weekStart(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.subtract(Duration(days: local.weekday - DateTime.monday));
  }

  static String _signature(List<PlannedSession> sessions) => sessions
      .map(
        (session) =>
            '${session.day}|${session.title}|${session.location}|${session.duration}',
      )
      .join('||');

  static Map<String, dynamic> _sessionToJson(PlannedSession session) =>
      <String, dynamic>{
        'day': session.day,
        'title': session.title,
        'location': session.location,
        'duration': session.duration,
        'focus': session.focus,
        'intensity': session.intensity,
        'personalisation_note': session.personalisationNote,
      };

  static PlannedSession _sessionFromJson(Map<String, dynamic> json) =>
      PlannedSession(
        day: json['day']?.toString() ?? 'Monday',
        title: json['title']?.toString() ?? 'Workout',
        location: json['location']?.toString() ?? 'Gym',
        duration: json['duration']?.toString() ?? '45 min',
        focus: json['focus']?.toString() ?? 'Balanced training',
        intensity: json['intensity']?.toString() ?? 'Moderate',
        personalisationNote: json['personalisation_note']?.toString() ?? '',
      );
}
