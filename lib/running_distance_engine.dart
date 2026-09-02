import 'dart:math' as math;

import 'guided_run_engine.dart';

enum RunningDiscipline {
  sprint,
  longSprint,
  middleDistance,
  endurance,
  longEndurance,
}

enum RunningGoalDistance {
  m100('100 m', 100, RunningDiscipline.sprint, 8, 3),
  m200('200 m', 200, RunningDiscipline.sprint, 8, 3),
  m400('400 m', 400, RunningDiscipline.longSprint, 8, 3),
  m800('800 m', 800, RunningDiscipline.middleDistance, 8, 4),
  m1500('1500 m', 1500, RunningDiscipline.middleDistance, 8, 4),
  mile('1 Mile', 1609.344, RunningDiscipline.middleDistance, 8, 4),
  k3('3K', 3000, RunningDiscipline.endurance, 8, 4),
  k5('5K', 5000, RunningDiscipline.endurance, 8, 4),
  k10('10K', 10000, RunningDiscipline.endurance, 10, 4),
  halfMarathon('Half Marathon', 21097.5, RunningDiscipline.longEndurance, 12, 4),
  marathon('Marathon', 42195, RunningDiscipline.longEndurance, 16, 4);

  final String label;
  final double meters;
  final RunningDiscipline discipline;
  final int minimumRecommendedWeeks;
  final int recommendedDaysPerWeek;

  const RunningGoalDistance(
    this.label,
    this.meters,
    this.discipline,
    this.minimumRecommendedWeeks,
    this.recommendedDaysPerWeek,
  );

  bool get isSprint =>
      discipline == RunningDiscipline.sprint ||
      discipline == RunningDiscipline.longSprint;
}

enum RunningSessionType {
  acceleration,
  maxVelocity,
  speedEndurance,
  sprintTechnique,
  aerobicTempo,
  easy,
  recovery,
  hills,
  intervals,
  threshold,
  raceSpecific,
  longRun,
  strengthSupport,
  taper,
  rest,
}

class RunningPlanConfig {
  final RunningGoalDistance goal;
  final String level;
  final int daysPerWeek;
  final int totalWeeks;
  final double recentWeeklyKm;
  final double? benchmarkDistanceMeters;
  final double? benchmarkSeconds;
  final DateTime? targetDate;

  const RunningPlanConfig({
    required this.goal,
    this.level = 'Beginner',
    required this.daysPerWeek,
    required this.totalWeeks,
    this.recentWeeklyKm = 0,
    this.benchmarkDistanceMeters,
    this.benchmarkSeconds,
    this.targetDate,
  });
}

class RunningPlannedSession {
  final int dayIndex;
  final RunningSessionType type;
  final String title;
  final String prescription;
  final String intensity;
  final double? plannedKm;
  final int? targetPaceSecondsPerKm;
  final int? repetitions;
  final int? repetitionDistanceMeters;
  final int? recoverySeconds;
  final bool hard;
  final bool guidedCompatible;
  final List<String> notes;

  const RunningPlannedSession({
    required this.dayIndex,
    required this.type,
    required this.title,
    required this.prescription,
    required this.intensity,
    this.plannedKm,
    this.targetPaceSecondsPerKm,
    this.repetitions,
    this.repetitionDistanceMeters,
    this.recoverySeconds,
    this.hard = false,
    this.guidedCompatible = false,
    this.notes = const <String>[],
  });
}

class RunningPlanWeek {
  final int weekNumber;
  final String phase;
  final double plannedKm;
  final bool recoveryWeek;
  final bool taperWeek;
  final List<RunningPlannedSession> sessions;

  const RunningPlanWeek({
    required this.weekNumber,
    required this.phase,
    required this.plannedKm,
    required this.recoveryWeek,
    required this.taperWeek,
    required this.sessions,
  });
}

class RunningTrainingPlan {
  final RunningPlanConfig config;
  final List<RunningPlanWeek> weeks;
  final RunningPaceZones? paceZones;
  final List<String> coachingNotes;

  const RunningTrainingPlan({
    required this.config,
    required this.weeks,
    required this.paceZones,
    required this.coachingNotes,
  });
}

