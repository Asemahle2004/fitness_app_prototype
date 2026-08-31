import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum BodyMetric {
  weight('Weight', 'kg'),
  bodyFat('Body fat', '%'),
  chest('Chest', 'cm'),
  waist('Waist', 'cm'),
  hips('Hips', 'cm'),
  arm('Arm', 'cm'),
  thigh('Thigh', 'cm');

  final String label;
  final String unit;

  const BodyMetric(this.label, this.unit);
}

class BodyProgressEntry {
  final String id;
  final DateTime recordedAt;
  final double? weightKg;
  final double? bodyFatPercent;
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? armCm;
  final double? thighCm;
  final String notes;

  const BodyProgressEntry({
    required this.id,
    required this.recordedAt,
    this.weightKg,
    this.bodyFatPercent,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.armCm,
    this.thighCm,
    this.notes = '',
  });

  factory BodyProgressEntry.create({
    required DateTime recordedAt,
    double? weightKg,
    double? bodyFatPercent,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? armCm,
    double? thighCm,
    String notes = '',
  }) {
    return BodyProgressEntry(
      id: 'body_${DateTime.now().microsecondsSinceEpoch}',
      recordedAt: recordedAt,
      weightKg: weightKg,
      bodyFatPercent: bodyFatPercent,
      chestCm: chestCm,
      waistCm: waistCm,
      hipsCm: hipsCm,
      armCm: armCm,
      thighCm: thighCm,
      notes: notes.trim(),
    );
  }

  bool get hasMeasurements =>
      weightKg != null ||
      bodyFatPercent != null ||
      chestCm != null ||
      waistCm != null ||
      hipsCm != null ||
      armCm != null ||
      thighCm != null;

  double? valueFor(BodyMetric metric) {
    switch (metric) {
      case BodyMetric.weight:
        return weightKg;
      case BodyMetric.bodyFat:
        return bodyFatPercent;
      case BodyMetric.chest:
        return chestCm;
      case BodyMetric.waist:
        return waistCm;
      case BodyMetric.hips:
        return hipsCm;
      case BodyMetric.arm:
        return armCm;
      case BodyMetric.thigh:
        return thighCm;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recorded_at': recordedAt.toIso8601String(),
        'weight_kg': weightKg,
        'body_fat_percent': bodyFatPercent,
        'chest_cm': chestCm,
        'waist_cm': waistCm,
        'hips_cm': hipsCm,
        'arm_cm': armCm,
        'thigh_cm': thighCm,
        'notes': notes,
      };

  factory BodyProgressEntry.fromJson(Map<String, dynamic> json) {
    double? number(String key) => (json[key] as num?)?.toDouble();
    return BodyProgressEntry(
      id: json['id'] as String? ??
          'body_${DateTime.now().microsecondsSinceEpoch}',
      recordedAt: DateTime.tryParse(json['recorded_at'] as String? ?? '') ??
          DateTime.now(),
      weightKg: number('weight_kg'),
      bodyFatPercent: number('body_fat_percent'),
      chestCm: number('chest_cm'),
      waistCm: number('waist_cm'),
      hipsCm: number('hips_cm'),
      armCm: number('arm_cm'),
      thighCm: number('thigh_cm'),
      notes: json['notes'] as String? ?? '',
    );
  }
}

enum ProgressPhotoAngle {
  front('Front'),
  side('Side'),
  back('Back');

  final String label;
  const ProgressPhotoAngle(this.label);
}

class ProgressPhotoRecord {
  final String id;
  final DateTime recordedAt;
  final ProgressPhotoAngle angle;
  final String localPath;
  final String notes;

  const ProgressPhotoRecord({
    required this.id,
    required this.recordedAt,
    required this.angle,
    required this.localPath,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'recorded_at': recordedAt.toIso8601String(),
        'angle': angle.name,
        'local_path': localPath,
        'notes': notes,
      };

  factory ProgressPhotoRecord.fromJson(Map<String, dynamic> json) {
    final angleName = json['angle'] as String? ?? 'front';
    final angle = ProgressPhotoAngle.values.firstWhere(
      (item) => item.name == angleName,
      orElse: () => ProgressPhotoAngle.front,
    );
    return ProgressPhotoRecord(
      id: json['id'] as String? ??
          'photo_${DateTime.now().microsecondsSinceEpoch}',
      recordedAt: DateTime.tryParse(json['recorded_at'] as String? ?? '') ??
          DateTime.now(),
      angle: angle,
      localPath: json['local_path'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }
}

class BodyProgressStore {
  static const _entryKeyPrefix = 'leanit_body_progress_v1';
  static const _photoKeyPrefix = 'leanit_progress_photos_v1';
  static const _maxEntries = 500;
  static const _maxPhotos = 120;

  String get _scope {
    try {
      return Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    } catch (_) {
      return 'guest';
    }
  }

  String get _entryKey => '${_entryKeyPrefix}_$_scope';
  String get _photoKey => '${_photoKeyPrefix}_$_scope';

  Future<List<BodyProgressEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_entryKey) ?? const <String>[];
    final entries = <BodyProgressEntry>[];
    for (final item in raw) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(item) as Map);
        final entry = BodyProgressEntry.fromJson(decoded);
        if (entry.hasMeasurements) entries.add(entry);
      } catch (_) {}
    }
    entries.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return entries;
  }

  Future<void> saveEntry(BodyProgressEntry entry) async {
    final current = await loadEntries();
    final next = <BodyProgressEntry>[
      entry,
      ...current.where((item) => item.id != entry.id),
    ]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _entryKey,
      next.take(_maxEntries).map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> deleteEntry(String id) async {
    final current = await loadEntries();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _entryKey,
      current
          .where((item) => item.id != id)
          .map((item) => jsonEncode(item.toJson()))
          .toList(),
    );
  }

  Future<List<ProgressPhotoRecord>> loadPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_photoKey) ?? const <String>[];
    final photos = <ProgressPhotoRecord>[];
    for (final item in raw) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(item) as Map);
        final photo = ProgressPhotoRecord.fromJson(decoded);
        if (photo.localPath.trim().isNotEmpty) photos.add(photo);
      } catch (_) {}
    }
    photos.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return photos;
  }

  Future<void> savePhoto(ProgressPhotoRecord photo) async {
    final current = await loadPhotos();
    final next = <ProgressPhotoRecord>[
      photo,
      ...current.where((item) => item.id != photo.id),
    ]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _photoKey,
      next.take(_maxPhotos).map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> deletePhotoMetadata(String id) async {
    final current = await loadPhotos();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _photoKey,
      current
          .where((item) => item.id != id)
          .map((item) => jsonEncode(item.toJson()))
          .toList(),
    );
  }
}
