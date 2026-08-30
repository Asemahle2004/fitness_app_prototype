from pathlib import Path

main_path = Path('lib/main.dart')
text = main_path.read_text(encoding='utf-8')

import_line = "import 'exercise_repository.dart';\n"
if import_line not in text:
    anchor = "import 'workout_engine.dart';\n"
    if anchor not in text:
        raise SystemExit('Could not find workout_engine import')
    text = text.replace(anchor, anchor + import_line, 1)

start_marker = 'class ExerciseDetailScreen extends StatelessWidget {'
end_marker = 'class _ExerciseInfoBox extends StatelessWidget {'

start = text.find(start_marker)
end = text.find(end_marker)
if start == -1 or end == -1 or end <= start:
    raise SystemExit('Could not find ExerciseDetailScreen block')

new_class = r'''class ExerciseDetailScreen extends StatefulWidget {
  final ExercisePrescription exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late final ExerciseRepository _exerciseRepository;
  late final Future<OnlineExercise?> _onlineExerciseFuture;

  ExercisePrescription get exercise => widget.exercise;

  @override
  void initState() {
    super.initState();
    _exerciseRepository = ExerciseRepository(supabase);
    _onlineExerciseFuture = _exerciseRepository.fetchByName(exercise.name);
  }

  List<String> instructionsFor(String exerciseName) {
    switch (exerciseName) {
      case 'Goblet Squat':
        return [
          'Hold the dumbbell close to your chest.',
          'Stand with your feet in a comfortable position.',
          'Brace your body and lower under control.',
          'Keep your feet firmly on the floor.',
          'Stand back up under control.',
        ];

      case 'Dumbbell Romanian Deadlift':
      case 'Romanian Deadlift':
        return [
          'Hold the weights in front of your thighs.',
          'Keep a slight bend in your knees.',
          'Move your hips backward as you lower the weights.',
          'Keep the weights close to your legs.',
          'Drive your hips forward to return to standing.',
        ];

      case 'Glute Bridge':
        return [
          'Lie on your back with your knees bent.',
          'Keep your feet firmly on the floor.',
          'Brace your core.',
          'Lift your hips upward under control.',
          'Lower slowly back to the floor.',
        ];

      case 'Push-Up':
        return [
          'Place your hands slightly wider than shoulder width.',
          'Keep your body in a straight line.',
          'Lower your chest toward the floor.',
          'Keep your body controlled.',
          'Push back to the starting position.',
        ];

      case 'Dumbbell Bench Press':
        return [
          'Lie securely on the bench.',
          'Hold a dumbbell in each hand.',
          'Lower the dumbbells under control.',
          'Keep your feet stable on the floor.',
          'Press the dumbbells upward.',
        ];

      default:
        return [
          'Set yourself up in a stable starting position.',
          'Perform the movement under control.',
          'Use a comfortable range of motion.',
          'Avoid rushing the repetitions.',
          'Stop if you experience unusual pain.',
        ];
    }
  }

  List<String> mistakesFor(String exerciseName) {
    switch (exerciseName) {
      case 'Goblet Squat':
        return [
          'Heels lifting from the floor',
          'Knees collapsing inward',
          'Dropping too quickly',
        ];

      case 'Dumbbell Romanian Deadlift':
      case 'Romanian Deadlift':
        return [
          'Rounding the back excessively',
          'Turning the movement into a squat',
          'Holding the weights too far from the body',
        ];

      case 'Push-Up':
        return [
          'Hips dropping',
          'Elbows spreading excessively',
          'Using incomplete uncontrolled repetitions',
        ];

      default:
        return [
          'Using more resistance than you can control',
          'Rushing the movement',
          'Ignoring unusual pain',
        ];
    }
  }

  Widget _placeholderVisual() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.accessibility_new,
          size: 100,
          color: Color(0xFF176B87),
        ),
        SizedBox(height: 16),
        Text(
          'Exercise visual being prepared',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF486581),
          ),
        ),
      ],
    );
  }

  Widget _localVisual() {
    final visualAsset = exercise.visualAsset;
    if (visualAsset == null || visualAsset.isEmpty) {
      return _placeholderVisual();
    }

    return Image.asset(
      visualAsset,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _placeholderVisual(),
    );
  }

  Widget _exerciseVisual(
    OnlineExercise? onlineExercise, {
    required bool isLoading,
  }) {
    final imagePath = onlineExercise?.imagePath;

    if (imagePath != null && imagePath.isNotEmpty) {
      final imageUrl = _exerciseRepository.publicImageUrl(imagePath);
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _localVisual(),
      );
    }

    if (isLoading && exercise.visualAsset == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return _localVisual();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OnlineExercise?>(
      future: _onlineExerciseFuture,
      builder: (context, snapshot) {
        final onlineExercise = snapshot.data;
        final fallbackInstructions = instructionsFor(exercise.name);
        final fallbackMistakes = mistakesFor(exercise.name);

        final instructions = onlineExercise != null &&
                onlineExercise.instructions.isNotEmpty
            ? onlineExercise.instructions
            : fallbackInstructions;

        final mistakes = onlineExercise != null &&
                onlineExercise.commonMistakes.isNotEmpty
            ? onlineExercise.commonMistakes
            : fallbackMistakes;

        final target = onlineExercise != null &&
                onlineExercise.primaryMuscles.isNotEmpty
            ? onlineExercise.primaryMuscles.join(', ')
            : exercise.target;

        final equipmentText = onlineExercise != null &&
                onlineExercise.equipment.isNotEmpty
            ? onlineExercise.equipment.join(', ')
            : exercise.equipment;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F9FC),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF102A43)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    target,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF176B87),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 320,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F4F8),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _exerciseVisual(
                      onlineExercise,
                      isLoading:
                          snapshot.connectionState == ConnectionState.waiting,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _ExerciseInfoBox(
                          label: 'SETS',
                          value: '${exercise.sets}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ExerciseInfoBox(
                          label: 'REPS',
                          value: exercise.reps,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ExerciseInfoBox(
                          label: 'REST',
                          value: exercise.rest,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'How to perform',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...instructions.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE5F4F8),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF176B87),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.45,
                                color: Color(0xFF486581),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Common mistakes',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...mistakes.map(
                    (mistake) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.close_rounded,
                            color: Colors.redAccent,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mistake,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF486581),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD9E2EC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          color: Color(0xFF176B87),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Equipment',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF829AB1),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                equipmentText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF102A43),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
'''

text = text[:start] + new_class + '\n\n' + text[end:]
main_path.write_text(text, encoding='utf-8')
print('Refactored lib/main.dart to use ExerciseRepository for every exercise.')
