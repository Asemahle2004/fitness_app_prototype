import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'adaptive_programme_engine.dart';
import 'adaptive_strength_engine.dart';
import 'app_health.dart';
import 'periodization_engine.dart';
import 'programme_adaptation_store.dart';
import 'programme_engine.dart';
import 'strength_adaptation_cache.dart';
import 'sync_queue.dart';

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

  static const _cachePrefix = 'leanit_current_programme_cache_v1';

  String get _scope => client.auth.currentUser?.id ?? 'guest';
  String get _cacheKey =>
      '${_cachePrefix}_${_scope.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';

  static Set<String> _stringSet(dynamic value) {
    if (value is! List) return <String>{};
    return value.whereType<String>().toSet();
  }

  static List<String> _sortedStrings(dynamic value) {
    final items = _stringSet(value).toList()..sort();
    return items;
  }

  static String _string(
    Map<String, dynamic> profile,
    String key,
    String fallback,
  ) {
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

  static List<Map<String, dynamic>> _sessionsToJson(
    List<PlannedSession> sessions,
  ) {
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
      activeStartedAt:
          DateTime.tryParse(row['active_started_at']?.toString() ?? ''),
    );
  }

  static Map<String, dynamic> _rowForStored(
    StoredProgramme value, {
    String? userId,
  }) => <String, dynamic>{
        if (userId != null) 'user_id': userId,
        'profile_signature': value.profileSignature,
        'goal': value.programme.goal,
        'structure': value.programme.structure,
        'explanation': value.programme.explanation,
        'sessions': _sessionsToJson(value.programme.sessions),
        'current_week': value.currentWeek,
        'current_session_index': value.currentSessionIndex,
        'active_session_index': value.activeSessionIndex,
        'active_started_at': value.activeStartedAt?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  Future<void> _cache(StoredProgramme value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(_rowForStored(value)));
    _updatePeriodization(value.currentWeek);
  }

  Future<StoredProgramme?> _cached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final value = _fromRow(Map<String, dynamic>.from(decoded));
      _updatePeriodization(value.currentWeek);
      return value;
    } catch (_) {
      return null;
    }
  }

  static void _updatePeriodization(int week) {
    final strength = StrengthAdaptationCache.current;
    PeriodizationEngine.setCurrent(
      PeriodizationEngine.forWeek(
        programmeWeek: week,
        forceRecovery: strength?.action == StrengthAdaptationAction.deload,
        consolidate: strength?.action == StrengthAdaptationAction.reduce ||
            strength?.action == StrengthAdaptationAction.maintain,
        progressionSupported:
            strength?.action == StrengthAdaptationAction.progress,
      ),
    );
  }

  Future<void> _writeCloudOrQueue(
    Map<String, dynamic> row, {
    String action = 'upsert',
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return;
    final payload = <String, dynamic>{...row, 'user_id': user.id};
    try {
      if (action == 'upsert') {
        await client.from('current_programmes').upsert(payload);
      } else {
        await client
            .from('current_programmes')
            .update(payload..remove('user_id'))
            .eq('user_id', user.id);
      }
    } catch (error) {
      await SyncQueueStore(userScope: user.id).enqueue(
        table: 'current_programmes',
        action: 'upsert',
        data: payload,
        matchColumn: 'user_id',
        matchValue: user.id,
      );
      await AppErrorStore.record('Programme cloud sync', error);
    }
  }

  Future<StoredProgramme> ensureForProfile(Map<String, dynamic> profile) async {
    final generated = programmeFromProfile(profile);
    final signature = signatureForProfile(profile);
    final user = client.auth.currentUser;

    if (user == null) {
      final local = StoredProgramme(
        programme: generated,
        profileSignature: signature,
        currentWeek: 1,
        currentSessionIndex: 0,
        activeSessionIndex: null,
        activeStartedAt: null,
      );
      await _cache(local);
      return local;
    }

    StoredProgramme? existing;
    try {
      final row = await client
          .from('current_programmes')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (row != null) existing = _fromRow(Map<String, dynamic>.from(row));
    } catch (error) {
      existing = await _cached();
      await AppErrorStore.record('Programme load', error);
    }

    if (existing != null &&
        existing.profileSignature == signature &&
        existing.hasSessions) {
      await ProgrammeAdaptationStore.ensureWeek(existing.currentWeek);
      await _cache(existing);
      return existing;
    }

    final created = StoredProgramme(
      programme: generated,
      profileSignature: signature,
      currentWeek: 1,
      currentSessionIndex: 0,
      activeSessionIndex: null,
      activeStartedAt: null,
    );
    await _cache(created);
    await _writeCloudOrQueue(_rowForStored(created, userId: user.id));
    await ProgrammeAdaptationStore.resetForWeek(
      1,
      startedAt: DateTime.now(),
      clearEvents: true,
    );
    return created;
  }

  Future<StoredProgramme?> loadCurrent() async {
    final user = client.auth.currentUser;
    if (user == null) return _cached();
    try {
      final row = await client
          .from('current_programmes')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (row == null) return _cached();
      final stored = _fromRow(Map<String, dynamic>.from(row));
      await _cache(stored);
      return stored;
    } catch (error) {
      await AppErrorStore.record('Programme load', error);
      return _cached();
    }
  }

  Future<void> markSessionStarted(int sessionIndex) async {
    final current = await loadCurrent();
    if (current == null) return;
    final updated = StoredProgramme(
      programme: current.programme,
      profileSignature: current.profileSignature,
      currentWeek: current.currentWeek,
      currentSessionIndex: current.currentSessionIndex,
      activeSessionIndex: sessionIndex,
      activeStartedAt: DateTime.now(),
    );
    await _cache(updated);
    await _writeCloudOrQueue(_rowForStored(updated));
  }

  Future<void> clearActiveSession() async {
    final current = await loadCurrent();
    if (current == null) return;
    final updated = StoredProgramme(
      programme: current.programme,
      profileSignature: current.profileSignature,
      currentWeek: current.currentWeek,
      currentSessionIndex: current.currentSessionIndex,
      activeSessionIndex: null,
      activeStartedAt: null,
    );
    await _cache(updated);
    await _writeCloudOrQueue(_rowForStored(updated));
  }

  Future<void> completeSession(
    int completedIndex, {
    Map<String, dynamic>? profile,
  }) async {
    final current = await loadCurrent();
    if (current == null || current.programme.sessions.isEmpty) return;
    if (completedIndex < 0 ||
        completedIndex >= current.programme.sessions.length) {
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
    if (current.programme.sessions.isEmpty) return;

    final count = current.programme.sessions.length;
    var nextIndex = completedIndex + 1;
    var nextWeek = current.currentWeek;

    if (nextIndex < count) {
      final updated = StoredProgramme(
        programme: current.programme,
        profileSignature: current.profileSignature,
        currentWeek: current.currentWeek,
        currentSessionIndex: nextIndex,
        activeSessionIndex: null,
        activeStartedAt: null,
      );
      await _cache(updated);
      await _writeCloudOrQueue(_rowForStored(updated));
      return;
    }

    nextIndex = 0;
    nextWeek += 1;
    var nextProgramme =
        profile == null ? current.programme : programmeFromProfile(profile);
    String? adaptiveMode;
    String? adaptiveSummary;
    AdaptiveWeekMode? decisionMode;

    if (profile != null) {
      try {
        final result = await AdaptiveProgrammeService(client).buildNextWeek(
          profile: profile,
          currentProgramme: current.programme,
          currentWeek: current.currentWeek,
        );
        nextProgramme = result.programme;
        decisionMode = result.decision.mode;
        adaptiveMode = result.decision.mode.name;
        adaptiveSummary = result.decision.summary;
      } catch (error) {
        await AppErrorStore.record('Adaptive week build', error);
        nextProgramme = programmeFromProfile(profile);
      }
    }

    final strength = StrengthAdaptationCache.current;
    final plan = PeriodizationEngine.forWeek(
      programmeWeek: nextWeek,
      forceRecovery: decisionMode == AdaptiveWeekMode.recovery ||
          strength?.action == StrengthAdaptationAction.deload,
      consolidate: decisionMode == AdaptiveWeekMode.consolidate ||
          strength?.action == StrengthAdaptationAction.reduce ||
          strength?.action == StrengthAdaptationAction.maintain,
      progressionSupported: decisionMode == AdaptiveWeekMode.progress &&
          (strength == null ||
              strength.action == StrengthAdaptationAction.progress),
    );
    PeriodizationEngine.setCurrent(plan);
    final periodizedSessions =
        PeriodizationEngine.adaptSessions(nextProgramme.sessions, plan);
    nextProgramme = GeneratedProgramme(
      goal: nextProgramme.goal,
      structure: '${nextProgramme.structure} • ${plan.phase.label} block',
      explanation:
          '${plan.headline}. ${plan.reasons.join(' ')}\n\n${nextProgramme.explanation}',
      sessions: periodizedSessions,
    );

    final updated = StoredProgramme(
      programme: nextProgramme,
      profileSignature: current.profileSignature,
      currentWeek: nextWeek,
      currentSessionIndex: nextIndex,
      activeSessionIndex: null,
      activeStartedAt: null,
    );
    await _cache(updated);
    await _writeCloudOrQueue(_rowForStored(updated));

    await ProgrammeAdaptationStore.resetForWeek(
      nextWeek,
      startedAt: DateTime.now(),
      previousMode: adaptiveMode,
      previousSummary: adaptiveSummary,
    );
  }
}
