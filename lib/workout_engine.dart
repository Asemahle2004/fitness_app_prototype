class ExercisePrescription {
  final String name;
  final int sets;
  final String reps;
  final String rest;
  final String equipment;
  final String target;
  final String? visualAsset;

  const ExercisePrescription({
    required this.name,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.equipment,
    required this.target,
    this.visualAsset,
  });
}

class GeneratedWorkout {
  final String title;
  final List<ExercisePrescription> exercises;

  const GeneratedWorkout({required this.title, required this.exercises});
}

class WorkoutEngine {
  static GeneratedWorkout generate({
    required String sessionTitle,
    required String location,
  }) {
    if (location == 'Home') {
      return _homeWorkout(sessionTitle);
    }

    return _gymWorkout(sessionTitle);
  }

  static GeneratedWorkout _gymWorkout(String title) {
    switch (title) {
      case 'Full Body':
      case 'Full Body A':
      case 'Full Body B':
      case 'Full Body C':
        return GeneratedWorkout(
          title: title,
          exercises: const [
            ExercisePrescription(
              name: 'Goblet Squat',
              sets: 3,
              reps: '8–12',
              rest: '90 sec',
              equipment: 'Dumbbell',
              target: 'Quads, glutes',
            ),
            ExercisePrescription(
              name: 'Dumbbell Bench Press',
              sets: 3,
              reps: '8–12',
              rest: '90 sec',
              equipment: 'Dumbbells + Bench',
              target: 'Chest, triceps',
              visualAsset: 'assets/exercises/dumbbell_bench_press.png',
            ),
            ExercisePrescription(
              name: 'Lat Pulldown',
              sets: 3,
              reps: '8–12',
              rest: '90 sec',
              equipment: 'Lat Pulldown Machine',
              target: 'Back, biceps',
            ),
            ExercisePrescription(
              name: 'Romanian Deadlift',
              sets: 3,
              reps: '8–12',
              rest: '90 sec',
              equipment: 'Barbell or Dumbbells',
              target: 'Hamstrings, glutes',
            ),
            ExercisePrescription(
              name: 'Seated Dumbbell Shoulder Press',
              sets: 2,
              reps: '8–12',
              rest: '90 sec',
              equipment: 'Dumbbells + Bench',
              target: 'Shoulders, triceps',
            ),
            ExercisePrescription(
              name: 'Plank',
              sets: 3,
              reps: '30–60 sec',
              rest: '60 sec',
              equipment: 'Bodyweight',
              target: 'Core',
            ),
          ],
        );
      case 'Upper Body A':
        return const GeneratedWorkout(
          title: 'Upper Body A',
          exercises: [
            ExercisePrescription(
              name: 'Dumbbell Bench Press',
              sets: 3,
              reps: '8–12',
              rest: '90 sec',
              equipment: 'Dumbbells + Bench',
              target: 'Chest, triceps',
              visualAsset: 'assets/exercises/dumbbell_bench_press.png',
            ),
            ExercisePrescription(
              name: 'Lat Pulldown',
              sets: 3,
              reps: '8–12',
              rest: '90 sec',
              equipment: 'Lat Pulldown Machine',
              target: 'Back, biceps',
            ),
            ExercisePrescription(
              name: 'Seated Dumbbell Shoulder Press',
              sets: 3,
              reps: '8–12',
              rest: '90 sec',
              equipment: 'Dumbbells + Bench',
              target: 'Shoulders, triceps',
            ),
            ExercisePrescription(
              name: 'Seated Cable Row',
              sets: 3,
              reps: '8–12',
              rest: '90 sec',
              equipment: 'Cable Machine',
              target: 'Back, biceps',
            ),
            ExercisePrescription(
              name: 'Dumbbell Curl',
              sets: 2,
              reps: '10–15',
              rest: '60 sec',
              equipment: 'Dumbbells',
              target: 'Biceps',
            ),
            ExercisePrescription(
              name: 'Triceps Pushdown',
              sets: 2,
              reps: '10–15',
              rest: '60 sec',
              equipment: 'Cable Machine',
              target: 'Triceps',
            ),
          ],
        );

      case 'Lower Body A':
        return const GeneratedWorkout(
          title: 'Lower Body A',
          exercises: [
            ExercisePrescription(
              name: 'Goblet Squat',
              sets: 3,
              reps: '8–12',
              rest: '90 sec',
              equipment: 'Dumbbell',
              target: 'Quads, glutes',
            ),
            ExercisePrescription(
              name: 'Romanian Deadlift',
              sets: 3,
              reps: '8–12',
              rest: '90 sec',
              equipment: 'Barbell or Dumbbells',
              target: 'Hamstrings, glutes',
            ),
            ExercisePrescription(
              name: 'Leg Press',
              sets: 3,
              reps: '10–15',
              rest: '90 sec',
              equipment: 'Leg Press Machine',
              target: 'Quads, glutes',
            ),
            ExercisePrescription(
              name: 'Leg Curl',
              sets: 3,
              reps: '10–15',
              rest: '75 sec',
              equipment: 'Leg Curl Machine',
              target: 'Hamstrings',
            ),
            ExercisePrescription(
              name: 'Calf Raise',
              sets: 3,
              reps: '10–15',
              rest: '60 sec',
              equipment: 'Machine or Free Weight',
              target: 'Calves',
            ),
            ExercisePrescription(
              name: 'Plank',
              sets: 3,
              reps: '30–60 sec',
              rest: '60 sec',
              equipment: 'Bodyweight',
              target: 'Core',
            ),
          ],
        );

      case 'Upper Body B':
        return const GeneratedWorkout(
          title: 'Upper Body B',
          exercises: [
            ExercisePrescription(
              name: 'Incline Dumbbell Press',
              sets: 3,
              reps: '8–12',
              rest: '90 sec',
              equipment: 'Dumbbells + Bench',
              target: 'Chest, shoulders',
            ),
            ExercisePrescription(
              name: 'One-Arm Dumbbell Row',
              sets: 3,
              reps: '8–12',
              rest: '90 sec',
              equipment: 'Dumbbell + Bench',
              target: 'Back, biceps',
            ),
            ExercisePrescription(
              name: 'Machine Chest Press',
              sets: 3,
              reps: '8–12',
              rest: '90 sec',
              equipment: 'Chest Press Machine',
              target: 'Chest, triceps',
            ),
            ExercisePrescription(
              name: 'Lat Pulldown',
              sets: 3,
              reps: '8–12',
              rest: '90 sec',
              equipment: 'Lat Pulldown Machine',
              target: 'Back, biceps',
            ),
            ExercisePrescription(
              name: 'Lateral Raise',
              sets: 2,
              reps: '12–15',
              rest: '60 sec',
              equipment: 'Dumbbells',
              target: 'Shoulders',
            ),
            ExercisePrescription(
              name: 'Hammer Curl',
              sets: 2,
              reps: '10–15',
              rest: '60 sec',
              equipment: 'Dumbbells',
              target: 'Biceps',
            ),
          ],
        );

      case 'Lower Body B':
        return const GeneratedWorkout(
          title: 'Lower Body B',
          exercises: [
            ExercisePrescription(
              name: 'Hip Thrust',
              sets: 3,
              reps: '8–12',
              rest: '90 sec',
              equipment: 'Bench + Weight',
              target: 'Glutes',
            ),
            ExercisePrescription(
              name: 'Split Squat',
              sets: 3,
              reps: '8–12 each leg',
              rest: '90 sec',
              equipment: 'Bodyweight or Dumbbells',
              target: 'Quads, glutes',
            ),
            ExercisePrescription(
              name: 'Romanian Deadlift',
              sets: 3,
              reps: '8–12',
              rest: '90 sec',
              equipment: 'Barbell or Dumbbells',
              target: 'Hamstrings, glutes',
            ),
            ExercisePrescription(
              name: 'Leg Curl',
              sets: 3,
              reps: '10–15',
              rest: '75 sec',
              equipment: 'Leg Curl Machine',
              target: 'Hamstrings',
            ),
            ExercisePrescription(
              name: 'Calf Raise',
              sets: 3,
              reps: '10–15',
              rest: '60 sec',
              equipment: 'Machine or Free Weight',
              target: 'Calves',
            ),
            ExercisePrescription(
              name: 'Dead Bug',
              sets: 3,
              reps: '8–12 each side',
              rest: '60 sec',
              equipment: 'Bodyweight',
              target: 'Core',
            ),
          ],
        );

      default:
        return GeneratedWorkout(title: title, exercises: const []);
    }
  }

