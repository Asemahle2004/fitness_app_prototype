import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'adaptive_programme_engine.dart';
import 'programme_adaptation_store.dart';
import 'programme_engine.dart';

class StoredProgramme {
  final GeneratedProgramme programme;
  final String profileSignature;
  final int currentWeek;
  final int currentSessionIndex;
  final int? activeSessionIndex;
  final DateTime? activeStartedAt;

  const StoredProgramme({
    required this.programme,
    required this.profileSignature,
    required this.currentWeek,
    required this.currentSessionIndex,
    required this.activeSessionIndex,
    required this.activeStartedAt,
  });

  bool get hasSessions => programme.sessions.isNotEmpty;

  int get safeCurrentSessionIndex {
    if (programme.sessions.isEmpty) return 0;
    return currentSessionIndex.clamp(0, programme.sessions.length - 1);
  }

  PlannedSession? get currentSession {
    if (programme.sessions.isEmpty) return null;
    return programme.sessions[safeCurrentSessionIndex];
  }

  PlannedSession? get nextSession {
    if (programme.sessions.length < 2) return null;
    final next = safeCurrentSessionIndex + 1;
    if (next < programme.sessions.length) return programme.sessions[next];
    return programme.sessions.first;
  }
}

class ProgrammeStore {
  final SupabaseClient client;

  const ProgrammeStore(this.client);

  static Set<String> _stringSet(dynamic value) {
    if (value is! List) return <String>{};
    return value.whereType<String>().toSet();
  }

  static List<String> _sortedStrings(dynamic value) {
    final items = _stringSet(value).toList()..sort();
    return items;
  }

  static String _string(Map<String, dynamic> profile, String key, String fallback) {
    final value = profile[key]?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  static GeneratedProgramme programmeFromProfile(Map<String, dynamic> profile) {
    return ProgrammeEngine.generate(
      goal: _string(profile, 'main_goal', 'Improve General Fitness'),
      experience: _string(profile, 'experience', 'Beginner'),
      fitnessLevel: _string(profile, 'fitness_level', 'Low'),
      activityLevel: _string(profile, 'activity_level', 'Moderately active'),
      availableDays: _stringSet(profile['available_days']),
      locations: _stringSet(profile['training_locations']),
      homeEquipment: _stringSet(profile['home_equipment']),
      gymAccess: _string(profile, 'gym_access', 'Standard gym'),
      sessionLength: _string(profile, 'session_length', '45 min'),
      trainingTime: _string(profile, 'training_time', 'Flexible'),
      hasLimitation: profile['has_limitation'] == true,
      affectedAreas: _stringSet(profile['affected_areas']),
    );
  }

  static String signatureForProfile(Map<String, dynamic> profile) {
    final snapshot = <String, dynamic>{
      'goal': _string(profile, 'main_goal', 'Improve General Fitness'),
      'experience': _string(profile, 'experience', 'Beginner'),
      'fitnessLevel': _string(profile, 'fitness_level', 'Low'),
      'activityLevel': _string(profile, 'activity_level', 'Moderately active'),
      'days': _sortedStrings(profile['available_days']),
      'locations': _sortedStrings(profile['training_locations']),
      'homeEquipment': _sortedStrings(profile['home_equipment']),
      'gymAccess': profile['gym_access']?.toString(),
      'sessionLength': _string(profile, 'session_length', '45 min'),
      'trainingTime': _string(profile, 'training_time', 'Flexible'),
      'hasLimitation': profile['has_limitation'] == true,
      'affectedAreas': _sortedStrings(profile['affected_areas']),
      'warningSigns': _sortedStrings(profile['warning_signs']),
    };
    return jsonEncode(snapshot);
  }

  static List<Map<String, dynamic>> _sessionsToJson(List<PlannedSession> sessions) {
    return sessions
        .map(
          (session) => <String, dynamic>{
            'day': session.day,
            'title': session.title,
            'location': session.location,
            'duration': session.duration,
            'focus': session.focus,
            'intensity': session.intensity,
            'personalisation_note': session.personalisationNote,
          },
        )
        .toList(growable: false);
  }

  static List<PlannedSession> _sessionsFromJson(dynamic value) {
    if (value is! List) return const <PlannedSession>[];
    final sessions = <PlannedSession>[];
    for (final item in value) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      sessions.add(
        PlannedSession(
          day: map['day']?.toString() ?? 'Flexible',
          title: map['title']?.toString() ?? 'Workout',
          location: map['location']?.toString() ?? 'Flexible',
          duration: map['duration']?.toString() ?? '45 min',
          focus: map['focus']?.toString() ?? 'Balanced training',
          intensity: map['intensity']?.toString() ?? 'Moderate',
          personalisationNote:
              map['personalisation_note']?.toString() ?? '',
        ),
      );
    }
    return sessions;
  }

  static StoredProgramme _fromRow(Map<String, dynamic> row) {
    return StoredProgramme(
      programme: GeneratedProgramme(
        goal: row['goal']?.toString() ?? 'Improve General Fitness',
        structure: row['structure']?.toString() ?? 'Training programme',
        explanation: row['explanation']?.toString() ?? '',
        sessions: _sessionsFromJson(row['sessions']),
      ),
      profileSignature: row['profile_signature']?.toString() ?? '',
      currentWeek: (row['current_week'] as num?)?.toInt() ?? 1,
      currentSessionIndex: (row['current_session_index'] as num?)?.toInt() ?? 0,
      activeSessionIndex: (row['active_session_index'] as num?)?.toInt(),
      activeStartedAt: DateTime.tryParse(row['active_started_at']?.toString() ?? ''),
    );
  }