class RunningPaceZones {
  final int easyMinSecondsPerKm;
  final int easyMaxSecondsPerKm;
  final int steadySecondsPerKm;
  final int thresholdSecondsPerKm;
  final int intervalSecondsPerKm;
  final int benchmarkSecondsPerKm;

  const RunningPaceZones({
    required this.easyMinSecondsPerKm,
    required this.easyMaxSecondsPerKm,
    required this.steadySecondsPerKm,
    required this.thresholdSecondsPerKm,
    required this.intervalSecondsPerKm,
    required this.benchmarkSecondsPerKm,
  });
}

class RacePrediction {
  final RunningGoalDistance goal;
  final int predictedSeconds;
  final String confidence;

  const RacePrediction({
    required this.goal,
    required this.predictedSeconds,
    required this.confidence,
  });
}

class RunningWeatherAdjustment {
  final double paceMultiplier;
  final String headline;
  final List<String> notes;
  final bool preferEffortOverPace;

  const RunningWeatherAdjustment({
    required this.paceMultiplier,
    required this.headline,
    required this.notes,
    required this.preferEffortOverPace,
  });

  int adjustPace(int secondsPerKm) =>
      (secondsPerKm * paceMultiplier).round();
}

class RunningDayAdjustment {
  final bool replaceWithRecovery;
  final double volumeMultiplier;
  final bool allowHardWork;
  final String headline;
  final List<String> reasons;

  const RunningDayAdjustment({
    required this.replaceWithRecovery,
    required this.volumeMultiplier,
    required this.allowHardWork,
    required this.headline,
    required this.reasons,
  });
}

class RunningDistanceEngine {
  const RunningDistanceEngine._();

  static RunningTrainingPlan generate(RunningPlanConfig raw) {
    final days = raw.daysPerWeek.clamp(2, 7).toInt();
    final minimumWeeks = raw.goal.minimumRecommendedWeeks;
    final weeks = raw.totalWeeks.clamp(minimumWeeks, 32).toInt();
    final config = RunningPlanConfig(
      goal: raw.goal,
      level: raw.level,
      daysPerWeek: days,
      totalWeeks: weeks,
      recentWeeklyKm: math.max(0.0, raw.recentWeeklyKm),
      benchmarkDistanceMeters: raw.benchmarkDistanceMeters,
      benchmarkSeconds: raw.benchmarkSeconds,
      targetDate: raw.targetDate,
    );
    final zones = paceZones(
      distanceMeters: config.benchmarkDistanceMeters,
      seconds: config.benchmarkSeconds,
    );

    final generated = <RunningPlanWeek>[];
    var enduranceKm = _startingWeeklyKm(config);
    for (var week = 1; week <= weeks; week += 1) {
      final taper = _isTaperWeek(config.goal, week, weeks);
      final recovery = !taper && week % 4 == 0;
      final phase = _phaseFor(week, weeks, taper: taper, recovery: recovery);
      final weekSessions = config.goal.isSprint
          ? _sprintWeek(config, week, phase, recovery: recovery, taper: taper)
          : _enduranceWeek(
              config,
              week,
              phase,
              zones,
              weeklyKm: enduranceKm,
              recovery: recovery,
              taper: taper,
            );
      final plannedKm = weekSessions.fold<double>(
        0,
        (sum, item) => sum + (item.plannedKm ?? 0),
      );
      generated.add(
        RunningPlanWeek(
          weekNumber: week,
          phase: phase,
          plannedKm: plannedKm,
          recoveryWeek: recovery,
          taperWeek: taper,
          sessions: List<RunningPlannedSession>.unmodifiable(weekSessions),
        ),
      );

      if (!config.goal.isSprint && !taper) {
        if (recovery) {
          enduranceKm = math.max(_startingWeeklyKm(config), enduranceKm * 0.80);
        } else {
          final ceiling = _goalWeeklyKmCeiling(config.goal, config.level);
          enduranceKm = math.min(ceiling, enduranceKm * 1.08 + 0.5);
        }
      }
    }

    return RunningTrainingPlan(
      config: config,
      weeks: List<RunningPlanWeek>.unmodifiable(generated),
      paceZones: zones,
      coachingNotes: <String>[
        if (config.goal.isSprint)
          'Sprint quality comes before mileage: use full recoveries and stop maximal-speed work when mechanics deteriorate.'
        else
          'Most endurance running stays easy; hard sessions are separated and every fourth week reduces load.',
        'Readiness, pain, illness-like symptoms and unusual fatigue can override the calendar.',
        if (config.goal == RunningGoalDistance.marathon)
          'Marathon long runs build gradually and the final weeks taper rather than chase last-minute fitness.',
      ],
    );
  }

