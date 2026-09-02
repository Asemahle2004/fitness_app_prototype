class TrainingProfileContext {
  final List<String> goals;
  final String mainGoal;
  final String experience;
  final String fitnessLevel;
  final String activityLevel;
  final String sessionLength;
  final String trainingTime;
  final int? age;
  final String? sex;
  final double? bodyWeightKg;

  const TrainingProfileContext({
    required this.goals,
    required this.mainGoal,
    required this.experience,
    required this.fitnessLevel,
    required this.activityLevel,
    required this.sessionLength,
    required this.trainingTime,
    this.age,
    this.sex,
    this.bodyWeightKg,
  });

  static TrainingProfileContext? current;

  factory TrainingProfileContext.fromMap(Map<String, dynamic> map) {
    List<String> strings(dynamic value) {
      if (value is! List) return const <String>[];
      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    final mainGoal = map['main_goal']?.toString().trim();
    final savedGoals = strings(map['goals']);
    final goals = <String>{
      ...savedGoals,
      if (mainGoal != null && mainGoal.isNotEmpty) mainGoal,
    }.toList(growable: false);

    return TrainingProfileContext(
      goals: goals.isEmpty ? const ['Improve General Fitness'] : goals,
      mainGoal: mainGoal == null || mainGoal.isEmpty
          ? (goals.isEmpty ? 'Improve General Fitness' : goals.first)
          : mainGoal,
      experience: map['experience']?.toString() ?? 'Beginner',
      fitnessLevel: map['fitness_level']?.toString() ?? 'Low',
      activityLevel: map['activity_level']?.toString() ?? 'Moderately active',
      sessionLength: map['session_length']?.toString() ?? '45 min',
      trainingTime: map['training_time']?.toString() ?? 'Flexible',
      age: (map['age'] as num?)?.toInt(),
      sex: map['sex']?.toString(),
      bodyWeightKg: (map['weight_kg'] as num?)?.toDouble(),
    );
  }

  static void updateFromMap(Map<String, dynamic>? map) {
    current = map == null ? null : TrainingProfileContext.fromMap(map);
  }

  bool hasGoal(String goal) => goals.contains(goal);
  bool get wantsStrength =>
      hasGoal('Build Muscle') ||
      hasGoal('Gain Weight') ||
      hasGoal('Improve General Fitness');
  bool get wantsFatLoss => hasGoal('Lose Body Fat');
  bool get wantsRunning =>
      hasGoal('Start Running') || hasGoal('Improve Running Performance');
}
