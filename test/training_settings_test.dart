import 'package:fitness_app_prototype/training_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('defaults to metric with guided cues enabled', () async {
    const store = TrainingSettingsStore(userScope: 'tester');
    final settings = await store.load();

    expect(settings.unitSystem, UnitSystem.metric);
    expect(settings.soundCues, isTrue);
    expect(settings.hapticCues, isTrue);
    expect(settings.countdownCues, isTrue);
  });

  test('persists imperial and cue preferences per user', () async {
    const first = TrainingSettingsStore(userScope: 'user-a');
    const second = TrainingSettingsStore(userScope: 'user-b');

    await first.save(
      const TrainingSettings(
        unitSystem: UnitSystem.imperial,
        soundCues: false,
        hapticCues: true,
        countdownCues: false,
      ),
    );

    final firstLoaded = await first.load();
    final secondLoaded = await second.load();

    expect(firstLoaded.unitSystem, UnitSystem.imperial);
    expect(firstLoaded.soundCues, isFalse);
    expect(firstLoaded.countdownCues, isFalse);
    expect(secondLoaded.unitSystem, UnitSystem.metric);
  });

  test('copyWith changes one preference without resetting the others', () {
    const base = TrainingSettings(
      unitSystem: UnitSystem.imperial,
      soundCues: false,
      hapticCues: false,
      countdownCues: true,
    );

    final changed = base.copyWith(hapticCues: true);

    expect(changed.unitSystem, UnitSystem.imperial);
    expect(changed.soundCues, isFalse);
    expect(changed.hapticCues, isTrue);
    expect(changed.countdownCues, isTrue);
  });
}