  static List<RunningPlannedSession> _sprintWeek(
    RunningPlanConfig config,
    int week,
    String phase, {
    required bool recovery,
    required bool taper,
  }) {
    final goal = config.goal;
    final longSprint = goal.discipline == RunningDiscipline.longSprint;
    final scale = taper ? 0.55 : (recovery ? 0.70 : 1.0);
    final accelReps = math.max(3, (6 * scale).round());
    final speedReps = math.max(3, (5 * scale).round());
    final enduranceReps = math.max(2, (4 * scale).round());
    final sessions = <RunningPlannedSession>[
      RunningPlannedSession(
        dayIndex: 1,
        type: RunningSessionType.acceleration,
        title: 'Acceleration + Starts',
        prescription: '$accelReps × ${goal == RunningGoalDistance.m100 ? 30 : 40} m accelerations',
        intensity: taper ? 'Fast, low volume' : 'Fast with full recovery',
        repetitions: accelReps,
        repetitionDistanceMeters: goal == RunningGoalDistance.m100 ? 30 : 40,
        recoverySeconds: 180,
        hard: true,
        guidedCompatible: true,
        notes: const [
          'Warm up thoroughly before fast running.',
          'Full recovery is part of sprint training, not wasted time.',
        ],
      ),
      RunningPlannedSession(
        dayIndex: 3,
        type: RunningSessionType.maxVelocity,
        title: 'Maximum Velocity Mechanics',
        prescription: '$speedReps flying repetitions with a gradual build-in',
        intensity: 'Fast and relaxed; stop before form breaks down',
        repetitions: speedReps,
        repetitionDistanceMeters: goal == RunningGoalDistance.m100 ? 60 : 80,
        recoverySeconds: 240,
        hard: true,
        guidedCompatible: true,
      ),
      RunningPlannedSession(
        dayIndex: 5,
        type: RunningSessionType.speedEndurance,
        title: longSprint ? '400 m Speed Endurance' : 'Sprint Speed Endurance',
        prescription: longSprint
            ? '$enduranceReps × 200 m controlled-fast, long recovery'
            : '$enduranceReps × ${goal == RunningGoalDistance.m100 ? 80 : 150} m',
        intensity: taper ? 'Race rhythm, reduced volume' : 'Fast, never repeated all-out failure',
        repetitions: enduranceReps,
        repetitionDistanceMeters: longSprint
            ? 200
            : (goal == RunningGoalDistance.m100 ? 80 : 150),
        recoverySeconds: longSprint ? 360 : 300,
        hard: true,
        guidedCompatible: true,
      ),
    ];

    if (config.daysPerWeek >= 4) {
      sessions.insert(
        2,
        RunningPlannedSession(
          dayIndex: 2,
          type: RunningSessionType.sprintTechnique,
          title: 'Technique + Easy Tempo',
          prescription: recovery
              ? 'Drills + 6 × 100 m relaxed tempo'
              : 'Drills + 8 × 100 m relaxed tempo',
          intensity: 'Easy to moderate',
          repetitions: recovery ? 6 : 8,
          repetitionDistanceMeters: 100,
          recoverySeconds: 60,
          hard: false,
          guidedCompatible: true,
        ),
      );
    }
    if (config.daysPerWeek >= 5) {
      sessions.add(
        const RunningPlannedSession(
          dayIndex: 6,
          type: RunningSessionType.strengthSupport,
          title: 'Sprint Strength Support',
          prescription: 'Short strength / mobility support session',
          intensity: 'Moderate; leave repetitions in reserve',
          hard: false,
        ),
      );
    }
    return sessions.take(config.daysPerWeek).toList(growable: false);
  }

