import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fitness_app_prototype/custom_exercise_store.dart';
import 'package:fitness_app_prototype/workout_editor_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient client;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = SupabaseClient('https://example.supabase.co', 'anon-key');
  });

  test('custom exercise saves and reloads locally', () async {
    final store = CustomExerciseStore(client);
    final record = CustomExerciseRecord.create(
      name: 'My Cable Press',
      category: 'Strength',
      primaryMuscles: const ['Chest'],
      secondaryMuscles: const ['Triceps'],
      equipment: const ['Cable'],
      movementPattern: 'Push',
      locations: const ['Gym'],
      instructions: const ['Set the cable at chest height.', 'Press with control.'],
      defaultSets: 4,
      defaultReps: '6–8',
      defaultRest: '120 sec',
    );

    await store.save(record);
    final loaded = await store.load();

    expect(loaded, hasLength(1));
    expect(loaded.first.name, 'My Cable Press');
    expect(loaded.first.defaultSets, 4);
    expect(loaded.first.defaultReps, '6–8');
    expect(loaded.first.defaultRest, '120 sec');
    expect(loaded.first.primaryMuscles, ['Chest']);
  });

  test('custom exercise defaults flow into workout prescription', () {
    final record = CustomExerciseRecord.create(
      name: 'Custom Hold',
      category: 'Strength',
      primaryMuscles: const ['Core'],
      equipment: const ['Bodyweight'],
      locations: const ['Home'],
      defaultSets: 2,
      defaultReps: '45 sec',
      defaultRest: '30 sec',
    );

    final prescription = WorkoutEditorMapper.fromOnlineExercise(
      record.toOnlineExercise(),
    );

    expect(prescription.sets, 2);
    expect(prescription.reps, '45 sec');
    expect(prescription.rest, '30 sec');
    expect(prescription.metricLabel, 'TIME');
    expect(prescription.target, 'Core');
  });

  test('delete removes custom exercise', () async {
    final store = CustomExerciseStore(client);
    final record = CustomExerciseRecord.create(
      name: 'Temporary Exercise',
      category: 'Other',
      primaryMuscles: const ['Core'],
      equipment: const ['Bodyweight'],
      locations: const ['Home'],
    );

    await store.save(record);
    await store.delete(record.id);

    expect(await store.load(), isEmpty);
  });
}
