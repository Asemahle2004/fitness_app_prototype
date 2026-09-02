import 'package:fitness_app_prototype/run_location_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('run location settings', () {
    test('Android uses a foreground notification for active run tracking', () {
      final settings = buildRunLocationSettings(
        platform: TargetPlatform.android,
        isWeb: false,
      );

      expect(settings, isA<AndroidSettings>());
      final android = settings as AndroidSettings;
      expect(android.accuracy, LocationAccuracy.high);
      expect(android.distanceFilter, 5);
      expect(android.intervalDuration, const Duration(seconds: 2));
      expect(android.foregroundNotificationConfig, isNotNull);
      expect(android.foregroundNotificationConfig!.enableWakeLock, isTrue);
    });

    test('non-Android platforms keep the ordinary location stream', () {
      final settings = buildRunLocationSettings(
        platform: TargetPlatform.iOS,
        isWeb: false,
      );

      expect(settings, isNot(isA<AndroidSettings>()));
      expect(settings.accuracy, LocationAccuracy.high);
      expect(settings.distanceFilter, 5);
    });

    test('web never creates an Android foreground service configuration', () {
      final settings = buildRunLocationSettings(
        platform: TargetPlatform.android,
        isWeb: true,
      );

      expect(settings, isNot(isA<AndroidSettings>()));
    });
  });
}
