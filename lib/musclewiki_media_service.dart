import 'package:supabase_flutter/supabase_flutter.dart';

class MuscleWikiMediaResult {
  final bool available;
  final String? imageUrl;
  final String? videoUrl;
  final int? providerExerciseId;
  final String? providerExerciseName;
  final int? expiresInSeconds;
  final String? reason;

  const MuscleWikiMediaResult({
    required this.available,
    this.imageUrl,
    this.videoUrl,
    this.providerExerciseId,
    this.providerExerciseName,
    this.expiresInSeconds,
    this.reason,
  });

  factory MuscleWikiMediaResult.fromData(dynamic data) {
    if (data is! Map) {
      return const MuscleWikiMediaResult(
        available: false,
        reason: 'invalid_provider_response',
      );
    }
    final map = Map<String, dynamic>.from(data);
    return MuscleWikiMediaResult(
      available: map['available'] == true,
      imageUrl: map['imageUrl']?.toString(),
      videoUrl: map['videoUrl']?.toString(),
      providerExerciseId: (map['providerExerciseId'] as num?)?.toInt(),
      providerExerciseName: map['providerExerciseName']?.toString(),
      expiresInSeconds: (map['expiresIn'] as num?)?.toInt(),
      reason: map['reason']?.toString(),
    );
  }
}

class MuscleWikiMediaService {
  final SupabaseClient client;

  const MuscleWikiMediaService(this.client);

  // Tokenised provider URLs are intentionally memory-only. They are short-lived
  // access credentials and must never be written to SharedPreferences, the
  // database, logs or Supabase Storage.
  static final Map<String, _MemoryEntry> _memory = <String, _MemoryEntry>{};

  Future<MuscleWikiMediaResult> resolve({
    required String exerciseName,
    String? sex,
  }) async {
    final resolvedSex = sex == 'Female' ? 'female' : 'male';
    final key = '${exerciseName.trim().toLowerCase()}::$resolvedSex';
    final cached = _memory[key];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return cached.result;
    }

    try {
      final response = await client.functions
          .invoke(
            'musclewiki-media',
            body: <String, dynamic>{
              'exerciseName': exerciseName,
              'sex': resolvedSex,
            },
          )
          .timeout(const Duration(seconds: 4));
      final result = MuscleWikiMediaResult.fromData(response.data);
      if (result.available) {
        final ttl = (result.expiresInSeconds ?? 600).clamp(60, 840);
        _memory[key] = _MemoryEntry(
          result: result,
          expiresAt: DateTime.now().add(Duration(seconds: ttl - 30)),
        );
      }
      return result;
    } on FunctionException catch (error) {
      return MuscleWikiMediaResult(
        available: false,
        reason: 'provider_function_${error.status}',
      );
    } catch (_) {
      return const MuscleWikiMediaResult(
        available: false,
        reason: 'provider_unavailable',
      );
    }
  }

  static void clearMemoryCache() => _memory.clear();
}

class _MemoryEntry {
  final MuscleWikiMediaResult result;
  final DateTime expiresAt;

  const _MemoryEntry({required this.result, required this.expiresAt});
}
