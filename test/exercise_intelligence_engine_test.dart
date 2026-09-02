import 'package:fitness_app_prototype/exercise_intelligence_engine.dart';
import 'package:fitness_app_prototype/master_exercise_catalogue.dart';
import 'package:fitness_app_prototype/training_profile_context.dart';
import 'package:fitness_app_prototype/workout_duration_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    TrainingProfileContext.current = null;
  });

  test('beginner gym workout selects real master catalogue exercises', () {
    const profile = TrainingProfileContext(
      goals: ['Build Muscle'],
      mainGoal: 'Build Muscle',
      experience: 'Beginner',
      fitnessLevel: 'Low',
      activityLevel: 'Moderately active',
      sessionLength: '45 min',
      trainingTime: 'Evening',
    );
    final workout = ExerciseIntelligenceEngine.generate(
      sessionTitle: 'Full Body A',
      location: 'Gym',
      gymAccess: 'Full gym',
      sessionDuration: '45 min',
      profile: profile,
    );

    expect(workout.exercises.length, greaterThanOrEqualTo(3));
    for (final exercise in workout.exercises) {
      expect(MasterExerciseCatalogue.findByName(exercise.name), isNotNull);
      final difficulty = MasterExerciseCatalogue.inferredDifficulty(
        exercise.name,
        MasterExerciseCatalogue.findByName(exercise.name)!.exerciseType,
      );
      expect(difficulty, isNot('Advanced'));
    }
  });

  test('beginner starting load guidance uses RIR rather than invented kilograms', () {
    const profile = TrainingProfileContext(
      goals: ['Build Muscle'],
      mainGoal: 'Build Muscle',
      experience: 'Beginner',
      fitnessLevel: 'Low',
      activityLevel: 'Lightly active',
      sessionLength: '45 min',
      trainingTime: 'Morning',
    );
    final workout = ExerciseIntelligenceEngine.generate(
      sessionTitle: 'Upper Body A',
      location: 'Gym',
      gymAccess: 'Full gym',
      sessionDuration: '45 min',
      profile: profile,
    );
    final weighted = workout.exercises.firstWhere(
      (exercise) => !exercise.equipment.toLowerCase().contains('bodyweight'),
    );
    final guidance = ExerciseIntelligenceEngine.guidanceFor(weighted.name);
    expect(guidance, isNotNull);
    expect(guidance!.startingLoadGuidance.toLowerCase(), contains('reps in reserve'));
    expect(guidance.startingLoadGuidance.toLowerCase(), isNot(contains(' kg')));
    expect(guidance.alternatives, isNotEmpty);
  });

  test('60 minute session carries more usable work than 30 minute session and fits target', () {
    const profile = TrainingProfileContext(
      goals: ['Build Muscle'],
      mainGoal: 'Build Muscle',
      experience: 'Intermediate',
      fitnessLevel: 'Moderate',
      activityLevel: 'Moderately active',
      sessionLength: '60 min',
      trainingTime: 'Evening',
    );
    final short = ExerciseIntelligenceEngine.generate(
      sessionTitle: 'Upper Body A',
      location: 'Gym',
      gymAccess: 'Full gym',
      sessionDuration: '30 min',
      profile: profile,
    );
    final long = ExerciseIntelligenceEngine.generate(
      sessionTitle: 'Upper Body A',
      location: 'Gym',
      gymAccess: 'Full gym',
      sessionDuration: '60 min',
      profile: profile,
    );

    final shortEstimate = WorkoutDurationEngine.estimate(short);
    final longEstimate = WorkoutDurationEngine.estimate(long);
    expect(longEstimate.workingSeconds, greaterThanOrEqualTo(shortEstimate.workingSeconds));
    expect(shortEstimate.totalMinutes, lessThanOrEqualTo(35));
    expect(longEstimate.totalMinutes, lessThanOrEqualTo(65));
  });

  test('bodyweight-only home generation does not prescribe gym machines', () {
    const profile = TrainingProfileContext(
      goals: ['Build Muscle'],
      mainGoal: 'Build Muscle',
      experience: 'Beginner',
      fitnessLevel: 'Low',
      activityLevel: 'Lightly active',
      sessionLength: '30 min',
      trainingTime: 'Flexible',
    );
    final workout = ExerciseIntelligenceEngine.generate(
      sessionTitle: 'Full Body A',
      location: 'Home',
      homeEquipment: const <String>{},
      sessionDuration: '30 min',
      profile: profile,
    );

    expect(workout.exercises, isNotEmpty);
    for (final exercise in workout.exercises) {
      expect(exercise.equipment.toLowerCase(), isNot(contains('machine')));
      expect(exercise.equipment.toLowerCase(), contains('bodyweight'));
    }
  });
}