  static List<RunningPlannedSession> _enduranceWeek(
    RunningPlanConfig config,
    int week,
    String phase,
    RunningPaceZones? zones, {
    required double weeklyKm,
    required bool recovery,
    required bool taper,
  }) {
    final discipline = config.goal.discipline;
    final scale = taper ? 0.62 : (recovery ? 0.78 : 1.0);
    final targetKm = math.max(6.0, weeklyKm * scale);
    final longFraction = discipline == RunningDiscipline.longEndurance ? 0.30 : 0.24;
    final longKm = math.max(3.0, targetKm * longFraction);
    final qualityKm = math.max(2.0, targetKm * 0.18);
    final remaining = math.max(2.0, targetKm - longKm - qualityKm);
    final easySessions = math.max(1, config.daysPerWeek - 2);
    final easyKm = remaining / easySessions;

    final qualityType = _qualityType(config.goal, week, taper: taper);
    final qualityTitle = switch (qualityType) {
      RunningSessionType.threshold => 'Threshold / Tempo',
      RunningSessionType.raceSpecific => 'Race-Specific Session',
      RunningSessionType.taper => 'Taper Sharpening',
      _ => 'Intervals',
    };
    final sessions = <RunningPlannedSession>[
      RunningPlannedSession(
        dayIndex: 1,
        type: RunningSessionType.easy,
        title: 'Easy Run',
        prescription: '${easyKm.toStringAsFixed(1)} km easy conversational running',
        intensity: 'Easy / conversational',
        plannedKm: easyKm,
        targetPaceSecondsPerKm: zones?.easyMinSecondsPerKm,
        hard: false,
        guidedCompatible: true,
      ),
      RunningPlannedSession(
        dayIndex: 3,
        type: qualityType,
        title: qualityTitle,
        prescription: _qualityPrescription(config.goal, qualityKm, taper: taper),
        intensity: taper ? 'Controlled sharpening' : 'Hard but controlled',
        plannedKm: qualityKm,
        targetPaceSecondsPerKm: _paceForType(zones, qualityType),
        hard: !taper,
        guidedCompatible: true,
      ),
      RunningPlannedSession(
        dayIndex: 6,
        type: taper ? RunningSessionType.taper : RunningSessionType.longRun,
        title: taper ? 'Reduced Long Run' : 'Long Run',
        prescription: '${longKm.toStringAsFixed(1)} km easy${config.goal == RunningGoalDistance.marathon && !taper ? ', finish controlled' : ''}',
        intensity: 'Easy',
        plannedKm: longKm,
        targetPaceSecondsPerKm: zones?.easyMaxSecondsPerKm,
        hard: false,
        guidedCompatible: true,
      ),
    ];

    var day = 2;
    while (sessions.length < config.daysPerWeek) {
      while (sessions.any((item) => item.dayIndex == day)) {
        day += 1;
      }
      sessions.add(
        RunningPlannedSession(
          dayIndex: day,
          type: recovery ? RunningSessionType.recovery : RunningSessionType.easy,
          title: recovery ? 'Recovery Run' : 'Easy Aerobic Run',
          prescription: '${easyKm.toStringAsFixed(1)} km very comfortable',
          intensity: recovery ? 'Very easy' : 'Easy',
          plannedKm: easyKm,
          targetPaceSecondsPerKm: zones?.easyMaxSecondsPerKm,
          hard: false,
          guidedCompatible: true,
        ),
      );
      day += 1;
    }
    sessions.sort((a, b) => a.dayIndex.compareTo(b.dayIndex));
    return sessions;
  }

