import 'workout_engine.dart';

enum SessionStepType {
  raiseTemperature('Warm-up'),
  mobility('Mobility'),
  activation('Activation'),
  recovery('Recovery'),
  stretch('Stretch'),
  breathing('Breathing');

  final String label;
  const SessionStepType(this.label);
}

class SessionPhaseStep {
  final String name;
  final int durationSeconds;
  final String cue;
  final String target;
  final SessionStepType type;

  const SessionPhaseStep({
    required this.name,
    required this.durationSeconds,
    required this.cue,
    required this.target,
    required this.type,
  });
}

class SessionPreparationPlan {
  final List<SessionPhaseStep> warmUp;
  final List<SessionPhaseStep> coolDown;

  const SessionPreparationPlan({
    required this.warmUp,
    required this.coolDown,
  });

  int get warmUpSeconds =>
      warmUp.fold<int>(0, (sum, step) => sum + step.durationSeconds);

  int get coolDownSeconds =>
      coolDown.fold<int>(0, (sum, step) => sum + step.durationSeconds);
}

class SessionPreparationEngine {
  static SessionPreparationPlan forWorkout(GeneratedWorkout workout) {
    final fingerprint = _fingerprint(workout);

    if (_looksLikeRunning(fingerprint)) {
      return const SessionPreparationPlan(
        warmUp: [
          SessionPhaseStep(
            name: 'Easy walk or march',
            durationSeconds: 90,
            cue: 'Start easy and gradually increase your stride rhythm.',
            target: 'Whole body temperature',
            type: SessionStepType.raiseTemperature,
          ),
          SessionPhaseStep(
            name: 'Ankle rocks',
            durationSeconds: 40,
            cue: 'Drive the knee gently forward while keeping the heel down.',
            target: 'Ankles and calves',
            type: SessionStepType.mobility,
          ),
          SessionPhaseStep(
            name: 'Leg swings',
            durationSeconds: 40,
            cue: 'Use a comfortable range. Switch legs halfway through.',
            target: 'Hips and hamstrings',
            type: SessionStepType.mobility,
          ),
          SessionPhaseStep(
            name: 'March to running rhythm',
            durationSeconds: 50,
            cue: 'Tall posture, light feet and relaxed shoulders.',
            target: 'Running pattern',
            type: SessionStepType.activation,
          ),
        ],
        coolDown: [
          SessionPhaseStep(
            name: 'Easy walk',
            durationSeconds: 90,
            cue: 'Let breathing and heart rate settle gradually.',
            target: 'Whole body recovery',
            type: SessionStepType.recovery,
          ),
          SessionPhaseStep(
            name: 'Calf stretch',
            durationSeconds: 45,
            cue: 'Keep the back heel down. Switch sides halfway through.',
            target: 'Calves',
            type: SessionStepType.stretch,
          ),
          SessionPhaseStep(
            name: 'Hip flexor stretch',
            durationSeconds: 45,
            cue: 'Stay tall and gently shift the hips forward. Switch sides halfway.',
            target: 'Hip flexors',
            type: SessionStepType.stretch,
          ),
          SessionPhaseStep(
            name: 'Slow breathing',
            durationSeconds: 45,
            cue: 'Relax your shoulders and use slow, comfortable breaths.',
            target: 'Recovery',
            type: SessionStepType.breathing,
          ),
        ],
      );
    }

    if (_looksUpperBody(fingerprint) && !_looksLowerBody(fingerprint)) {
      return const SessionPreparationPlan(
        warmUp: [
          SessionPhaseStep(
            name: 'Easy march',
            durationSeconds: 60,
            cue: 'Move continuously until you feel warmer, not tired.',
            target: 'Whole body temperature',
            type: SessionStepType.raiseTemperature,
          ),
          SessionPhaseStep(
            name: 'Arm circles',
            durationSeconds: 40,
            cue: 'Start small, then gradually increase the circle size.',
            target: 'Shoulders',
            type: SessionStepType.mobility,
          ),
          SessionPhaseStep(
            name: 'Thoracic rotations',
            durationSeconds: 45,
            cue: 'Rotate through the upper back without forcing the range.',
            target: 'Upper back',
            type: SessionStepType.mobility,
          ),
          SessionPhaseStep(
            name: 'Scapular push-up or wall slide',
            durationSeconds: 45,
            cue: 'Move the shoulder blades with control and keep the neck relaxed.',
            target: 'Shoulder blades and upper back',
            type: SessionStepType.activation,
          ),
        ],
        coolDown: [
          SessionPhaseStep(
            name: 'Easy walk and shake-out',
            durationSeconds: 60,
            cue: 'Relax your grip, shoulders and breathing.',
            target: 'General recovery',
            type: SessionStepType.recovery,
          ),
          SessionPhaseStep(
            name: 'Chest stretch',
            durationSeconds: 45,
            cue: 'Use a gentle stretch; do not force the shoulder backward.',
            target: 'Chest and front shoulder',
            type: SessionStepType.stretch,
          ),
          SessionPhaseStep(
            name: 'Lat and upper-back stretch',
            durationSeconds: 45,
            cue: 'Reach long while keeping the stretch comfortable.',
            target: 'Back and shoulders',
            type: SessionStepType.stretch,
          ),
          SessionPhaseStep(
            name: 'Slow breathing',
            durationSeconds: 45,
            cue: 'Let breathing return toward normal before leaving the session.',
            target: 'Recovery',
            type: SessionStepType.breathing,
          ),
        ],
      );
    }

    if (_looksLowerBody(fingerprint) && !_looksUpperBody(fingerprint)) {
      return const SessionPreparationPlan(
        warmUp: [
          SessionPhaseStep(
            name: 'Easy march',
            durationSeconds: 60,
            cue: 'Build warmth gradually without turning the warm-up into cardio work.',
            target: 'Whole body temperature',
            type: SessionStepType.raiseTemperature,
          ),
          SessionPhaseStep(
            name: 'Ankle rocks',
            durationSeconds: 40,
            cue: 'Keep the heel down and move only through a comfortable range.',
            target: 'Ankles',
            type: SessionStepType.mobility,
          ),
          SessionPhaseStep(
            name: 'Leg swings',
            durationSeconds: 40,
            cue: 'Switch legs halfway and avoid forcing the range.',
            target: 'Hips and hamstrings',
            type: SessionStepType.mobility,
          ),
          SessionPhaseStep(
            name: 'Bodyweight squat to reach',
            durationSeconds: 45,
            cue: 'Use controlled reps and stay within a comfortable depth.',
            target: 'Quads, hips and trunk',
            type: SessionStepType.activation,
          ),
          SessionPhaseStep(
            name: 'Glute bridge',
            durationSeconds: 45,
            cue: 'Squeeze the glutes at the top without over-arching the back.',
            target: 'Glutes and hamstrings',
            type: SessionStepType.activation,
          ),
        ],
        coolDown: [
          SessionPhaseStep(
            name: 'Easy walk',
            durationSeconds: 60,
            cue: 'Keep moving gently while breathing settles.',
            target: 'General recovery',
            type: SessionStepType.recovery,
          ),
          SessionPhaseStep(
            name: 'Quad stretch',
            durationSeconds: 45,
            cue: 'Use support if needed and switch sides halfway through.',
            target: 'Quadriceps',
            type: SessionStepType.stretch,
          ),
          SessionPhaseStep(
            name: 'Hamstring or glute stretch',
            durationSeconds: 45,
            cue: 'Choose the position that feels comfortable today.',
            target: 'Posterior chain',
            type: SessionStepType.stretch,
          ),
          SessionPhaseStep(
            name: 'Slow breathing',
            durationSeconds: 45,
            cue: 'Relax and let your breathing return toward normal.',
            target: 'Recovery',
            type: SessionStepType.breathing,
          ),
        ],
      );
    }

    return const SessionPreparationPlan(
      warmUp: [
        SessionPhaseStep(
          name: 'Easy march',
          durationSeconds: 60,
          cue: 'Move continuously until you feel warmer, not fatigued.',
          target: 'Whole body temperature',
          type: SessionStepType.raiseTemperature,
        ),
        SessionPhaseStep(
          name: 'World\'s greatest stretch',
          durationSeconds: 50,
          cue: 'Move slowly and switch sides halfway through.',
          target: 'Hips, upper back and ankles',
          type: SessionStepType.mobility,
        ),
        SessionPhaseStep(
          name: 'Squat to reach',
          durationSeconds: 45,
          cue: 'Use a comfortable squat depth and reach tall at the top.',
          target: 'Lower body and trunk',
          type: SessionStepType.activation,
        ),
        SessionPhaseStep(
          name: 'Shoulder circles and wall slides',
          durationSeconds: 45,
          cue: 'Keep the movement smooth and the neck relaxed.',
          target: 'Shoulders and upper back',
          type: SessionStepType.mobility,
        ),
      ],
      coolDown: [
        SessionPhaseStep(
          name: 'Easy walk',
          durationSeconds: 60,
          cue: 'Move gently while breathing settles.',
          target: 'General recovery',
          type: SessionStepType.recovery,
        ),
        SessionPhaseStep(
          name: 'Lower-body stretch',
          durationSeconds: 45,
          cue: 'Choose a gentle quad, hamstring or hip stretch.',
          target: 'Hips and legs',
          type: SessionStepType.stretch,
        ),
        SessionPhaseStep(
          name: 'Upper-body stretch',
          durationSeconds: 45,
          cue: 'Use a gentle chest, shoulder or back stretch.',
          target: 'Upper body',
          type: SessionStepType.stretch,
        ),
        SessionPhaseStep(
          name: 'Slow breathing',
          durationSeconds: 45,
          cue: 'Finish with relaxed, comfortable breaths.',
          target: 'Recovery',
          type: SessionStepType.breathing,
        ),
      ],
    );
  }

  static String _fingerprint(GeneratedWorkout workout) {
    return <String>[
      workout.title,
      ...workout.exercises.expand(
        (exercise) => [exercise.name, exercise.target, exercise.equipment],
      ),
    ].join(' ').toLowerCase();
  }

  static bool _looksLikeRunning(String value) {
    return value.contains('run') ||
        value.contains('tempo') ||
        value.contains('run-walk') ||
        value.contains('quality run') ||
        value.contains('long easy');
  }

  static bool _looksUpperBody(String value) {
    const words = [
      'upper body',
      'push',
      'pull',
      'chest',
      'shoulder',
      'triceps',
      'biceps',
      'upper back',
      'lat pulldown',
      'row',
      'bench press',
    ];
    return words.any(value.contains);
  }

  static bool _looksLowerBody(String value) {
    const words = [
      'lower body',
      'runner strength',
      'quad',
      'glute',
      'hamstring',
      'squat',
      'lunge',
      'deadlift',
      'leg press',
      'calf',
    ];
    return words.any(value.contains);
  }
}
