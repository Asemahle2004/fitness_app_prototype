import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'training_profile_context.dart';

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

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);
  static const _profileCachePrefix = 'leanit_profile_cache_v1';
  static final Map<String, Map<String, dynamic>> _memoryCache = {};
  static final Map<String, Future<void>> _refreshInFlight = {};

  String _cacheKey(String userId) =>
      '${_profileCachePrefix}_${userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';

  Future<Map<String, dynamic>?> _loadCachedProfile(String userId) async {
    final memory = _memoryCache[userId];
    if (memory != null) return Map<String, dynamic>.from(memory);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(userId));
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final profile = Map<String, dynamic>.from(decoded);
      if (profile['id']?.toString() != userId) return null;
      _memoryCache[userId] = Map<String, dynamic>.from(profile);
      return profile;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheProfile(
    String userId,
    Map<String, dynamic> profile,
  ) async {
    _memoryCache[userId] = Map<String, dynamic>.from(profile);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey(userId), jsonEncode(profile));
  }

  Future<void> _clearCachedProfile(String userId) async {
    _memoryCache.remove(userId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey(userId));
  }

  Future<Map<String, dynamic>?> _fetchCloudProfile(String userId) async {
    final row = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle()
        .timeout(const Duration(seconds: 4));
    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  void _refreshCachedProfileInBackground(String userId) {
    if (_refreshInFlight.containsKey(userId)) return;
    final task = () async {
      try {
        final profile = await _fetchCloudProfile(userId);
        if (profile != null) {
          await _cacheProfile(userId, profile);
          TrainingProfileContext.updateFromMap(profile);
        }
      } catch (_) {
        // Offline/slow network leaves the known-good cached profile in place.
      } finally {
        _refreshInFlight.remove(userId);
      }
    }();
    _refreshInFlight[userId] = task;
    unawaited(task);
  }

  Future<LeanEatProfile?> currentProfile() async {
    final row = await currentProfileMap();
    if (row == null) return null;
    return LeanEatProfile.fromMap(row);
  }

  Future<Map<String, dynamic>?> currentProfileMap() async {
    final user = client.auth.currentUser;
    if (user == null) {
      TrainingProfileContext.updateFromMap(null);
      return null;
    }

    // Cache-first is essential for gym/run offline use. A previously loaded
    // account should never wait four seconds for a failed network request just
    // to open its home screen.
    final cached = await _loadCachedProfile(user.id);
    if (cached != null) {
      TrainingProfileContext.updateFromMap(cached);
      _refreshCachedProfileInBackground(user.id);
      return cached;
    }

    final profile = await _fetchCloudProfile(user.id);
    if (profile == null) {
      await _clearCachedProfile(user.id);
      TrainingProfileContext.updateFromMap(null);
      return null;
    }
    await _cacheProfile(user.id, profile);
    TrainingProfileContext.updateFromMap(profile);
    return profile;
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    final payload = <String, dynamic>{...updates};
    final mainGoal = payload['main_goal']?.toString().trim();
    if (!payload.containsKey('goals') && mainGoal != null && mainGoal.isNotEmpty) {
      payload['goals'] = <String>[mainGoal];
    }

    await client.from('profiles').upsert({
      'id': user.id,
      ...payload,
      'updated_at': DateTime.now().toIso8601String(),
    });

    final current = await _fetchCloudProfile(user.id);
    if (current != null) {
      await _cacheProfile(user.id, current);
      TrainingProfileContext.updateFromMap(current);
    }
    revision.value += 1;
  }

  static void notifyChanged() {
    revision.value += 1;
  }
}