  static RunningPaceZones? paceZones({
    double? distanceMeters,
    double? seconds,
  }) {
    if (distanceMeters == null ||
        seconds == null ||
        distanceMeters < 800 ||
        seconds <= 0) {
      return null;
    }
    final benchmarkPace = (seconds / (distanceMeters / 1000)).round();
    final threshold = (benchmarkPace * 1.06).round();
    final steady = (benchmarkPace * 1.16).round();
    final easyMin = (benchmarkPace * 1.22).round();
    final easyMax = (benchmarkPace * 1.42).round();
    final interval = (benchmarkPace * 0.96).round();
    return RunningPaceZones(
      easyMinSecondsPerKm: easyMin,
      easyMaxSecondsPerKm: math.max(easyMin, easyMax),
      steadySecondsPerKm: steady,
      thresholdSecondsPerKm: threshold,
      intervalSecondsPerKm: interval,
      benchmarkSecondsPerKm: benchmarkPace,
    );
  }

  static RacePrediction? predict({
    required double benchmarkDistanceMeters,
    required double benchmarkSeconds,
    required RunningGoalDistance goal,
  }) {
    if (benchmarkDistanceMeters <= 0 || benchmarkSeconds <= 0) return null;
    final ratio = goal.meters / benchmarkDistanceMeters;
    if (ratio <= 0) return null;

    final benchmarkSprint = benchmarkDistanceMeters < 800;
    if (benchmarkSprint != goal.isSprint &&
        (benchmarkDistanceMeters < 800 || goal.meters < 800)) {
      return null;
    }
    final exponent = benchmarkDistanceMeters < 800 ? 1.03 : 1.06;
    final predicted = benchmarkSeconds * math.pow(ratio, exponent).toDouble();
    final closeness = math.max(ratio, 1 / ratio);
    final confidence = closeness <= 2
        ? 'Higher'
        : (closeness <= 4 ? 'Moderate' : 'Low');
    return RacePrediction(
      goal: goal,
      predictedSeconds: predicted.round(),
      confidence: confidence,
    );
  }

  static RunningWeatherAdjustment weatherAdjustment({
    required RunningGoalDistance goal,
    required double temperatureC,
    required double humidityPercent,
  }) {
    final humidity = humidityPercent.clamp(0, 100).toDouble();
    if (goal.isSprint) {
      final hot = temperatureC >= 30;
      return RunningWeatherAdjustment(
        paceMultiplier: 1,
        headline: hot
            ? 'Use longer recovery and monitor heat stress'
            : 'Sprint pace remains effort-based',
        notes: <String>[
          if (hot) 'Increase shade, fluids and recovery between maximal efforts.',
          if (temperatureC <= 10) 'Extend the progressive warm-up before maximum-speed work.',
          'Do not convert sprint quality into a slower endurance-style pace target.',
        ],
        preferEffortOverPace: true,
      );
    }

    var penalty = 0.0;
    if (temperatureC > 18) penalty += (temperatureC - 18) * 0.004;
    if (humidity > 60) penalty += (humidity - 60) * 0.0015;
    penalty = penalty.clamp(0.0, 0.15).toDouble();
    return RunningWeatherAdjustment(
      paceMultiplier: 1 + penalty,
      headline: penalty >= 0.06
          ? 'Run by effort today, not by the original pace number'
          : (penalty > 0
              ? 'Use a small heat-adjusted pace allowance'
              : 'No heat adjustment needed'),
      notes: <String>[
        if (penalty > 0)
          'The suggested pace allowance is about ${(penalty * 100).round()}% slower for the same training purpose.',
        'Hydration, shade and symptoms matter more than hitting a pace target in difficult conditions.',
      ],
      preferEffortOverPace: penalty >= 0.06,
    );
  }

