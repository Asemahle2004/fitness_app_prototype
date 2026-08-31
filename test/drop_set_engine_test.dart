import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_app_prototype/drop_set_engine.dart';
import 'package:fitness_app_prototype/workout_engine.dart';

void main() {
  const bench = ExercisePrescription(
    name: 'Dumbbell Bench Press',
    sets: 3,
    reps: '8–12',
    rest: '90 sec',
    equipment: 'Dumbbells + Bench',
    target: 'Chest, triceps',
  );

  test('configures one or more load-reduction drops', () {
    final configured = DropSetEngine.configure(
      bench,
      const DropSetConfig(drops: 2, reductionPercent: 20),
    );

    expect(configured.dropSetCount, 2);
    expect(configured.dropSetReductionPercent, 20);
    expect(DropSetEngine.badge(configured), '2 drops • -20%');
  });

  test('suggested drop weight compounds and rounds to half kilogram', () {
    expect(
      DropSetEngine.suggestedWeight(
        workingWeightKg: 30,
        reductionPercent: 20,
        dropNumber: 1,
      ),
      24,
    );
    expect(
      DropSetEngine.suggestedWeight(
        workingWeightKg: 30,
        reductionPercent: 20,
        dropNumber: 2,
      ),
      19,
    );
  });

  test('bodyweight and timed work cannot use load drop sets', () {
    const pushUp = ExercisePrescription(
      name: 'Push-Up',
      sets: 3,
      reps: '8–15',
      rest: '60 sec',
      equipment: 'Bodyweight',
      target: 'Chest',
    );
    const plank = ExercisePrescription(
      name: 'Plank',
      sets: 3,
      reps: '45 sec',
      rest: '60 sec',
      equipment: 'Bodyweight',
      target: 'Core',
      metricLabel: 'TIME',
    );

    expect(DropSetEngine.canConfigure(pushUp), isFalse);
    expect(DropSetEngine.canConfigure(plank), isFalse);
  });

  test('superset members cannot also be configured as drop sets', () {
    final paired = bench.copyWith(supersetId: 'ss_1');
    expect(DropSetEngine.canConfigure(paired), isFalse);
  });
}
