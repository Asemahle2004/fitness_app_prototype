import 'package:fitness_app_prototype/equipment_flexibility_engine.dart';
import 'package:fitness_app_prototype/workout_engine.dart';
import 'package:flutter_test/flutter_test.dart';

ExercisePrescription _exercise(
  String name,
  String equipment, {
  String? supersetId,
}) {
  return ExercisePrescription(
    name: name,
    sets: 3,
    reps: '8–12',
    rest: '75 sec',
    equipment: equipment,
    target: 'Chest',
    supersetId: supersetId,
  );
}

void main() {
  test('equipment components separate mixed setup', () {
    expect(
      EquipmentFlexibilityEngine.components('Dumbbells + Bench'),
      containsAll({'dumbbell', 'bench'}),
    );
  });

  test('temporary occupation recommends moving later when safe work exists', () {
    final exercises = [
      _exercise('Barbell Bench Press', 'Barbell + Bench'),
      _exercise('Dumbbell Row', 'Dumbbell'),
      _exercise('Cable Fly', 'Cable'),
    ];

    final result = EquipmentFlexibilityEngine.recommend(
      issue: EquipmentIssueType.temporarilyOccupied,
      exercises: exercises,
      currentIndex: 0,
      unavailable: {'bench'},
    );

    expect(result, EquipmentSessionAction.moveLater);
  });

  test('permanent missing equipment recommends substitution', () {
    final exercises = [
      _exercise('Leg Press', 'Leg Press Machine'),
      _exercise('Dumbbell Row', 'Dumbbell'),
    ];

    final result = EquipmentFlexibilityEngine.recommend(
      issue: EquipmentIssueType.unavailableAtLocation,
      exercises: exercises,
      currentIndex: 0,
      unavailable: {'leg press machine'},
    );

    expect(result, EquipmentSessionAction.alternative);
  });

  test('move later is disabled for one member of a superset', () {
    final exercises = [
      _exercise('Barbell Bench Press', 'Barbell + Bench', supersetId: 'ss1'),
      _exercise('Row', 'Cable', supersetId: 'ss1'),
      _exercise('Curl', 'Dumbbell'),
    ];

    expect(
      EquipmentFlexibilityEngine.canMoveLater(
        exercises: exercises,
        currentIndex: 0,
        unavailable: {'bench'},
      ),
      isFalse,
    );
  });

  test('next safe exercise ignores another exercise using blocked equipment', () {
    final exercises = [
      _exercise('Bench Press', 'Barbell + Bench'),
      _exercise('Dumbbell Bench Press', 'Dumbbells + Bench'),
      _exercise('Dumbbell Row', 'Dumbbell'),
    ];

    expect(
      EquipmentFlexibilityEngine.nextSafeIndex(
        exercises: exercises,
        currentIndex: 0,
        unavailable: {'bench'},
      ),
      2,
    );
  });
}