  static RunningDayAdjustment dayAdjustment({
    required int readinessScore,
    bool poorSleep = false,
    bool unusuallySore = false,
    bool highStress = false,
    bool feelsIll = false,
  }) {
    final score = readinessScore.clamp(0, 100).toInt();
    if (feelsIll || score < 35) {
      return const RunningDayAdjustment(
        replaceWithRecovery: true,
        volumeMultiplier: 0.45,
        allowHardWork: false,
        headline: 'Replace hard running with recovery',
        reasons: <String>[
          'Today’s recovery signal is too low for hard running.',
          'LeanIt will not prescribe maximal sprinting or hard intervals when you report feeling unwell.',
        ],
      );
    }
    final warnings = <String>[
      if (poorSleep) 'poor sleep',
      if (unusuallySore) 'unusual soreness',
      if (highStress) 'high stress',
    ];
    if (score < 60 || warnings.length >= 2) {
      return RunningDayAdjustment(
        replaceWithRecovery: false,
        volumeMultiplier: 0.70,
        allowHardWork: false,
        headline: 'Keep the session easy and shorter',
        reasons: <String>[
          'Readiness is $score/100.',
          if (warnings.isNotEmpty) 'Reported today: ${warnings.join(', ')}.',
        ],
      );
    }
    return RunningDayAdjustment(
      replaceWithRecovery: false,
      volumeMultiplier: score < 75 ? 0.90 : 1,
      allowHardWork: true,
      headline: score < 75
          ? 'Train normally, but keep margin'
          : 'Normal training is available',
      reasons: <String>['Readiness is $score/100 with no major recovery override.'],
    );
  }

  static GuidedRunPlan toGuidedPlan(RunningPlannedSession session) {
    final steps = <GuidedRunStep>[
      const GuidedRunStep(
        label: 'Warm up',
        instruction:
            'Build gradually. Do mobility and easy movement before the first work repetition.',
        durationSeconds: 480,
        type: GuidedRunPhaseType.warmUp,
      ),
    ];
    final reps = session.repetitions ?? _defaultTimedReps(session.type);
    final workSeconds = _workSeconds(session);
    final recovery = session.recoverySeconds ?? _defaultRecovery(session.type);
    for (var i = 1; i <= reps; i += 1) {
      steps.add(
        GuidedRunStep(
          label: '${session.title} $i',
          instruction: session.intensity,
          durationSeconds: workSeconds,
          type: GuidedRunPhaseType.run,
        ),
      );
      if (i < reps) {
        steps.add(
          GuidedRunStep(
            label: 'Recover $i',
            instruction: session.type == RunningSessionType.acceleration ||
                    session.type == RunningSessionType.maxVelocity ||
                    session.type == RunningSessionType.speedEndurance
                ? 'Recover fully. Sprint quality requires real recovery.'
                : 'Jog or walk easily before the next effort.',
            durationSeconds: recovery,
            type: GuidedRunPhaseType.recover,
          ),
        );
      }
    }
    steps.add(
      const GuidedRunStep(
        label: 'Cool down',
        instruction: 'Walk or jog easily and let breathing settle.',
        durationSeconds: 300,
        type: GuidedRunPhaseType.coolDown,
      ),
    );
    return GuidedRunPlan(
      id: 'distance_${session.type.name}_${session.dayIndex}',
      title: session.title,
      description: session.prescription,
      level: session.hard ? 'Quality session' : 'Aerobic session',
      steps: steps,
    );
  }

  static double _startingWeeklyKm(RunningPlanConfig config) {
    if (config.goal.isSprint) return 0;
    if (config.recentWeeklyKm > 0) return config.recentWeeklyKm;
    return switch (config.goal) {
      RunningGoalDistance.m800 ||
      RunningGoalDistance.m1500 ||
      RunningGoalDistance.mile => 12,
      RunningGoalDistance.k3 || RunningGoalDistance.k5 => 14,
      RunningGoalDistance.k10 => 18,
      RunningGoalDistance.halfMarathon => 22,
      RunningGoalDistance.marathon => 28,
      _ => 10,
    };
  }

  static double _goalWeeklyKmCeiling(RunningGoalDistance goal, String level) {
    final experienced = level.toLowerCase().contains('advanced') ||
        level.toLowerCase().contains('experienced');
    return switch (goal) {
      RunningGoalDistance.m800 => experienced ? 55 : 35,
      RunningGoalDistance.m1500 || RunningGoalDistance.mile =>
        experienced ? 70 : 45,
      RunningGoalDistance.k3 || RunningGoalDistance.k5 => experienced ? 80 : 50,
      RunningGoalDistance.k10 => experienced ? 95 : 60,
      RunningGoalDistance.halfMarathon => experienced ? 110 : 70,
      RunningGoalDistance.marathon => experienced ? 125 : 85,
      _ => 30,
    };
  }

