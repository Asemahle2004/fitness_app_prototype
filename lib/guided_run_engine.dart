enum GuidedRunPhaseType { warmUp, run, recover, coolDown }

class GuidedRunStep {
  final String label;
  final String instruction;
  final int durationSeconds;
  final GuidedRunPhaseType type;

  const GuidedRunStep({
    required this.label,
    required this.instruction,
    required this.durationSeconds,
    required this.type,
  });
}

class GuidedRunPlan {
  final String id;
  final String title;
  final String description;
  final String level;
  final List<GuidedRunStep> steps;

  const GuidedRunPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.steps,
  });

  int get totalSeconds =>
      steps.fold<int>(0, (total, step) => total + step.durationSeconds);
}

class GuidedRunProgress {
  final int stepIndex;
  final GuidedRunStep? step;
  final int secondsIntoStep;
  final int secondsRemainingInStep;
  final int totalSecondsRemaining;
  final bool complete;

  const GuidedRunProgress({
    required this.stepIndex,
    required this.step,
    required this.secondsIntoStep,
    required this.secondsRemainingInStep,
    required this.totalSecondsRemaining,
    required this.complete,
  });

  double get stepProgress {
    final current = step;
    if (current == null || current.durationSeconds <= 0) return 1;
    return (secondsIntoStep / current.durationSeconds).clamp(0, 1);
  }
}

