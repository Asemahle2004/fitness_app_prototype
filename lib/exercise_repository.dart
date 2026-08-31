import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  final bool maleImageReviewed;
  final bool femaleImageReviewed;
  final String? mediaSource;
  final String? mediaLicense;
  final String? mediaReviewNotes;

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
    required this.maleImageReviewed,
    required this.femaleImageReviewed,
    required this.mediaSource,
    required this.mediaLicense,
    required this.mediaReviewNotes,
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
      maleImageReviewed: map['male_image_reviewed'] == true,
      femaleImageReviewed: map['female_image_reviewed'] == true,
      mediaSource: map['media_source'] as String?,
      mediaLicense: map['media_license'] as String?,
      mediaReviewNotes: map['media_review_notes'] as String?,
    );
  }

  factory OnlineExercise.fromFreeExerciseDb(Map<String, dynamic> map) {
    List<String> strings(dynamic value) {
      final list = value as List?;
      if (list == null) return const [];
      return list
          .whereType<String>()
          .map(_titleCase)
          .toList(growable: false);
    }

    final rawName = map['name']?.toString().trim() ?? 'Exercise';
    final rawEquipment = map['equipment']?.toString().trim();
    final rawCategory = map['category']?.toString().trim();
    final rawForce = map['force']?.toString().trim();
    final rawMechanic = map['mechanic']?.toString().trim();
    final rawLevel = map['level']?.toString().trim();
    final images =
        (map['images'] as List?)?.whereType<String>().toList() ??
        const <String>[];

    String equipmentLabel;
    if (rawEquipment == null ||
        rawEquipment.isEmpty ||
        rawEquipment == 'body only') {
      equipmentLabel = 'Bodyweight';
    } else if (rawEquipment == 'bands') {
      equipmentLabel = 'Resistance Bands';
    } else if (rawEquipment == 'kettlebells') {
      equipmentLabel = 'Kettlebell';
    } else {
      equipmentLabel = _titleCase(rawEquipment);
    }

    final movementParts = <String>[
      if (rawForce != null && rawForce.isNotEmpty) _titleCase(rawForce),
      if (rawMechanic != null && rawMechanic.isNotEmpty)
        _titleCase(rawMechanic),
    ];

    String? imageUrl;
    if (images.isNotEmpty) {
      final base = Uri.parse(
        'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/',
      );
      imageUrl = base.resolve(images.first).toString();
    }

    return OnlineExercise(
      id: _slug(rawName),
      name: rawName,
      category: rawCategory == null ? null : _titleCase(rawCategory),
      primaryMuscles: strings(map['primaryMuscles']),
      secondaryMuscles: strings(map['secondaryMuscles']),
      equipment: [equipmentLabel],
      difficulty: rawLevel == null ? null : _titleCase(rawLevel),
      movementPattern:
          movementParts.isEmpty ? null : movementParts.join(' • '),
      locations: _locationsFor(equipmentLabel, rawCategory),
      instructions: (map['instructions'] as List?)
              ?.whereType<String>()
              .where((value) => value.trim().isNotEmpty)
              .toList(growable: false) ??
          const [],
      commonMistakes: const [],
      imagePath: imageUrl,
      videoPath: null,
      maleImagePath: null,
      femaleImagePath: null,
      maleVideoPath: null,
      femaleVideoPath: null,
      maleImageReviewed: false,
      femaleImageReviewed: false,
      mediaSource: 'yuhonas/free-exercise-db',
      mediaLicense: 'Unlicense / public-domain dedication',
      mediaReviewNotes:
          '[reference-generic] Licensed source image; technique not independently reviewed by LeanIt.',
    );
  }

  Map<String, dynamic> toCacheMap() {
    return {
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
      'common_mistakes': commonMistakes,
      'image_path': imagePath,
      'video_path': videoPath,
      'male_image_path': maleImagePath,
      'female_image_path': femaleImagePath,
      'male_video_path': maleVideoPath,
      'female_video_path': femaleVideoPath,
      'male_image_reviewed': maleImageReviewed,
      'female_image_reviewed': femaleImageReviewed,
      'media_source': mediaSource,
      'media_license': mediaLicense,
      'media_review_notes': mediaReviewNotes,
    };
  }

  /// Returns only media that has been explicitly reviewed for production use.
  /// A path existing in Storage is not enough by itself: technique and media
  /// rights must both be approved before LeanIt shows it as final media.
  ///
  /// Sex-specific reviewed media stays preferred. A licensed generic image is
  /// allowed only when media_review_notes contains the explicit
  /// [approved-generic] marker written by the import/review tooling.
  String? reviewedImageForSex(String? sex) {
    if (sex == 'Female') {
      if (femaleImageReviewed && _hasText(femaleImagePath)) {
        return femaleImagePath;
      }
      if (hasApprovedGenericImage) {
        return imagePath;
      }
      if (maleImageReviewed && _hasText(maleImagePath)) {
        return maleImagePath;
      }
      return null;
    }

    if (sex == 'Male') {
      if (maleImageReviewed && _hasText(maleImagePath)) {
        return maleImagePath;
      }
      if (hasApprovedGenericImage) {
        return imagePath;
      }
      if (femaleImageReviewed && _hasText(femaleImagePath)) {
        return femaleImagePath;
      }
      return null;
    }

    if (hasApprovedGenericImage) return imagePath;
    if (maleImageReviewed && _hasText(maleImagePath)) return maleImagePath;
    if (femaleImageReviewed && _hasText(femaleImagePath)) {
      return femaleImagePath;
    }
    return null;
  }

  bool get hasApprovedGenericImage {
    final notes = mediaReviewNotes ?? '';
    return _hasText(imagePath) && notes.contains('[approved-generic]');
  }

  bool get hasReferenceGenericImage {
    final notes = mediaReviewNotes ?? '';
    return _hasText(imagePath) && notes.contains('[reference-generic]');
  }

  bool get hasReviewedMaleImage =>
      maleImageReviewed && _hasText(maleImagePath);

  bool get hasReviewedFemaleImage =>
      femaleImageReviewed && _hasText(femaleImagePath);

  bool get hasCompleteReviewedImagePair =>
      hasReviewedMaleImage && hasReviewedFemaleImage;

  static String _slug(String value) {
    var output = value.toLowerCase().replaceAll('&', 'and');
    output = output.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return output.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static String _titleCase(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static List<String> _locationsFor(String equipment, String? category) {
    final value = equipment.toLowerCase();
    final categoryValue = category?.toLowerCase() ?? '';

    if (categoryValue == 'strongman') {
      return const ['Gym', 'Outside'];
    }
    if (value == 'bodyweight') {
      return const ['Home', 'Gym', 'Outside'];
    }
    if (value.contains('resistance band') ||
        value.contains('foam roll') ||
        value.contains('exercise ball') ||
        value.contains('medicine ball') ||
        value.contains('kettlebell') ||
        value.contains('dumbbell')) {
      return const ['Home', 'Gym'];
    }
    return const ['Gym'];
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}

class ExerciseRepository {
  final SupabaseClient client;
  final String mediaBucket;
  final int freeCatalogueLimit;

  static const String _freeCatalogueUrl =
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json';
  static const String _freeCatalogueCacheKey =
      'leanit_free_exercise_catalogue_v1';
  static const String _freeCatalogueCacheTimeKey =
      'leanit_free_exercise_catalogue_cached_at_v1';
  static const Duration _freeCatalogueCacheMaxAge = Duration(days: 7);
  static Future<List<OnlineExercise>>? _freeCatalogueCache;

  const ExerciseRepository(
    this.client, {
    this.mediaBucket = 'exercise-media',
    this.freeCatalogueLimit = 300,
  });

  String idFromName(String name) {
    var value = name.toLowerCase().replaceAll('&', 'and');
    value = value.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    value = value.replaceAll(RegExp(r'^_+|_+$'), '');
    return value;
  }

  Future<OnlineExercise?> fetchByName(String name) async {
    final exerciseId = idFromName(name);
    final byId = await fetchById(exerciseId);
    if (byId != null) return byId;

    final lower = name.trim().toLowerCase();
    final catalogue = await _freeCatalogueSafely();
    for (final exercise in catalogue) {
      if (exercise.name.toLowerCase() == lower) return exercise;
    }
    return null;
  }

  Future<OnlineExercise?> fetchById(String exerciseId) async {
    try {
      final data = await client
          .from('exercises')
          .select()
          .eq('id', exerciseId)
          .eq('is_active', true)
          .maybeSingle();

      if (data != null) return OnlineExercise.fromMap(data);
    } catch (_) {
      // Fall through to the cached/free catalogue. This keeps the exercise
      // library useful when Supabase is temporarily unavailable.
    }

    final catalogue = await _freeCatalogueSafely();
    for (final exercise in catalogue) {
      if (exercise.id == exerciseId) return exercise;
    }
    return null;
  }

  Future<List<OnlineExercise>> fetchAll() async {
    final merged = <String, OnlineExercise>{};

    final freeCatalogue = await _freeCatalogueSafely();
    for (final exercise in freeCatalogue.take(freeCatalogueLimit)) {
      merged[exercise.id] = exercise;
    }

    try {
      final data = await client
          .from('exercises')
          .select()
          .eq('is_active', true)
          .order('name');

      for (final row in (data as List).whereType<Map<String, dynamic>>()) {
        final exercise = OnlineExercise.fromMap(row);
        // LeanIt/Supabase records win over the public fallback record.
        merged[exercise.id] = exercise;
      }
    } catch (_) {
      // The cached/free catalogue remains available as the fallback.
    }

    final result = merged.values.toList(growable: false)
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    return result;
  }

  Future<List<OnlineExercise>> searchByName(String query) async {
    final trimmed = query.trim().toLowerCase();
    final all = await fetchAll();
    if (trimmed.isEmpty) return all;

    return all.where((exercise) {
      return exercise.name.toLowerCase().contains(trimmed) ||
          (exercise.category ?? '').toLowerCase().contains(trimmed) ||
          exercise.primaryMuscles
              .any((muscle) => muscle.toLowerCase().contains(trimmed)) ||
          exercise.equipment
              .any((item) => item.toLowerCase().contains(trimmed));
    }).toList(growable: false);
  }

  Future<Map<String, int>> fetchMediaCoverage() async {
    try {
      final data =
          await client.from('exercise_media_coverage').select().single();
      int number(String key) => (data[key] as num?)?.toInt() ?? 0;
      return {
        'active': number('active_exercises'),
        'male': number('male_images'),
        'female': number('female_images'),
        'maleReviewed': number('male_reviewed'),
        'femaleReviewed': number('female_reviewed'),
        'fullyPublishable': number('fully_publishable_exercises'),
      };
    } catch (_) {
      final all = await fetchAll();
      return {
        'active': all.length,
        'male': all.where((e) => e.maleImagePath != null).length,
        'female': all.where((e) => e.femaleImagePath != null).length,
        'maleReviewed': all.where((e) => e.hasReviewedMaleImage).length,
        'femaleReviewed': all.where((e) => e.hasReviewedFemaleImage).length,
        'fullyPublishable':
            all.where((e) => e.hasCompleteReviewedImagePair).length,
      };
    }
  }

  String publicImageUrl(String imagePath) {
    final value = imagePath.trim();
    if (value.startsWith('https://') || value.startsWith('http://')) {
      return value;
    }
    return client.storage.from(mediaBucket).getPublicUrl(value);
  }

  Future<Uint8List> downloadImage(String imagePath) async {
    final value = imagePath.trim();
    if (value.startsWith('https://') || value.startsWith('http://')) {
      final response = await http.get(Uri.parse(value));
      if (response.statusCode != 200) {
        throw StateError(
          'Could not download exercise image (${response.statusCode}).',
        );
      }
      return response.bodyBytes;
    }
    return client.storage.from(mediaBucket).download(value);
  }

  Future<List<OnlineExercise>> _freeCatalogueSafely() async {
    try {
      return await _freeCatalogue();
    } catch (_) {
      return const <OnlineExercise>[];
    }
  }

  Future<List<OnlineExercise>> _freeCatalogue() {
    return _freeCatalogueCache ??= _loadFreeCatalogue();
  }

  Future<List<OnlineExercise>> _loadFreeCatalogue() async {
    final preferences = await SharedPreferences.getInstance();
    final cached = _readCachedCatalogue(preferences);

    if (cached.isNotEmpty) {
      final cachedAtMillis =
          preferences.getInt(_freeCatalogueCacheTimeKey) ?? 0;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMillis);
      final isStale = cachedAtMillis == 0 ||
          DateTime.now().difference(cachedAt) > _freeCatalogueCacheMaxAge;

      if (isStale) {
        unawaited(
          _refreshFreeCatalogue(preferences).catchError(
            (_) => cached,
          ),
        );
      }

      return cached;
    }

    return _refreshFreeCatalogue(preferences);
  }

  List<OnlineExercise> _readCachedCatalogue(
    SharedPreferences preferences,
  ) {
    final raw = preferences.getString(_freeCatalogueCacheKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <OnlineExercise>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <OnlineExercise>[];

      final exercises = <OnlineExercise>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        exercises.add(
          OnlineExercise.fromMap(Map<String, dynamic>.from(item)),
        );
      }
      exercises.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return exercises;
    } catch (_) {
      return const <OnlineExercise>[];
    }
  }

  Future<List<OnlineExercise>> _refreshFreeCatalogue(
    SharedPreferences preferences,
  ) async {
    final exercises = await _fetchFreeCatalogueFromNetwork();
    final cacheJson = jsonEncode(
      exercises.map((exercise) => exercise.toCacheMap()).toList(),
    );

    await preferences.setString(_freeCatalogueCacheKey, cacheJson);
    await preferences.setInt(
      _freeCatalogueCacheTimeKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    return exercises;
  }

  Future<List<OnlineExercise>> _fetchFreeCatalogueFromNetwork() async {
    final response = await http
        .get(Uri.parse(_freeCatalogueUrl))
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw StateError(
        'Could not load free exercise catalogue (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw const FormatException(
        'Free exercise catalogue is not a JSON list.',
      );
    }

    final exercises = <OnlineExercise>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      exercises.add(
        OnlineExercise.fromFreeExerciseDb(
          Map<String, dynamic>.from(item),
        ),
      );
    }

    exercises.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return exercises;
  }
}
