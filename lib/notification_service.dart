import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'app_health.dart';
import 'leanit_preferences.dart';

class LeanItNotificationService {
  LeanItNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final local = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(local.identifier));
      } catch (_) {
        // The in-app reminder planner remains available even when a platform
        // cannot report a named local timezone.
      }

      const android = AndroidInitializationSettings('ic_stat_leanit');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
      );
      _initialized = true;
    } catch (error) {
      await AppErrorStore.record('Notification initialization', error);
    }
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb) {
      // Web keeps the in-app reminder planner. Browsers do not provide the
      // same reliable future recurring delivery semantics as mobile here.
      return true;
    }

    await initialize();
    try {
      final android = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      if (android != null) return android;

      final ios = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      if (ios != null) return ios;

      final macos = await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return macos ?? true;
    } catch (error) {
      await AppErrorStore.record('Notification permission', error);
      return false;
    }
  }

  static Future<void> apply(LeanItPreferences preferences) async {
    if (kIsWeb) return;
    await initialize();
    if (!_initialized) return;

    try {
      for (var id = 4101; id <= 4107; id += 1) {
        await _plugin.cancel(id: id);
      }
      if (!preferences.workoutRemindersEnabled) return;

      // Permission is requested only after the member explicitly enables the
      // reminder toggle. Merely opening LeanIt never triggers the prompt.
      final granted = await requestPermission();
      if (!granted) return;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'leanit_workout_reminders',
          'Workout reminders',
          channelDescription:
              'Reminders for planned LeanIt training sessions and check-ins.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      );

      final days = preferences.reminderWeekdays.toList()..sort();
      for (final weekday in days) {
        final scheduled = _nextWeekdayTime(
          weekday,
          preferences.reminderHour,
          preferences.reminderMinute,
        );
        await _plugin.zonedSchedule(
          id: 4100 + weekday,
          title: 'LeanIt training reminder',
          body: 'Check today’s adaptive session and readiness before you train.',
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'leanit://today',
        );
      }
    } catch (error) {
      await AppErrorStore.record('Workout reminder scheduling', error);
    }
  }

  static tz.TZDateTime _nextWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    var delta = (weekday - scheduled.weekday) % 7;
    if (delta == 0 && !scheduled.isAfter(now)) delta = 7;
    scheduled = scheduled.add(Duration(days: delta));
    return scheduled;
  }
}