class GuidedRunEngine {
  static const List<GuidedRunPlan> starterPlans = <GuidedRunPlan>[
    GuidedRunPlan(
      id: 'run_walk_foundation',
      title: 'Run-Walk Foundation',
      description:
          'Easy running alternated with walking recovery. A simple introduction to guided intervals.',
      level: 'Beginner',
      steps: <GuidedRunStep>[
        GuidedRunStep(
          label: 'Warm up',
          instruction: 'Walk briskly and settle into comfortable breathing.',
          durationSeconds: 300,
          type: GuidedRunPhaseType.warmUp,
        ),
        GuidedRunStep(label: 'Run 1', instruction: 'Run easy and controlled.', durationSeconds: 60, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Walk 1', instruction: 'Walk and recover.', durationSeconds: 90, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Run 2', instruction: 'Run easy and controlled.', durationSeconds: 60, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Walk 2', instruction: 'Walk and recover.', durationSeconds: 90, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Run 3', instruction: 'Run easy and controlled.', durationSeconds: 60, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Walk 3', instruction: 'Walk and recover.', durationSeconds: 90, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Run 4', instruction: 'Run easy and controlled.', durationSeconds: 60, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Walk 4', instruction: 'Walk and recover.', durationSeconds: 90, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Run 5', instruction: 'Run easy and controlled.', durationSeconds: 60, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Walk 5', instruction: 'Walk and recover.', durationSeconds: 90, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Run 6', instruction: 'Run easy and controlled.', durationSeconds: 60, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Walk 6', instruction: 'Walk and recover.', durationSeconds: 90, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Run 7', instruction: 'Run easy and controlled.', durationSeconds: 60, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Walk 7', instruction: 'Walk and recover.', durationSeconds: 90, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Run 8', instruction: 'Run easy and controlled.', durationSeconds: 60, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Walk 8', instruction: 'Walk and recover.', durationSeconds: 90, type: GuidedRunPhaseType.recover),
        GuidedRunStep(
          label: 'Cool down',
          instruction: 'Walk easily and let your breathing settle.',
          durationSeconds: 300,
          type: GuidedRunPhaseType.coolDown,
        ),
      ],
    ),
    GuidedRunPlan(
      id: 'steady_intervals',
      title: 'Steady Intervals',
      description:
          'Longer controlled running efforts with short easy recoveries.',
      level: 'Beginner / Intermediate',
      steps: <GuidedRunStep>[
        GuidedRunStep(label: 'Warm up', instruction: 'Easy walk or jog.', durationSeconds: 300, type: GuidedRunPhaseType.warmUp),
        GuidedRunStep(label: 'Steady 1', instruction: 'Run at a controlled steady effort.', durationSeconds: 120, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Easy 1', instruction: 'Walk or jog very easily.', durationSeconds: 60, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Steady 2', instruction: 'Run at a controlled steady effort.', durationSeconds: 120, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Easy 2', instruction: 'Walk or jog very easily.', durationSeconds: 60, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Steady 3', instruction: 'Run at a controlled steady effort.', durationSeconds: 120, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Easy 3', instruction: 'Walk or jog very easily.', durationSeconds: 60, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Steady 4', instruction: 'Run at a controlled steady effort.', durationSeconds: 120, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Easy 4', instruction: 'Walk or jog very easily.', durationSeconds: 60, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Steady 5', instruction: 'Run at a controlled steady effort.', durationSeconds: 120, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Easy 5', instruction: 'Walk or jog very easily.', durationSeconds: 60, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Steady 6', instruction: 'Run at a controlled steady effort.', durationSeconds: 120, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Easy 6', instruction: 'Walk or jog very easily.', durationSeconds: 60, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Cool down', instruction: 'Jog or walk easily.', durationSeconds: 300, type: GuidedRunPhaseType.coolDown),
      ],
    ),
    GuidedRunPlan(
      id: 'speed_intervals',
      title: 'Speed Intervals',
      description:
          'Short faster efforts with generous easy recovery. Keep the fast portions controlled, not all-out.',
      level: 'Intermediate',
      steps: <GuidedRunStep>[
        GuidedRunStep(label: 'Warm up', instruction: 'Easy running. Build gradually.', durationSeconds: 480, type: GuidedRunPhaseType.warmUp),
        GuidedRunStep(label: 'Fast 1', instruction: 'Run faster but stay controlled.', durationSeconds: 60, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Recover 1', instruction: 'Easy jog or walk.', durationSeconds: 120, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Fast 2', instruction: 'Run faster but stay controlled.', durationSeconds: 60, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Recover 2', instruction: 'Easy jog or walk.', durationSeconds: 120, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Fast 3', instruction: 'Run faster but stay controlled.', durationSeconds: 60, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Recover 3', instruction: 'Easy jog or walk.', durationSeconds: 120, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Fast 4', instruction: 'Run faster but stay controlled.', durationSeconds: 60, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Recover 4', instruction: 'Easy jog or walk.', durationSeconds: 120, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Fast 5', instruction: 'Run faster but stay controlled.', durationSeconds: 60, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Recover 5', instruction: 'Easy jog or walk.', durationSeconds: 120, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Fast 6', instruction: 'Run faster but stay controlled.', durationSeconds: 60, type: GuidedRunPhaseType.run),
        GuidedRunStep(label: 'Recover 6', instruction: 'Easy jog or walk.', durationSeconds: 120, type: GuidedRunPhaseType.recover),
        GuidedRunStep(label: 'Cool down', instruction: 'Run or walk very easily.', durationSeconds: 300, type: GuidedRunPhaseType.coolDown),
      ],
    ),
  ];

  static GuidedRunProgress progressFor(GuidedRunPlan plan, int elapsedSeconds) {
    final elapsed = elapsedSeconds.clamp(0, plan.totalSeconds);
    if (elapsed >= plan.totalSeconds) {
      return const GuidedRunProgress(
        stepIndex: -1,
        step: null,
        secondsIntoStep: 0,
        secondsRemainingInStep: 0,
        totalSecondsRemaining: 0,
        complete: true,
      );
    }

    var cursor = 0;
    for (var index = 0; index < plan.steps.length; index += 1) {
      final step = plan.steps[index];
      final end = cursor + step.durationSeconds;
      if (elapsed < end) {
        final into = elapsed - cursor;
        return GuidedRunProgress(
          stepIndex: index,
          step: step,
          secondsIntoStep: into,
          secondsRemainingInStep: step.durationSeconds - into,
          totalSecondsRemaining: plan.totalSeconds - elapsed,
          complete: false,
        );
      }
      cursor = end;
    }

    return const GuidedRunProgress(
      stepIndex: -1,
      step: null,
      secondsIntoStep: 0,
      secondsRemainingInStep: 0,
      totalSecondsRemaining: 0,
      complete: true,
    );
  }

  static GuidedRunStep? nextStep(GuidedRunPlan plan, GuidedRunProgress progress) {
    if (progress.complete || progress.stepIndex < 0) return null;
    final nextIndex = progress.stepIndex + 1;
    if (nextIndex >= plan.steps.length) return null;
    return plan.steps[nextIndex];
  }

  static String phaseLabel(GuidedRunPhaseType type) {
    switch (type) {
      case GuidedRunPhaseType.warmUp:
        return 'WARM UP';
      case GuidedRunPhaseType.run:
        return 'RUN';
      case GuidedRunPhaseType.recover:
        return 'RECOVER';
      case GuidedRunPhaseType.coolDown:
        return 'COOL DOWN';
    }
  }
}
