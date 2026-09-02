import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'programme_engine.dart';

class CustomTrainingBlock {
  final String id;
  final String name;
  final int weeks;
  final String goal;
  final List<PlannedSession> sessions;
  final bool allowLeanItAdaptation;
  final DateTime createdAt;

  const CustomTrainingBlock({
    required this.id,
    required this.name,
    required this.weeks,
    required this.goal,
    required this.sessions,
    required this.allowLeanItAdaptation,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'weeks': weeks,
        'goal': goal,
        'allow_leanit_adaptation': allowLeanItAdaptation,
        'created_at': createdAt.toIso8601String(),
        'sessions': sessions.map((session) => <String, dynamic>{
              'day': session.day,
              'title': session.title,
              'location': session.location,
              'duration': session.duration,
              'focus': session.focus,
              'intensity': session.intensity,
              'personalisation_note': session.personalisationNote,
            }).toList(growable: false),
      };

  factory CustomTrainingBlock.fromJson(Map<String, dynamic> json) {
    final raw = json['sessions'];
    final sessions = <PlannedSession>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        sessions.add(
          PlannedSession(
            day: map['day']?.toString() ?? 'Monday',
            title: map['title']?.toString() ?? 'Workout',
            location: map['location']?.toString() ?? 'Flexible',
            duration: map['duration']?.toString() ?? '45 min',
            focus: map['focus']?.toString() ?? 'General training',
            intensity: map['intensity']?.toString() ?? 'Moderate',
            personalisationNote: map['personalisation_note']?.toString() ?? '',
          ),
        );
      }
    }
    return CustomTrainingBlock(
      id: json['id']?.toString() ?? 'block_${DateTime.now().microsecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Custom Block',
      weeks: ((json['weeks'] as num?)?.toInt() ?? 4).clamp(4, 12),
      goal: json['goal']?.toString() ?? 'General Fitness',
      sessions: List<PlannedSession>.unmodifiable(sessions),
      allowLeanItAdaptation: json['allow_leanit_adaptation'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class CustomTrainingBlockStore {
  final String userScope;

  const CustomTrainingBlockStore({required this.userScope});

  static const _prefix = 'leanit_custom_training_blocks_v1';
  static const _maxBlocks = 20;

  String get _key {
    final safe = userScope.trim().isEmpty
        ? 'guest'
        : userScope.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '${_prefix}_$safe';
  }

  Future<List<CustomTrainingBlock>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    final values = <CustomTrainingBlock>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map) {
          values.add(CustomTrainingBlock.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (_) {}
    }
    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  Future<void> save(CustomTrainingBlock block) async {
    final current = await load();
    final next = <CustomTrainingBlock>[
      block,
      ...current.where((item) => item.id != block.id),
    ].take(_maxBlocks).toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      next.map((item) => jsonEncode(item.toJson())).toList(growable: false),
    );
  }

  Future<CustomTrainingBlock> create({
    required String name,
    required int weeks,
    required String goal,
    required List<PlannedSession> sessions,
    bool allowLeanItAdaptation = true,
  }) async {
    final now = DateTime.now();
    final block = CustomTrainingBlock(
      id: 'block_${now.microsecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Custom Training Block' : name.trim(),
      weeks: weeks.clamp(4, 12),
      goal: goal.trim().isEmpty ? 'General Fitness' : goal.trim(),
      sessions: List<PlannedSession>.unmodifiable(sessions),
      allowLeanItAdaptation: allowLeanItAdaptation,
      createdAt: now,
    );
    await save(block);
    return block;
  }

  Future<void> delete(String id) async {
    final next = (await load()).where((item) => item.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      next.map((item) => jsonEncode(item.toJson())).toList(growable: false),
    );
  }
}
