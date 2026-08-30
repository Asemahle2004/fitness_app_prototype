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

  Future<LeanEatProfile?> currentProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final row = await client.from('profiles').select().eq('id', user.id).maybeSingle();
    if (row == null) return null;
    return LeanEatProfile.fromMap(row);
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = client.auth.currentUser;
    if (user == null) return;
    await client.from('profiles').upsert({
      'id': user.id,
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
