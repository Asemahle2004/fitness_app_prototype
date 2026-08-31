import 'package:supabase_flutter/supabase_flutter.dart';

class ExerciseSetPerformance {
  final String exerciseName;
  final int setNumber;
  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final DateTime performedAt;

  const ExerciseSetPerformance({
    required this.exerciseName,
    required this.setNumber,
    required this.reps,
    required this.weightKg,
    required this.durationSeconds,
    required this.performedAt,
  });

  factory ExerciseSetPerformance.fromMap(Map<String, dynamic> map) {
    return ExerciseSetPerformance(
      exerciseName: map['exercise_name']?.toString() ?? 'Exercise',
      setNumber: (map['set_number'] as num?)?.toInt() ?? 1,
      reps: (map['reps'] as num?)?.toInt(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      durationSeconds: (map['duration_seconds'] as num?)?.toInt(),
      performedAt: DateTime.tryParse(map['performed_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String get summary {
    if (durationSeconds != null) {
      final minutes = durationSeconds! ~/ 60;
      final seconds = durationSeconds! % 60;
      return minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
    }
    if (weightKg != null && reps != null) {
      final weight = weightKg! % 1 == 0
          ? weightKg!.toStringAsFixed(0)
          : weightKg!.toStringAsFixed(1);
      return '$weight kg × $reps reps';
    }
    if (reps != null) return '$reps reps';
    return 'Completed set';
  }
}

class ExercisePerformanceStore {
  final SupabaseClient client;

  const ExercisePerformanceStore(this.client);

  Future<void> saveSet({
    required String workoutTitle,
    required String exerciseName,
    required int setNumber,
    int? reps,
    double? weightKg,
    int? durationSeconds,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    await client.from('exercise_set_logs').insert({
      'user_id': user.id,
      'workout_title': workoutTitle,
      'exercise_name': exerciseName,
      'set_number': setNumber,
      'reps': reps,
      'weight_kg': weightKg,
      'duration_seconds': durationSeconds,
      'performed_at': DateTime.now().toIso8601String(),
    });
  }

  Future<ExerciseSetPerformance?> latestForExercise(String exerciseName) async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final row = await client
        .from('exercise_set_logs')
        .select(
          'exercise_name,set_number,reps,weight_kg,duration_seconds,performed_at',
        )
        .eq('user_id', user.id)
        .eq('exercise_name', exerciseName)
        .order('performed_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) return null;
    return ExerciseSetPerformance.fromMap(Map<String, dynamic>.from(row));
  }
}