  static GeneratedWorkout _homeWorkout(String title) {
    if (title.startsWith('Full Body')) {
      return GeneratedWorkout(
        title: '$title — Home',
        exercises: const [
          ExercisePrescription(
            name: 'Goblet Squat',
            sets: 3,
            reps: '8–12',
            rest: '90 sec',
            equipment: 'Dumbbell',
            target: 'Quads, glutes',
          ),
          ExercisePrescription(
            name: 'Push-Up',
            sets: 3,
            reps: '8–15',
            rest: '90 sec',
            equipment: 'Bodyweight',
            target: 'Chest, triceps',
            visualAsset: 'assets/exercises/push_up.png',
          ),
          ExercisePrescription(
            name: 'One-Arm Dumbbell Row',
            sets: 3,
            reps: '8–12',
            rest: '90 sec',
            equipment: 'Dumbbell',
            target: 'Back, biceps',
          ),
          ExercisePrescription(
            name: 'Dumbbell Romanian Deadlift',
            sets: 3,
            reps: '8–12',
            rest: '90 sec',
            equipment: 'Dumbbells',
            target: 'Hamstrings, glutes',
          ),
          ExercisePrescription(
            name: 'Dumbbell Shoulder Press',
            sets: 2,
            reps: '8–12',
            rest: '90 sec',
            equipment: 'Dumbbells',
            target: 'Shoulders, triceps',
          ),
          ExercisePrescription(
            name: 'Plank',
            sets: 3,
            reps: '30–60 sec',
            rest: '60 sec',
            equipment: 'Bodyweight',
            target: 'Core',
          ),
        ],
      );
    }
    if (title.contains('Upper')) {
      return GeneratedWorkout(
        title: '$title — Home',
        exercises: const [
          ExercisePrescription(
            name: 'Push-Up',
            sets: 3,
            reps: '8–15',
            rest: '90 sec',
            equipment: 'Bodyweight',
            target: 'Chest, triceps',
            visualAsset: 'assets/exercises/push_up.png',
          ),
          ExercisePrescription(
            name: 'One-Arm Dumbbell Row',
            sets: 3,
            reps: '8–12',
            rest: '90 sec',
            equipment: 'Dumbbell',
            target: 'Back, biceps',
          ),
          ExercisePrescription(
            name: 'Dumbbell Floor Press',
            sets: 3,
            reps: '8–12',
            rest: '90 sec',
            equipment: 'Dumbbells',
            target: 'Chest, triceps',
          ),
          ExercisePrescription(
            name: 'Dumbbell Shoulder Press',
            sets: 3,
            reps: '8–12',
            rest: '90 sec',
            equipment: 'Dumbbells',
            target: 'Shoulders',
          ),
          ExercisePrescription(
            name: 'Dumbbell Curl',
            sets: 2,
            reps: '10–15',
            rest: '60 sec',
            equipment: 'Dumbbells',
            target: 'Biceps',
          ),
          ExercisePrescription(
            name: 'Overhead Triceps Extension',
            sets: 2,
            reps: '10–15',
            rest: '60 sec',
            equipment: 'Dumbbell',
            target: 'Triceps',
          ),
        ],
      );
    }

    return GeneratedWorkout(
      title: '$title — Home',
      exercises: const [
        ExercisePrescription(
          name: 'Goblet Squat',
          sets: 3,
          reps: '8–12',
          rest: '90 sec',
          equipment: 'Dumbbell',
          target: 'Quads, glutes',
        ),
        ExercisePrescription(
          name: 'Dumbbell Romanian Deadlift',
          sets: 3,
          reps: '8–12',
          rest: '90 sec',
          equipment: 'Dumbbells',
          target: 'Hamstrings, glutes',
        ),
        ExercisePrescription(
          name: 'Glute Bridge',
          sets: 3,
          reps: '10–15',
          rest: '75 sec',
          equipment: 'Bodyweight',
          target: 'Glutes',
        ),
        ExercisePrescription(
          name: 'Reverse Lunge',
          sets: 3,
          reps: '8–12 each leg',
          rest: '90 sec',
          equipment: 'Bodyweight or Dumbbells',
          target: 'Quads, glutes',
        ),
        ExercisePrescription(
          name: 'Standing Calf Raise',
          sets: 3,
          reps: '12–20',
          rest: '60 sec',
          equipment: 'Bodyweight',
          target: 'Calves',
        ),
        ExercisePrescription(
          name: 'Plank',
          sets: 3,
          reps: '30–60 sec',
          rest: '60 sec',
          equipment: 'Bodyweight',
          target: 'Core',
        ),
      ],
    );
  }
}
