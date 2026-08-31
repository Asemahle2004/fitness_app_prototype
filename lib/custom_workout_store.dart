import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'workout_engine.dart';

class CustomWorkout {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ExercisePrescription> exercises;

  const CustomWorkout({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.exercises,
  });

  GeneratedWorkout get generatedWorkout => GeneratedWorkout(
        title: name,
        exercises: List<ExercisePrescription>.unmodifiable(exercises),
      );

  CustomWorkout copyWith({
    String? name,
    DateTime? updatedAt,
    List<ExercisePrescription>? exercises,
  }) {
    return CustomWorkout(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'exercises': exercises.map(_exerciseToJson).toList(growable: false),
      };

  factory CustomWorkout.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'] as List? ?? const [];
    final exercises = <ExercisePrescription>[];
    for (final item in rawExercises) {
      if (item is Map) {
        exercises.add(
          _exerciseFromJson(Map<String, dynamic>.from(item)),
        );
      }
    }

    final now = DateTime.now();
    return CustomWorkout(
      id: json['id']?.toString() ?? now.microsecondsSinceEpoch.toString(),
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : 'Custom workout',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? now,
      exercises: exercises,
    );
  }

  static Map<String, dynamic> _exerciseToJson(ExercisePrescription exercise) => {
        'name': exercise.name,
        'sets': exercise.sets,
        'reps': exercise.reps,
        'rest': exercise.rest,
        'equipment': exercise.equipment,
        'target': exercise.target,
        'visual_asset': exercise.visualAsset,
        'metric_label': exercise.metricLabel,
      };

  static ExercisePrescription _exerciseFromJson(Map<String, dynamic> json) {
    return ExercisePrescription(
      name: json['name']?.toString() ?? 'Exercise',
      sets: (json['sets'] as num?)?.toInt() ?? 3,
      reps: json['reps']?.toString() ?? '8–12',
      rest: json['rest']?.toString() ?? '75 sec',
      equipment: json['equipment']?.toString() ?? 'Bodyweight',
      target: json['target']?.toString() ?? 'General fitness',
      visualAsset: json['visual_asset']?.toString(),
      metricLabel: json['metric_label']?.toString(),
    );
  }
}

class CustomWorkoutStore {
  static const _baseKey = 'leanit_custom_workouts_v1';
  static const maxSavedWorkouts = 50;

  final SupabaseClient client;

  const CustomWorkoutStore(this.client);

  String get _storageKey {
    final userId = client.auth.currentUser?.id;
    return userId == null || userId.isEmpty
        ? '${_baseKey}_guest'
        : '${_baseKey}_$userId';
  }

  Future<List<CustomWorkout>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final result = <CustomWorkout>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          final workout = CustomWorkout.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (workout.exercises.isNotEmpty) result.add(workout);
        } catch (_) {}
      }
      result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return result;
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(CustomWorkout workout) async {
    final existing = await loadAll();
    final next = <CustomWorkout>[
      workout,
      ...existing.where((item) => item.id != workout.id),
    ].take(maxSavedWorkouts).toList(growable: false);
    await _write(next);
  }

  Future<void> delete(String id) async {
    final existing = await loadAll();
    await _write(
      existing.where((item) => item.id != id).toList(growable: false),
    );
  }

  Future<void> _write(List<CustomWorkout> workouts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(workouts.map((item) => item.toJson()).toList(growable: false)),
    );
  }
}
