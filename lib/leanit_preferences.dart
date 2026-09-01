import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LeanItPreferences {
  final bool workoutRemindersEnabled;
  final int reminderHour;
  final int reminderMinute;
  final Set<int> reminderWeekdays;
  final int preWorkoutReminderMinutes;
  final bool largeText;
  final bool reducedMotion;
  final bool highContrast;
  final bool largerTapTargets;
  final bool lowDataMode;
  final bool preloadExerciseMedia;
  final bool automaticSync;

  const LeanItPreferences({
    this.workoutRemindersEnabled = true,
    this.reminderHour = 18,
    this.reminderMinute = 0,
    this.reminderWeekdays = const {1, 2, 3, 4, 5},
    this.preWorkoutReminderMinutes = 30,
    this.largeText = false,
    this.reducedMotion = false,
    this.highContrast = false,
    this.largerTapTargets = false,
    this.lowDataMode = false,
    this.preloadExerciseMedia = true,
    this.automaticSync = true,
  });

  LeanItPreferences copyWith({
    bool? workoutRemindersEnabled,
    int? reminderHour,
    int? reminderMinute,
    Set<int>? reminderWeekdays,
    int? preWorkoutReminderMinutes,
    bool? largeText,
    bool? reducedMotion,
    bool? highContrast,
    bool? largerTapTargets,
    bool? lowDataMode,
    bool? preloadExerciseMedia,
    bool? automaticSync,
  }) {
    return LeanItPreferences(
      workoutRemindersEnabled:
          workoutRemindersEnabled ?? this.workoutRemindersEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      reminderWeekdays: reminderWeekdays ?? this.reminderWeekdays,
      preWorkoutReminderMinutes:
          preWorkoutReminderMinutes ?? this.preWorkoutReminderMinutes,
      largeText: largeText ?? this.largeText,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      highContrast: highContrast ?? this.highContrast,
      largerTapTargets: largerTapTargets ?? this.largerTapTargets,
      lowDataMode: lowDataMode ?? this.lowDataMode,
      preloadExerciseMedia: preloadExerciseMedia ?? this.preloadExerciseMedia,
      automaticSync: automaticSync ?? this.automaticSync,
    );
  }

  Map<String, dynamic> toJson() => {
        'workout_reminders_enabled': workoutRemindersEnabled,
        'reminder_hour': reminderHour,
        'reminder_minute': reminderMinute,
        'reminder_weekdays': reminderWeekdays.toList()..sort(),
        'pre_workout_reminder_minutes': preWorkoutReminderMinutes,
        'large_text': largeText,
        'reduced_motion': reducedMotion,
        'high_contrast': highContrast,
        'larger_tap_targets': largerTapTargets,
        'low_data_mode': lowDataMode,
        'preload_exercise_media': preloadExerciseMedia,
        'automatic_sync': automaticSync,
      };

  factory LeanItPreferences.fromJson(Map<String, dynamic> json) {
    Set<int> weekdays(dynamic value) {
      if (value is! List) return const {1, 2, 3, 4, 5};
      final parsed = value
          .whereType<num>()
          .map((item) => item.toInt())
          .where((item) => item >= 1 && item <= 7)
          .toSet();
      return parsed.isEmpty ? const {1, 2, 3, 4, 5} : parsed;
    }

    return LeanItPreferences(
      workoutRemindersEnabled:
          json['workout_reminders_enabled'] as bool? ?? true,
      reminderHour: ((json['reminder_hour'] as num?)?.toInt() ?? 18).clamp(0, 23),
      reminderMinute:
          ((json['reminder_minute'] as num?)?.toInt() ?? 0).clamp(0, 59),
      reminderWeekdays: weekdays(json['reminder_weekdays']),
      preWorkoutReminderMinutes:
          ((json['pre_workout_reminder_minutes'] as num?)?.toInt() ?? 30)
              .clamp(0, 180),
      largeText: json['large_text'] as bool? ?? false,
      reducedMotion: json['reduced_motion'] as bool? ?? false,
      highContrast: json['high_contrast'] as bool? ?? false,
      largerTapTargets: json['larger_tap_targets'] as bool? ?? false,
      lowDataMode: json['low_data_mode'] as bool? ?? false,
      preloadExerciseMedia: json['preload_exercise_media'] as bool? ?? true,
      automaticSync: json['automatic_sync'] as bool? ?? true,
    );
  }
}

class LeanItPreferencesStore {
  static const _prefix = 'leanit_preferences_v2';
  final String userScope;

  const LeanItPreferencesStore({required this.userScope});

  String get _key => '${_prefix}_${_safeScope(userScope)}';

  Future<LeanItPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const LeanItPreferences();
    try {
      return LeanItPreferences.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const LeanItPreferences();
    }
  }

  Future<void> save(LeanItPreferences value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(value.toJson()));
    LeanItPreferencesCache.set(value);
  }

  static String _safeScope(String value) => value.trim().isEmpty
      ? 'guest'
      : value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}

class LeanItPreferencesCache {
  LeanItPreferencesCache._();
  static LeanItPreferences _current = const LeanItPreferences();
  static LeanItPreferences get current => _current;
  static void set(LeanItPreferences value) => _current = value;

  static Future<void> refresh(String userScope) async {
    _current = await LeanItPreferencesStore(userScope: userScope).load();
  }
}

class WorkoutReminderPlanner {
  const WorkoutReminderPlanner._();

  static DateTime? nextReminder(
    LeanItPreferences preferences, {
    DateTime? now,
  }) {
    if (!preferences.workoutRemindersEnabled ||
        preferences.reminderWeekdays.isEmpty) {
      return null;
    }
    final reference = now ?? DateTime.now();
    for (var offset = 0; offset <= 7; offset += 1) {
      final day = reference.add(Duration(days: offset));
      if (!preferences.reminderWeekdays.contains(day.weekday)) continue;
      final candidate = DateTime(
        day.year,
        day.month,
        day.day,
        preferences.reminderHour,
        preferences.reminderMinute,
      );
      if (candidate.isAfter(reference)) return candidate;
    }
    return null;
  }

  static bool isReminderDue(
    LeanItPreferences preferences, {
    DateTime? now,
    Duration window = const Duration(minutes: 30),
  }) {
    if (!preferences.workoutRemindersEnabled) return false;
    final reference = now ?? DateTime.now();
    if (!preferences.reminderWeekdays.contains(reference.weekday)) return false;
    final scheduled = DateTime(
      reference.year,
      reference.month,
      reference.day,
      preferences.reminderHour,
      preferences.reminderMinute,
    );
    final difference = reference.difference(scheduled).abs();
    return difference <= window;
  }

  static String formatTime(LeanItPreferences preferences) {
    final hour = preferences.reminderHour.toString().padLeft(2, '0');
    final minute = preferences.reminderMinute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