  static bool _isTaperWeek(RunningGoalDistance goal, int week, int totalWeeks) {
    final remaining = totalWeeks - week;
    if (goal == RunningGoalDistance.marathon) return remaining <= 1;
    if (goal == RunningGoalDistance.halfMarathon ||
        goal.discipline == RunningDiscipline.endurance) {
      return remaining == 0;
    }
    return goal.isSprint && remaining == 0;
  }

  static String _phaseFor(
    int week,
    int totalWeeks, {
    required bool taper,
    required bool recovery,
  }) {
    if (taper) return 'Taper / sharpen';
    if (recovery) return 'Consolidate';
    final ratio = week / totalWeeks;
    if (ratio < 0.30) return 'Foundation';
    if (ratio < 0.70) return 'Build';
    return 'Race specific';
  }

  static RunningSessionType _qualityType(
    RunningGoalDistance goal,
    int week, {
    required bool taper,
  }) {
    if (taper) return RunningSessionType.taper;
    if (week % 3 == 0) return RunningSessionType.raceSpecific;
    if (goal.discipline == RunningDiscipline.middleDistance || week.isOdd) {
      return RunningSessionType.intervals;
    }
    return RunningSessionType.threshold;
  }

  static String _qualityPrescription(
    RunningGoalDistance goal,
    double qualityKm, {
    required bool taper,
  }) {
    if (taper) return 'Short race-rhythm repetitions with full control';
    if (goal.discipline == RunningDiscipline.middleDistance) {
      return goal.meters <= 1609.344
          ? '6 × 400 m controlled-fast with easy recovery'
          : '5 × 600 m controlled-fast with easy recovery';
    }
    if (goal == RunningGoalDistance.k3 || goal == RunningGoalDistance.k5) {
      return '5 × 800 m at controlled interval effort';
    }
    if (goal == RunningGoalDistance.k10) {
      return '4 × 1 km at 10K-to-threshold effort';
    }
    if (goal == RunningGoalDistance.halfMarathon) {
      return '${qualityKm.toStringAsFixed(1)} km total with sustained threshold blocks';
    }
    return '${qualityKm.toStringAsFixed(1)} km total with marathon/threshold segments';
  }

  static int? _paceForType(RunningPaceZones? zones, RunningSessionType type) {
    if (zones == null) return null;
    return switch (type) {
      RunningSessionType.threshold => zones.thresholdSecondsPerKm,
      RunningSessionType.intervals => zones.intervalSecondsPerKm,
      RunningSessionType.raceSpecific => zones.benchmarkSecondsPerKm,
      RunningSessionType.taper => zones.benchmarkSecondsPerKm,
      _ => zones.easyMinSecondsPerKm,
    };
  }

  static int _defaultTimedReps(RunningSessionType type) => switch (type) {
        RunningSessionType.easy ||
        RunningSessionType.recovery ||
        RunningSessionType.longRun => 1,
        RunningSessionType.threshold => 3,
        _ => 5,
      };

  static int _workSeconds(RunningPlannedSession session) {
    final meters = session.repetitionDistanceMeters;
    if (meters != null) {
      if (meters <= 40) return 8;
      if (meters <= 80) return 15;
      if (meters <= 150) return 28;
      if (meters <= 200) return 40;
      if (meters <= 400) return 100;
      if (meters <= 600) return 150;
      if (meters <= 800) return 210;
      return 300;
    }
    if (session.plannedKm != null && session.plannedKm! > 0) {
      final pace = session.targetPaceSecondsPerKm ?? 360;
      return math.max(300, (session.plannedKm! * pace).round());
    }
    return 60;
  }

  static int _defaultRecovery(RunningSessionType type) => switch (type) {
        RunningSessionType.acceleration => 180,
        RunningSessionType.maxVelocity => 240,
        RunningSessionType.speedEndurance => 300,
        RunningSessionType.intervals => 120,
        RunningSessionType.threshold => 90,
        _ => 60,
      };
}
