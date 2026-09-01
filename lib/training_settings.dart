import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum UnitSystem { metric, imperial }

class TrainingSettings {
  final UnitSystem unitSystem;
  final bool soundCues;
  final bool hapticCues;
  final bool countdownCues;

  const TrainingSettings({
    this.unitSystem = UnitSystem.metric,
    this.soundCues = true,
    this.hapticCues = true,
    this.countdownCues = true,
  });

  bool get isMetric => unitSystem == UnitSystem.metric;
  String get weightUnit => isMetric ? 'kg' : 'lb';
  String get distanceUnit => isMetric ? 'km' : 'mi';
  String get heightUnit => isMetric ? 'cm' : 'ft/in';
  String get paceUnit => isMetric ? '/km' : '/mi';

  TrainingSettings copyWith({
    UnitSystem? unitSystem,
    bool? soundCues,
    bool? hapticCues,
    bool? countdownCues,
  }) {
    return TrainingSettings(
      unitSystem: unitSystem ?? this.unitSystem,
      soundCues: soundCues ?? this.soundCues,
      hapticCues: hapticCues ?? this.hapticCues,
      countdownCues: countdownCues ?? this.countdownCues,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'unit_system': unitSystem.name,
        'sound_cues': soundCues,
        'haptic_cues': hapticCues,
        'countdown_cues': countdownCues,
      };

  factory TrainingSettings.fromJson(Map<String, dynamic> json) {
    return TrainingSettings(
      unitSystem: json['unit_system'] == 'imperial'
          ? UnitSystem.imperial
          : UnitSystem.metric,
      soundCues: json['sound_cues'] as bool? ?? true,
      hapticCues: json['haptic_cues'] as bool? ?? true,
      countdownCues: json['countdown_cues'] as bool? ?? true,
    );
  }
}

class TrainingSettingsStore {
  static const _baseKey = 'leanit_training_settings_v1';
  final String userScope;

  const TrainingSettingsStore({required this.userScope});

  String get _key {
    final safe = userScope.trim().isEmpty
        ? 'guest'
        : userScope.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '${_baseKey}_$safe';
  }

  Future<TrainingSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const TrainingSettings();
    try {
      return TrainingSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const TrainingSettings();
    }
  }

  Future<void> save(TrainingSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
