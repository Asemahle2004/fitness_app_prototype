import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Location configuration for an active LeanIt run.
///
/// On Android the foreground notification makes geolocator promote the
/// location stream to a foreground service. This lets an explicitly-started
/// run continue when the user presses Home or turns the display off, while a
/// visible system notification keeps the tracking state transparent.
LocationSettings buildRunLocationSettings({
  TargetPlatform? platform,
  bool? isWeb,
}) {
  final resolvedPlatform = platform ?? defaultTargetPlatform;
  final resolvedWeb = isWeb ?? kIsWeb;

  if (!resolvedWeb && resolvedPlatform == TargetPlatform.android) {
    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
      intervalDuration: const Duration(seconds: 2),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'LeanIt run in progress',
        notificationText:
            'LeanIt is tracking your run. Tap the notification to return.',
        enableWakeLock: true,
      ),
    );
  }

  return const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );
}
