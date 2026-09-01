import 'package:fitness_app_prototype/session_preparation_engine.dart';
import 'package:fitness_app_prototype/session_step_visuals.dart';
import 'package:fitness_app_prototype/workout_engine.dart';
import 'package:flutter_test/flutter_test.dart';

ExercisePrescription exercise(
  String name,
  String target, {
  String equipment = 'Bodyweight',
}) {
  return ExercisePrescription(
    name: name,
    sets: 3,
    reps: '8–12',
    rest: '60 sec',
    equipment: equipment,
    target: target,
  );
}

void main() {
  group('SessionStepVisuals', () {
    test('maps exact guided movements to curated exercise media names', () {
      const thoracic = SessionPhaseStep(
        name: 'Thoracic rotations',
        durationSeconds: 45,
        cue: 'Rotate comfortably.',
        target: 'Upper back',
        type: SessionStepType.mobility,
      );
      const bridge = SessionPhaseStep(
        name: 'Glute bridge',
        durationSeconds: 45,
        cue: 'Squeeze the glutes.',
        target: 'Glutes',
        type: SessionStepType.activation,
      );

      expect(
        SessionStepVisuals.forStep(thoracic)?.exerciseName,
        'Thoracic Rotation',
      );
      expect(
        SessionStepVisuals.forStep(bridge)?.exerciseName,
        'Glute Bridge',
      );
    });

    test('does not invent a demonstration for an unmapped movement', () {
      const ankleRocks = SessionPhaseStep(
        name: 'Ankle rocks',
        durationSeconds: 40,
        cue: 'Move gently.',
        target: 'Ankles',
        type: SessionStepType.mobility,
      );

      expect(SessionStepVisuals.forStep(ankleRocks), isNull);
    });

    test('upper-body preparation includes mapped visual demonstrations', () {
      final plan = SessionPreparationEngine.forWorkout(
        GeneratedWorkout(
          title: 'Upper Body Strength',
          exercises: <ExercisePrescription>[
            exercise('Barbell Bench Press', 'Chest', equipment: 'Barbell + Bench'),
            exercise('Seated Cable Row', 'Back', equipment: 'Cable'),
          ],
        ),
      );

      final allSteps = <SessionPhaseStep>[...plan.warmUp, ...plan.coolDown];
      expect(SessionStepVisuals.coveredStepCount(allSteps), greaterThanOrEqualTo(3));
      expect(
        allSteps
            .where((step) => step.name == 'Thoracic rotations')
            .every((step) => SessionStepVisuals.forStep(step) != null),
        isTrue,
      );
    });

    test('lower-body preparation covers squat, bridge and recovery visuals', () {
      final plan = SessionPreparationEngine.forWorkout(
        GeneratedWorkout(
          title: 'Lower Body Strength',
          exercises: <ExercisePrescription>[
            exercise('Goblet Squat', 'Quads and glutes', equipment: 'Dumbbell'),
            exercise('Romanian Deadlift', 'Hamstrings', equipment: 'Barbell'),
          ],
        ),
      );

      final allSteps = <SessionPhaseStep>[...plan.warmUp, ...plan.coolDown];
      final mappedNames = allSteps
          .map(SessionStepVisuals.forStep)
          .whereType<SessionStepDemonstration>()
          .map((item) => item.exerciseName)
          .toSet();

      expect(mappedNames, contains('Bodyweight Squat'));
      expect(mappedNames, contains('Glute Bridge'));
      expect(mappedNames, contains('Hamstring Stretch'));
    });

    test('breathing remains a coached step rather than borrowing wrong media', () {
      const breathing = SessionPhaseStep(
        name: 'Slow breathing',
        durationSeconds: 45,
        cue: 'Breathe slowly.',
        target: 'Recovery',
        type: SessionStepType.breathing,
      );

      expect(SessionStepVisuals.forStep(breathing), isNull);
    });
  });
}
