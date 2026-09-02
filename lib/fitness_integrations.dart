import 'run_tracking_store.dart';
import 'training_store.dart';

enum FitnessIntegrationProvider {
  healthConnect,
  appleHealth,
  strava,
  garmin,
  wearOs,
  appleWatch,
}

enum FitnessIntegrationStatus {
  availableLocally,
  requiresPlatformSetup,
  requiresDeveloperCredentials,
  connected,
  unavailable,
}

class FitnessIntegrationDescriptor {
  final FitnessIntegrationProvider provider;
  final String name;
  final String purpose;
  final FitnessIntegrationStatus status;
  final Set<String> capabilities;
  final String setupNote;

  const FitnessIntegrationDescriptor({
    required this.provider,
    required this.name,
    required this.purpose,
    required this.status,
    required this.capabilities,
    required this.setupNote,
  });
}

class FitnessActivityExport {
  final String id;
  final String activityType;
  final String title;
  final DateTime startedAt;
  final int durationSeconds;
  final double? distanceMeters;
  final int? completedSets;
  final Map<String, dynamic> metadata;

  const FitnessActivityExport({
    required this.id,
    required this.activityType,
    required this.title,
    required this.startedAt,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.completedSets,
    this.metadata = const <String, dynamic>{},
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'activity_type': activityType,
        'title': title,
        'started_at': startedAt.toIso8601String(),
        'duration_seconds': durationSeconds,
        'distance_meters': distanceMeters,
        'completed_sets': completedSets,
        'metadata': metadata,
      };
}

class FitnessIntegrationRegistry {
  const FitnessIntegrationRegistry._();

  static const List<FitnessIntegrationDescriptor> providers =
      <FitnessIntegrationDescriptor>[
    FitnessIntegrationDescriptor(
      provider: FitnessIntegrationProvider.healthConnect,
      name: 'Android Health Connect',
      purpose: 'Import/export workouts, runs and supported health activity data on Android.',
      status: FitnessIntegrationStatus.requiresPlatformSetup,
      capabilities: {'workout export', 'run export', 'activity import'},
      setupNote:
          'Native Health Connect permissions and store disclosures must be configured before enabling writes.',
    ),
    FitnessIntegrationDescriptor(
      provider: FitnessIntegrationProvider.appleHealth,
      name: 'Apple Health',
      purpose: 'Share workouts and running activity with the Apple health ecosystem.',
      status: FitnessIntegrationStatus.requiresPlatformSetup,
      capabilities: {'workout export', 'run export', 'activity import'},
      setupNote:
          'HealthKit entitlements and per-data-type permission descriptions are required on iOS.',
    ),
    FitnessIntegrationDescriptor(
      provider: FitnessIntegrationProvider.strava,
      name: 'Strava',
      purpose: 'Sync completed runs and selected training summaries.',
      status: FitnessIntegrationStatus.requiresDeveloperCredentials,
      capabilities: {'run export', 'activity import'},
      setupNote:
          'OAuth client credentials and redirect configuration are required. LeanIt does not pretend this is connected before those exist.',
    ),
    FitnessIntegrationDescriptor(
      provider: FitnessIntegrationProvider.garmin,
      name: 'Garmin',
      purpose: 'Future structured-run delivery and completed-activity import.',
      status: FitnessIntegrationStatus.requiresDeveloperCredentials,
      capabilities: {'structured run', 'activity import'},
      setupNote:
          'Garmin developer access and approved API credentials are required.',
    ),
    FitnessIntegrationDescriptor(
      provider: FitnessIntegrationProvider.wearOs,
      name: 'Wear OS',
      purpose: 'Future wrist controls, interval cues and workout status.',
      status: FitnessIntegrationStatus.requiresPlatformSetup,
      capabilities: {'live controls', 'interval cues'},
      setupNote: 'A companion Wear OS target is required before wrist controls can be enabled.',
    ),
    FitnessIntegrationDescriptor(
      provider: FitnessIntegrationProvider.appleWatch,
      name: 'Apple Watch',
      purpose: 'Future live workout controls and guided-run cues.',
      status: FitnessIntegrationStatus.requiresPlatformSetup,
      capabilities: {'live controls', 'interval cues'},
      setupNote: 'A watchOS companion target and Apple entitlements are required.',
    ),
  ];
}

class FitnessActivityExporter {
  const FitnessActivityExporter._();

  static FitnessActivityExport fromWorkout(WorkoutRecord workout) {
    return FitnessActivityExport(
      id: 'workout_${workout.completedAt.microsecondsSinceEpoch}',
      activityType: 'strength_training',
      title: workout.title,
      startedAt: workout.completedAt.subtract(
        Duration(seconds: workout.durationSeconds),
      ),
      durationSeconds: workout.durationSeconds,
      distanceMeters: null,
      completedSets: workout.completedSets,
      metadata: <String, dynamic>{
        'exercises': workout.exercises,
        'perceived_effort': workout.perceivedEffort,
        'session_rpe': workout.sessionRpe,
      },
    );
  }

  static FitnessActivityExport fromRun(RunRecord run) {
    return FitnessActivityExport(
      id: run.id,
      activityType: 'running',
      title: run.isGuided ? 'Guided Run' : 'Run',
      startedAt: run.startedAt,
      durationSeconds: run.durationSeconds,
      distanceMeters: run.distanceMeters,
      completedSets: null,
      metadata: <String, dynamic>{
        'source': run.source,
        'guided_plan_id': run.guidedPlanId,
        'guided_completed': run.guidedCompleted,
        'perceived_effort': run.perceivedEffort,
        'notes': run.notes,
      },
    );
  }

  static List<FitnessActivityExport> all({
    required List<WorkoutRecord> workouts,
    required List<RunRecord> runs,
  }) {
    final values = <FitnessActivityExport>[
      ...workouts.map(fromWorkout),
      ...runs.map(fromRun),
    ]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return values;
  }
}
