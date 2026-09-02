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

  String _cacheKey(String userId) =>
      '${_profileCachePrefix}_${userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';

  Future<Map<String, dynamic>?> _loadCachedProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(userId));
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final profile = Map<String, dynamic>.from(decoded);
      if (profile['id']?.toString() != userId) return null;
      return profile;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheProfile(
    String userId,
    Map<String, dynamic> profile,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey(userId), jsonEncode(profile));
  }

  Future<void> _clearCachedProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey(userId));
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

    try {
      final row = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));
      if (row == null) {
        await _clearCachedProfile(user.id);
        TrainingProfileContext.updateFromMap(null);
        return null;
      }
      final profile = Map<String, dynamic>.from(row);
      await _cacheProfile(user.id, profile);
      TrainingProfileContext.updateFromMap(profile);
      return profile;
    } catch (_) {
      final cached = await _loadCachedProfile(user.id);
      if (cached != null) {
        TrainingProfileContext.updateFromMap(cached);
        return cached;
      }
      rethrow;
    }
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

    final current = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (current != null) {
      final profile = Map<String, dynamic>.from(current);
      await _cacheProfile(user.id, profile);
      TrainingProfileContext.updateFromMap(profile);
    }
    revision.value += 1;
  }

  static void notifyChanged() {
    revision.value += 1;
  }
}
