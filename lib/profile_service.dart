import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeanEatProfile {
  final String id;
  final String? fullName;
  final String? sex;
  final String? visualPreference;
  final bool onboardingComplete;

  const LeanEatProfile({
    required this.id,
    this.fullName,
    this.sex,
    this.visualPreference,
    required this.onboardingComplete,
  });

  factory LeanEatProfile.fromMap(Map<String, dynamic> map) => LeanEatProfile(
        id: map['id'] as String,
        fullName: map['full_name'] as String?,
        sex: map['sex'] as String?,
        visualPreference: map['visual_preference'] as String?,
        onboardingComplete: map['onboarding_complete'] as bool? ?? false,
      );

  String? get preferredVisualSex {
    if (visualPreference == 'Female') return 'Female';
    if (visualPreference == 'Male') return 'Male';
    if (visualPreference == 'Neutral') return null;
    return sex == 'Female' || sex == 'Male' ? sex : null;
  }
}

class ProfileService {
  final SupabaseClient client;
  const ProfileService(this.client);

  static const _cachePrefix = 'leanit_profile_cache_v1';
  static const _pendingPrefix = 'leanit_profile_pending_v1';

  /// Incremented whenever the signed-in profile changes locally or a fresher
  /// cloud copy arrives. Screens can refresh without waiting for another sign-in.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Future<LeanEatProfile?> currentProfile() async {
    final row = await currentProfileMap();
    if (row == null) return null;
    return LeanEatProfile.fromMap(row);
  }

  /// Local-first profile access.
  ///
  /// Once a profile has been loaded or created on this device, LeanIt can open
  /// it immediately without a network connection. A cloud refresh happens in
  /// the background when connectivity is available.
  Future<Map<String, dynamic>?> currentProfileMap() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final cached = await _readMap(_cacheKey(user.id));
    if (cached != null) {
      unawaited(_refreshFromCloud(user.id, cached));
      return cached;
    }

    try {
      await _flushPending(user.id);
      final row = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (row == null) return null;
      final profile = Map<String, dynamic>.from(row);
      await _writeMap(_cacheKey(user.id), profile);
      return profile;
    } catch (_) {
      // There is no local copy yet. Account creation/sign-in still requires a
      // connection once; after the first successful profile load the app can
      // use the cached profile offline.
      return null;
    }
  }

  /// Saves locally first, then best-effort syncs to Supabase. Offline edits are
  /// retained and retried on the next successful profile refresh.
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    final current = await _readMap(_cacheKey(user.id)) ?? <String, dynamic>{
      'id': user.id,
    };
    final merged = <String, dynamic>{
      ...current,
      'id': user.id,
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _writeMap(_cacheKey(user.id), merged);
    await _writeMap(_pendingKey(user.id), merged);
    revision.value += 1;

    try {
      await client.from('profiles').upsert(merged);
      await _remove(_pendingKey(user.id));
    } catch (_) {
      // The pending copy is intentionally kept for the next online refresh.
    }
  }

  Future<void> _refreshFromCloud(
    String userId,
    Map<String, dynamic> cached,
  ) async {
    try {
      await _flushPending(userId);
      final row = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return;
      final fresh = Map<String, dynamic>.from(row);
      final changed = jsonEncode(fresh) != jsonEncode(cached);
      await _writeMap(_cacheKey(userId), fresh);
      if (changed) revision.value += 1;
    } catch (_) {
      // Cached profile remains authoritative while offline.
    }
  }

  Future<void> _flushPending(String userId) async {
    final pending = await _readMap(_pendingKey(userId));
    if (pending == null) return;
    await client.from('profiles').upsert(pending);
    await _remove(_pendingKey(userId));
  }

  static String _cacheKey(String userId) => '${_cachePrefix}_$userId';
  static String _pendingKey(String userId) => '${_pendingPrefix}_$userId';

  static Future<Map<String, dynamic>?> _readMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  static Future<void> _writeMap(
    String key,
    Map<String, dynamic> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }

  static Future<void> _remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static void notifyChanged() {
    revision.value += 1;
  }
}
