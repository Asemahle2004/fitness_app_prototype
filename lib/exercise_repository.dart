import 'package:supabase_flutter/supabase_flutter.dart';

class OnlineExercise {
  final String id;
  final String name;
  final String? category;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> equipment;
  final String? difficulty;
  final String? movementPattern;
  final List<String> locations;
  final List<String> instructions;
  final List<String> commonMistakes;
  final String? imagePath;
  final String? videoPath;
  final String? maleImagePath;
  final String? femaleImagePath;
  final String? maleVideoPath;
  final String? femaleVideoPath;

  const OnlineExercise({
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
    required this.commonMistakes,
    required this.imagePath,
    required this.videoPath,
    required this.maleImagePath,
    required this.femaleImagePath,
    required this.maleVideoPath,
    required this.femaleVideoPath,
  });

  factory OnlineExercise.fromMap(Map<String, dynamic> map) {
    List<String> strings(dynamic value) {
      final list = value as List?;
      if (list == null) return const [];
      return list.whereType<String>().toList(growable: false);
    }

    return OnlineExercise(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String?,
      primaryMuscles: strings(map['primary_muscles']),
      secondaryMuscles: strings(map['secondary_muscles']),
      equipment: strings(map['equipment']),
      difficulty: map['difficulty'] as String?,
      movementPattern: map['movement_pattern'] as String?,
      locations: strings(map['locations']),
      instructions: strings(map['instructions']),
      commonMistakes: strings(map['common_mistakes']),
      imagePath: map['image_path'] as String?,
      videoPath: map['video_path'] as String?,
      maleImagePath: map['male_image_path'] as String?,
      femaleImagePath: map['female_image_path'] as String?,
      maleVideoPath: map['male_video_path'] as String?,
      femaleVideoPath: map['female_video_path'] as String?,
    );
  }

  String? imageForSex(String? sex) {
    if (sex == 'Female') {
      return femaleImagePath ?? imagePath ?? maleImagePath;
    }
    if (sex == 'Male') {
      return maleImagePath ?? imagePath ?? femaleImagePath;
    }
    return imagePath ?? maleImagePath ?? femaleImagePath;
  }
}

class ExerciseRepository {
  final SupabaseClient client;
  final String mediaBucket;

  const ExerciseRepository(
    this.client, {
    this.mediaBucket = 'exercise-media',
  });

  String idFromName(String name) {
    var value = name.toLowerCase().replaceAll('&', 'and');
    value = value.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    value = value.replaceAll(RegExp(r'^_+|_+$'), '');
    return value;
  }

  Future<OnlineExercise?> fetchByName(String name) async {
    final exerciseId = idFromName(name);
    return fetchById(exerciseId);
  }

  Future<OnlineExercise?> fetchById(String exerciseId) async {
    final data = await client
        .from('exercises')
        .select()
        .eq('id', exerciseId)
        .eq('is_active', true)
        .maybeSingle();

    if (data == null) return null;
    return OnlineExercise.fromMap(data);
  }

  Future<List<OnlineExercise>> fetchAll() async {
    final data = await client
        .from('exercises')
        .select()
        .eq('is_active', true)
        .order('name');

    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(OnlineExercise.fromMap)
        .toList(growable: false);
  }

  Future<List<OnlineExercise>> searchByName(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return fetchAll();

    final data = await client
        .from('exercises')
        .select()
        .eq('is_active', true)
        .ilike('name', '%$trimmed%')
        .order('name');

    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(OnlineExercise.fromMap)
        .toList(growable: false);
  }

  String publicImageUrl(String imagePath) {
    return client.storage.from(mediaBucket).getPublicUrl(imagePath);
  }
}
