import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fitness_app_prototype/custom_workout_store.dart';
import 'package:fitness_app_prototype/workout_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ExercisePrescription benchPress() => const ExercisePrescription(
        name: 'Dumbbell Bench Press',
        sets: 4,
        reps: '8–10',
        rest: '90 sec',
        equipment: 'Dumbbells + Bench',
        target: 'Chest, triceps',
      );

  test('custom workout JSON preserves prescriptions', () {
    final created = DateTime.utc(2026, 8, 31, 18);
    final workout = CustomWorkout(
      id: 'chest-day',
      name: 'My Chest Day',
      createdAt: created,
      updatedAt: created,
      exercises: [benchPress()],
    );

    final decoded = CustomWorkout.fromJson(workout.toJson());

    expect(decoded.id, 'chest-day');
    expect(decoded.name, 'My Chest Day');
    expect(decoded.exercises, hasLength(1));
    expect(decoded.exercises.first.name, 'Dumbbell Bench Press');
    expect(decoded.exercises.first.sets, 4);
    expect(decoded.exercises.first.reps, '8–10');
    expect(decoded.exercises.first.rest, '90 sec');
    expect(decoded.generatedWorkout.title, 'My Chest Day');
  });

  test('store saves, updates and deletes custom workouts locally', () async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'public-anon-test-key',
    );
    final store = CustomWorkoutStore(client);
    final created = DateTime.utc(2026, 8, 31, 18);
    final original = CustomWorkout(
      id: 'home-day',
      name: 'Home Day',
      createdAt: created,
      updatedAt: created,
      exercises: [benchPress()],
    );

    await store.save(original);
    var loaded = await store.loadAll();
    expect(loaded, hasLength(1));
    expect(loaded.first.name, 'Home Day');

    final updated = original.copyWith(
      name: 'Home Strength',
      updatedAt: created.add(const Duration(minutes: 5)),
    );
    await store.save(updated);
    loaded = await store.loadAll();
    expect(loaded, hasLength(1));
    expect(loaded.first.name, 'Home Strength');

    await store.delete('home-day');
    loaded = await store.loadAll();
    expect(loaded, isEmpty);
  });
}
