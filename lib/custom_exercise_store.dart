import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise_repository.dart';

class CustomExerciseRecord {
  final String id;
  final String name;
  final String category;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> equipment;
  final String difficulty;
  final String? movementPattern;
  final List<String> locations;
  final List<String> instructions;
  final int defaultSets;
  final String defaultReps;
  final String defaultRest;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomExerciseRecord({
    required this.id,
    required this.name,
    required this.category,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.equipment,
    required this.difficulty,
    required this.movementPattern,
    required this.locations,
    required this.instructions,
    required this.defaultSets,
    required this.defaultReps,
    required this.defaultRest,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomExerciseRecord.create({
    required String name,
    required String category,
    required List<String> primaryMuscles,
    List<String> secondaryMuscles = const [],
    required List<String> equipment,
    String difficulty = 'Custom',
    String? movementPattern,
    required List<String> locations,
    List<String> instructions = const [],
    int defaultSets = 3,
    String defaultReps = '8–12',
    String defaultRest = '75 sec',
  }) {
    final now = DateTime.now();
    return CustomExerciseRecord(
      id: 'custom_${now.microsecondsSinceEpoch}_${_slug(name)}',
      name: name.trim(),
      category: category.trim(),
      primaryMuscles: _cleanList(primaryMuscles),
      secondaryMuscles: _cleanList(secondaryMuscles),
      equipment: _cleanList(equipment),
      difficulty: difficulty.trim().isEmpty ? 'Custom' : difficulty.trim(),
      movementPattern: _cleanNullable(movementPattern),
      locations: _cleanList(locations),
      instructions: _cleanList(instructions),
      defaultSets: defaultSets.clamp(1, 20),
      defaultReps: defaultReps.trim().isEmpty ? '8–12' : defaultReps.trim(),
      defaultRest: defaultRest.trim().isEmpty ? '75 sec' : defaultRest.trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  CustomExerciseRecord copyWith({
    String? name,
    String? category,
    List<String>? primaryMuscles,
    List<String>? secondaryMuscles,
    List<String>? equipment,
    String? difficulty,
    String? movementPattern,
    bool clearMovementPattern = false,
    List<String>? locations,
    List<String>? instructions,
    int? defaultSets,
    String? defaultReps,
    String? defaultRest,
  }) {
    return CustomExerciseRecord(
      id: id,
      name: name?.trim() ?? this.name,
      category: category?.trim() ?? this.category,
      primaryMuscles: _cleanList(primaryMuscles ?? this.primaryMuscles),
      secondaryMuscles: _cleanList(secondaryMuscles ?? this.secondaryMuscles),
      equipment: _cleanList(equipment ?? this.equipment),
      difficulty: difficulty?.trim() ?? this.difficulty,
      movementPattern: clearMovementPattern
          ? null
          : _cleanNullable(movementPattern ?? this.movementPattern),
      locations: _cleanList(locations ?? this.locations),
      instructions: _cleanList(instructions ?? this.instructions),
      defaultSets: (defaultSets ?? this.defaultSets).clamp(1, 20),
      defaultReps: (defaultReps ?? this.defaultReps).trim(),
      defaultRest: (defaultRest ?? this.defaultRest).trim(),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'primary_muscles': primaryMuscles,
        'secondary_muscles': secondaryMuscles,
        'equipment': equipment,
        'difficulty': difficulty,
        'movement_pattern': movementPattern,
        'locations': locations,
        'instructions': instructions,
        'default_sets': defaultSets,
        'default_reps': defaultReps,
        'default_rest': defaultRest,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory CustomExerciseRecord.fromJson(Map<String, dynamic> json) {
    List<String> strings(dynamic value) =>
        (value as List?)?.whereType<String>().toList(growable: false) ??
        const <String>[];

    return CustomExerciseRecord(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Custom exercise',
      category: json['category']?.toString() ?? 'Strength',
      primaryMuscles: strings(json['primary_muscles']),
      secondaryMuscles: strings(json['secondary_muscles']),
      equipment: strings(json['equipment']),
      difficulty: json['difficulty']?.toString() ?? 'Custom',
      movementPattern: _cleanNullable(json['movement_pattern']?.toString()),
      locations: strings(json['locations']),
      instructions: strings(json['instructions']),
      defaultSets: (json['default_sets'] as num?)?.toInt().clamp(1, 20) ?? 3,
      defaultReps: json['default_reps']?.toString() ?? '8–12',
      defaultRest: json['default_rest']?.toString() ?? '75 sec',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  OnlineExercise toOnlineExercise() {
    return OnlineExercise(
      id: id,
      name: name,
      category: category,
      primaryMuscles: primaryMuscles,
      secondaryMuscles: secondaryMuscles,
      equipment: equipment.isEmpty ? const ['Bodyweight'] : equipment,
      difficulty: difficulty,
      movementPattern: movementPattern,
      locations: locations.isEmpty ? const ['Gym'] : locations,
      instructions: instructions,
      commonMistakes: const [],
      imagePath: null,
      videoPath: null,
      maleImagePath: null,
      femaleImagePath: null,
      maleVideoPath: null,
      femaleVideoPath: null,
      maleImageReviewed: false,
      femaleImageReviewed: false,
      mediaSource: CustomExerciseStore.mediaSource,
      mediaLicense: 'User-created exercise',
      mediaReviewNotes: jsonEncode({
        'default_sets': defaultSets,
        'default_reps': defaultReps,
        'default_rest': defaultRest,
        'custom_exercise_id': id,
      }),
    );
  }

  static List<String> _cleanList(List<String> values) => values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList(growable: false);

  static String? _cleanNullable(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  static String _slug(String value) => value
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

class CustomExerciseStore {
  static const mediaSource = 'leanit-user-custom';
  static const _keyPrefix = 'leanit_custom_exercises_v1';

  final SupabaseClient client;

  const CustomExerciseStore(this.client);

  String get _key {
    final userId = client.auth.currentUser?.id ?? 'local';
    return '${_keyPrefix}_$userId';
  }

  Future<List<CustomExerciseRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    final records = <CustomExerciseRecord>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          final record = CustomExerciseRecord.fromJson(decoded);
          if (record.id.isNotEmpty && record.name.trim().isNotEmpty) {
            records.add(record);
          }
        }
      } catch (_) {
        // Ignore malformed local entries so one bad record cannot break library.
      }
    }
    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return records;
  }

  Future<void> save(CustomExerciseRecord record) async {
    final records = await load();
    final index = records.indexWhere((item) => item.id == record.id);
    if (index >= 0) {
      records[index] = record;
    } else {
      records.insert(0, record);
    }
    await _write(records);
  }

  Future<void> delete(String id) async {
    final records = await load();
    records.removeWhere((item) => item.id == id);
    await _write(records);
  }

  Future<CustomExerciseRecord?> findById(String id) async {
    final records = await load();
    for (final record in records) {
      if (record.id == id) return record;
    }
    return null;
  }

  Future<bool> nameExists(String name, {String? excludingId}) async {
    final normalized = name.trim().toLowerCase();
    final records = await load();
    return records.any(
      (record) =>
          record.id != excludingId && record.name.trim().toLowerCase() == normalized,
    );
  }

  Future<void> _write(List<CustomExerciseRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      records.map((record) => jsonEncode(record.toJson())).toList(growable: false),
    );
  }
}
