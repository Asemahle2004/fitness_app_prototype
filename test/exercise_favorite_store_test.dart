import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_app_prototype/exercise_favorite_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('favorites persist for the same user', () async {
    const store = ExerciseFavoriteStore.forUser('user-a');

    await store.setFavorite('bench_press', true);
    await store.setFavorite('barbell_row', true);

    final restored = await store.load();
    expect(restored, containsAll(<String>['bench_press', 'barbell_row']));
  });

  test('favorites are scoped per user', () async {
    const first = ExerciseFavoriteStore.forUser('user-a');
    const second = ExerciseFavoriteStore.forUser('user-b');

    await first.setFavorite('bench_press', true);

    expect(await first.load(), contains('bench_press'));
    expect(await second.load(), isNot(contains('bench_press')));
  });

  test('toggle and remove update the saved set', () async {
    const store = ExerciseFavoriteStore.forUser(null);

    expect(await store.toggle('goblet_squat'), isTrue);
    expect(await store.load(), contains('goblet_squat'));

    expect(await store.toggle('goblet_squat'), isFalse);
    expect(await store.load(), isNot(contains('goblet_squat')));

    await store.setFavorite('plank', true);
    await store.remove('plank');
    expect(await store.load(), isEmpty);
  });
}
