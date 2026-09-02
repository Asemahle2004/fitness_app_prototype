import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'programme_adaptation_store.dart';
import 'programme_engine.dart';
import 'programme_store.dart';
import 'sync_queue.dart';

class ProgrammeActivationService {
  final SupabaseClient client;

  const ProgrammeActivationService(this.client);

  static const _cachePrefix = 'leanit_current_programme_cache_v1';

  Future<StoredProgramme> activate(
    GeneratedProgramme programme, {
    String source = 'library',
  }) async {
    final current = await ProgrammeStore(client).loadCurrent();
    final signature = current?.profileSignature ?? 'manual:$source';
    final stored = StoredProgramme(
      programme: programme,
      profileSignature: signature,
      currentWeek: 1,
      currentSessionIndex: 0,
      activeSessionIndex: null,
      activeStartedAt: null,
    );
    final user = client.auth.currentUser;
    final row = <String, dynamic>{
      if (user != null) 'user_id': user.id,
      'profile_signature': signature,
      'goal': programme.goal,
      'structure': programme.structure,
      'explanation': programme.explanation,
      'sessions': programme.sessions
          .map((session) => <String, dynamic>{
                'day': session.day,
                'title': session.title,
                'location': session.location,
                'duration': session.duration,
                'focus': session.focus,
                'intensity': session.intensity,
                'personalisation_note': session.personalisationNote,
              })
          .toList(growable: false),
      'current_week': 1,
      'current_session_index': 0,
      'active_session_index': null,
      'active_started_at': null,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _saveLocal(row, user?.id ?? 'guest');
    await ProgrammeAdaptationStore.resetForWeek(
      1,
      startedAt: DateTime.now(),
      clearEvents: true,
    );

    if (user != null) {
      try {
        await client.from('current_programmes').upsert(row);
      } catch (_) {
        await SyncQueueStore(userScope: user.id).enqueue(
          table: 'current_programmes',
          action: 'upsert',
          data: row,
          matchColumn: 'user_id',
          matchValue: user.id,
        );
      }
    }
    return stored;
  }

  Future<void> _saveLocal(Map<String, dynamic> row, String scope) async {
    final safe = scope.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_cachePrefix}_$safe', jsonEncode(row));
  }
}
