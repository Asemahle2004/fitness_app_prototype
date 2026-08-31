import 'package:fitness_app_prototype/body_progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('body measurements save and reload locally', () async {
    final store = BodyProgressStore();
    final saved = BodyProgressEntry(
      id: 'body_test',
      recordedAt: DateTime(2026, 8, 31, 8),
      weightKg: 78.5,
      bodyFatPercent: 18.2,
      chestCm: 101,
      waistCm: 84,
      hipsCm: 98,
      armCm: 35,
      thighCm: 58,
      notes: 'Morning check-in',
    );

    await store.saveEntry(saved);
    final loaded = await store.loadEntries();

    expect(loaded.length, 1);
    expect(loaded.single.id, 'body_test');
    expect(loaded.single.weightKg, 78.5);
    expect(loaded.single.waistCm, 84);
    expect(loaded.single.notes, 'Morning check-in');
  });

  test('saving same id replaces existing measurement record', () async {
    final store = BodyProgressStore();
    await store.saveEntry(
      BodyProgressEntry(
        id: 'same',
        recordedAt: DateTime(2026, 8, 1),
        weightKg: 80,
      ),
    );
    await store.saveEntry(
      BodyProgressEntry(
        id: 'same',
        recordedAt: DateTime(2026, 8, 2),
        weightKg: 79,
      ),
    );

    final loaded = await store.loadEntries();
    expect(loaded.length, 1);
    expect(loaded.single.weightKg, 79);
  });

  test('delete removes a saved body measurement', () async {
    final store = BodyProgressStore();
    await store.saveEntry(
      BodyProgressEntry(
        id: 'remove_me',
        recordedAt: DateTime(2026, 8, 1),
        waistCm: 90,
      ),
    );

    await store.deleteEntry('remove_me');
    expect(await store.loadEntries(), isEmpty);
  });

  test('progress photo metadata persists without storing image bytes in prefs', () async {
    final store = BodyProgressStore();
    final photo = ProgressPhotoRecord(
      id: 'photo_test',
      recordedAt: DateTime(2026, 8, 31),
      angle: ProgressPhotoAngle.side,
      localPath: '/leanit/photos/photo_test.jpg',
    );

    await store.savePhoto(photo);
    final loaded = await store.loadPhotos();

    expect(loaded.length, 1);
    expect(loaded.single.angle, ProgressPhotoAngle.side);
    expect(loaded.single.localPath, '/leanit/photos/photo_test.jpg');

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final photoKey = keys.firstWhere((key) => key.startsWith('leanit_progress_photos_v1'));
    final raw = prefs.getStringList(photoKey)!.single;
    expect(raw, contains('photo_test.jpg'));
    expect(raw.length, lessThan(1000));
  });
}