  Future<StoredProgramme> ensureForProfile(Map<String, dynamic> profile) async {
    final generated = programmeFromProfile(profile);
    final signature = signatureForProfile(profile);
    final user = client.auth.currentUser;

    if (user == null) {
      return StoredProgramme(
        programme: generated,
        profileSignature: signature,
        currentWeek: 1,
        currentSessionIndex: 0,
        activeSessionIndex: null,
        activeStartedAt: null,
      );
    }

    final existing = await client
        .from('current_programmes')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      final stored = _fromRow(Map<String, dynamic>.from(existing));
      if (stored.profileSignature == signature && stored.hasSessions) {
        await ProgrammeAdaptationStore.ensureWeek(stored.currentWeek);
        return stored;
      }
    }

    final now = DateTime.now().toIso8601String();
    final row = <String, dynamic>{
      'user_id': user.id,
      'profile_signature': signature,
      'goal': generated.goal,
      'structure': generated.structure,
      'explanation': generated.explanation,
      'sessions': _sessionsToJson(generated.sessions),
      'current_week': 1,
      'current_session_index': 0,
      'active_session_index': null,
      'active_started_at': null,
      'updated_at': now,
    };

    await client.from('current_programmes').upsert(row);
    await ProgrammeAdaptationStore.resetForWeek(
      1,
      startedAt: DateTime.now(),
      clearEvents: true,
    );

    return StoredProgramme(
      programme: generated,
      profileSignature: signature,
      currentWeek: 1,
      currentSessionIndex: 0,
      activeSessionIndex: null,
      activeStartedAt: null,
    );
  }

  Future<StoredProgramme?> loadCurrent() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final row = await client
        .from('current_programmes')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    if (row == null) return null;
    return _fromRow(Map<String, dynamic>.from(row));
  }

  Future<void> markSessionStarted(int sessionIndex) async {
    final user = client.auth.currentUser;
    if (user == null) return;
    await client.from('current_programmes').update({
      'active_session_index': sessionIndex,
      'active_started_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', user.id);
  }

  Future<void> clearActiveSession() async {
    final user = client.auth.currentUser;
    if (user == null) return;
    await client.from('current_programmes').update({
      'active_session_index': null,
      'active_started_at': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', user.id);
  }

  Future<void> completeSession(
    int completedIndex, {
    Map<String, dynamic>? profile,
  }) async {
    final current = await loadCurrent();
    if (current == null || current.programme.sessions.isEmpty) return;
    if (completedIndex < 0 || completedIndex >= current.programme.sessions.length) {
      return;
    }

    final session = current.programme.sessions[completedIndex];
    await ProgrammeAdaptationStore.recordSessionEvent(
      weekNumber: current.currentWeek,
      sessionIndex: completedIndex,
      sessionTitle: session.title,
      type: ProgrammeSessionEventType.completed,
    );
    await _advanceSession(
      current: current,
      completedIndex: completedIndex,
      profile: profile,
    );
  }

  Future<void> skipSession(
    int skippedIndex, {
    required Map<String, dynamic> profile,
  }) async {
    final current = await loadCurrent();
    if (current == null || current.programme.sessions.isEmpty) return;
    if (skippedIndex < 0 || skippedIndex >= current.programme.sessions.length) {
      return;
    }
    if (current.activeSessionIndex != null) return;

    final session = current.programme.sessions[skippedIndex];
    await ProgrammeAdaptationStore.recordSessionEvent(
      weekNumber: current.currentWeek,
      sessionIndex: skippedIndex,
      sessionTitle: session.title,
      type: ProgrammeSessionEventType.skipped,
    );
    await _advanceSession(
      current: current,
      completedIndex: skippedIndex,
      profile: profile,
    );
  }

  Future<void> _advanceSession({
    required StoredProgramme current,
    required int completedIndex,
    Map<String, dynamic>? profile,
  }) async {
    final user = client.auth.currentUser;
    if (user == null || current.programme.sessions.isEmpty) return;

    final count = current.programme.sessions.length;
    var nextIndex = completedIndex + 1;
    var nextWeek = current.currentWeek;

    if (nextIndex < count) {
      await client.from('current_programmes').update({
        'current_session_index': nextIndex,
        'active_session_index': null,
        'active_started_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', user.id);
      return;
    }

    nextIndex = 0;
    nextWeek += 1;
    var nextProgramme = profile == null
        ? current.programme
        : programmeFromProfile(profile);
    String? adaptiveMode;
    String? adaptiveSummary;

    if (profile != null) {
      try {
        final result = await AdaptiveProgrammeService(client).buildNextWeek(
          profile: profile,
          currentProgramme: current.programme,
          currentWeek: current.currentWeek,
        );
        nextProgramme = result.programme;
        adaptiveMode = result.decision.mode.name;
        adaptiveSummary = result.decision.summary;
      } catch (_) {
        // If adaptation data is unavailable, fall back to the safe static
        // profile-generated programme rather than blocking the week transition.
        nextProgramme = programmeFromProfile(profile);
      }
    }

    await client.from('current_programmes').update({
      'goal': nextProgramme.goal,
      'structure': nextProgramme.structure,
      'explanation': nextProgramme.explanation,
      'sessions': _sessionsToJson(nextProgramme.sessions),
      'current_week': nextWeek,
      'current_session_index': nextIndex,
      'active_session_index': null,
      'active_started_at': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', user.id);

    await ProgrammeAdaptationStore.resetForWeek(
      nextWeek,
      startedAt: DateTime.now(),
      previousMode: adaptiveMode,
      previousSummary: adaptiveSummary,
    );
  }
}
