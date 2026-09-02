import 'package:flutter/foundation.dart';
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
    final row = await client.from('profiles').select().eq('id', user.id).maybeSingle();
    if (row == null) {
      TrainingProfileContext.updateFromMap(null);
      return null;
    }
    final profile = Map<String, dynamic>.from(row);
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

    final current = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (current != null) {
      TrainingProfileContext.updateFromMap(Map<String, dynamic>.from(current));
    }
    revision.value += 1;
  }

  static void notifyChanged() {
    revision.value += 1;
  }
}
