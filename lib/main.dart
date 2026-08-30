import 'package:flutter/material.dart';
import 'programme_engine.dart';
import 'workout_engine.dart';
import 'exercise_repository.dart';
import 'live_workout_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ukrapyyqyrwhbyjhkxeh.supabase.co',
    publishableKey: 'sb_publishable_Larl3RdDTmOlyhwkhWaWRw_UdJA7mTr',
  );

  runApp(const FitnessApp());
}

final supabase = Supabase.instance.client;

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness App',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Arial'),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Spacer(),

              // Temporary logo
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF176B87),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 44,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 35),

              const Text(
                'Train for your goal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF102A43),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'We plan the rest.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF176B87),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Get a personalised training programme for home, gym or running based on your goal, experience, equipment and schedule.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF627D98),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoalSelectionScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF176B87),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'GET STARTED',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextButton(
                onPressed: () {},
                child: const Text(
                  'Already have an account? Sign in',
                  style: TextStyle(color: Color(0xFF627D98)),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  String? selectedGoal;

  final List<Map<String, dynamic>> goals = [
    {
      'title': 'Build Muscle',
      'subtitle':
          'Increase muscle size through structured resistance training.',
      'icon': Icons.fitness_center,
    },
    {
      'title': 'Lose Body Fat',
      'subtitle':
          'Use structured training and activity to improve body composition.',
      'icon': Icons.local_fire_department,
    },
    {
      'title': 'Improve General Fitness',
      'subtitle': 'Become stronger, fitter and more physically active.',
      'icon': Icons.favorite,
    },
    {
      'title': 'Start Running',
      'subtitle':
          'Build gradually from your current level into regular running.',
      'icon': Icons.directions_run,
    },
    {
      'title': 'Improve Running Performance',
      'subtitle': 'Work toward better endurance, pace and race performance.',
      'icon': Icons.timer,
    },
    {
      'title': 'Gain Weight',
      'subtitle': 'Support healthy weight gain with structured training.',
      'icon': Icons.trending_up,
    },
  ];

  @override
  Widget build(BuildContext context) {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What do you want to achieve?',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF102A43),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Choose your main goal. We will build your programme around it.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Color(0xFF627D98),
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: ListView.separated(
                  itemCount: goals.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final goal = goals[index];

                    final bool isSelected = selectedGoal == goal['title'];

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        setState(() {
                          selectedGoal = goal['title'];
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE5F4F8)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF176B87)
                                : const Color(0xFFD9E2EC),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF176B87)
                                    : const Color(0xFFF0F4F8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                goal['icon'],
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF176B87),
                              ),
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal['title'],
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF102A43),
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    goal['subtitle'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.35,
                                      color: Color(0xFF627D98),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? const Color(0xFF176B87)
                                  : const Color(0xFF9FB3C8),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: selectedGoal == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AboutYouScreen(selectedGoal: selectedGoal!),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF176B87),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD9E2EC),
                    disabledForegroundColor: const Color(0xFF829AB1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class AboutYouScreen extends StatefulWidget {
  final String selectedGoal;

  const AboutYouScreen({super.key, required this.selectedGoal});

  @override
  State<AboutYouScreen> createState() => _AboutYouScreenState();
}

class _AboutYouScreenState extends State<AboutYouScreen> {
  final _formKey = GlobalKey<FormState>();

  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  String? selectedSex;
  String? activityLevel;

  @override
  void dispose() {
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF176B87), width: 2),
      ),
    );
  }

  Widget activityCard({required String title, required String subtitle}) {
    final isSelected = activityLevel == title;

    return InkWell(
      onTap: () {
        setState(() {
          activityLevel = title;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5F4F8) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF176B87)
                : const Color(0xFFD9E2EC),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF627D98),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color(0xFF176B87)
                  : const Color(0xFF9FB3C8),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tell us about you',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF102A43),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Goal: ${widget.selectedGoal}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF176B87),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'This helps us choose an appropriate starting programme.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF627D98),
                        ),
                      ),

                      const SizedBox(height: 26),

                      TextFormField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: fieldDecoration('Age', 'e.g. 22'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your age';
                          }

                          final age = int.tryParse(value);

                          if (age == null || age < 13 || age > 100) {
                            return 'Enter a valid age';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Sex',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF102A43),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Male',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              selected: selectedSex == 'Male',
                              onSelected: (_) {
                                setState(() {
                                  selectedSex = 'Male';
                                });
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ChoiceChip(
                              label: const SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Female',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              selected: selectedSex == 'Female',
                              onSelected: (_) {
                                setState(() {
                                  selectedSex = 'Female';
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: heightController,
                              keyboardType: TextInputType.number,
                              decoration: fieldDecoration(
                                'Height (cm)',
                                'e.g. 175',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }

                                final height = double.tryParse(value);

                                if (height == null ||
                                    height < 100 ||
                                    height > 250) {
                                  return 'Check height';
                                }

                                return null;
                              },
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: TextFormField(
                              controller: weightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: fieldDecoration(
                                'Weight (kg)',
                                'e.g. 60',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }

                                final weight = double.tryParse(value);

                                if (weight == null ||
                                    weight < 30 ||
                                    weight > 300) {
                                  return 'Check weight';
                                }

                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Current activity level',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF102A43),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Choose the option that best describes your normal lifestyle.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF627D98),
                        ),
                      ),

                      const SizedBox(height: 16),

                      activityCard(
                        title: 'Mostly inactive',
                        subtitle: 'Little regular physical activity.',
                      ),

                      const SizedBox(height: 10),

                      activityCard(
                        title: 'Lightly active',
                        subtitle: 'Some walking or occasional exercise.',
                      ),

                      const SizedBox(height: 10),

                      activityCard(
                        title: 'Moderately active',
                        subtitle:
                            'Exercise, sport or active movement several times per week.',
                      ),

                      const SizedBox(height: 10),

                      activityCard(
                        title: 'Very active',
                        subtitle:
                            'Frequent exercise, sport or physically demanding activity.',
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      final formIsValid = _formKey.currentState!.validate();

                      if (selectedSex == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select your sex.'),
                          ),
                        );
                        return;
                      }

                      if (activityLevel == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select your activity level.'),
                          ),
                        );
                        return;
                      }

                      if (!formIsValid) {
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrainingExperienceScreen(
                            selectedGoal: widget.selectedGoal,
                            age: int.parse(ageController.text),
                            sex: selectedSex!,
                            height: double.parse(heightController.text),
                            weight: double.parse(weightController.text),
                            activityLevel: activityLevel!,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF176B87),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrainingExperienceScreen extends StatefulWidget {
  final String selectedGoal;
  final int age;
  final String sex;
  final double height;
  final double weight;
  final String activityLevel;

  const TrainingExperienceScreen({
    super.key,
    required this.selectedGoal,
    required this.age,
    required this.sex,
    required this.height,
    required this.weight,
    required this.activityLevel,
  });

  @override
  State<TrainingExperienceScreen> createState() =>
      _TrainingExperienceScreenState();
}

class _TrainingExperienceScreenState extends State<TrainingExperienceScreen> {
  String? trainingExperience;
  String? fitnessLevel;

  Widget optionCard({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE5F4F8) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF176B87) : const Color(0xFFD9E2EC),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF627D98),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected
                  ? const Color(0xFF176B87)
                  : const Color(0xFF9FB3C8),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = trainingExperience != null && fitnessLevel != null;

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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your training experience',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Tell us about your experience with structured exercise.',
                      style: TextStyle(fontSize: 16, color: Color(0xFF627D98)),
                    ),

                    const SizedBox(height: 24),

                    optionCard(
                      title: 'Beginner',
                      subtitle:
                          'I am new to structured training or I am still learning exercises and technique.',
                      selected: trainingExperience == 'Beginner',
                      onTap: () {
                        setState(() {
                          trainingExperience = 'Beginner';
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    optionCard(
                      title: 'Intermediate',
                      subtitle:
                          'I train regularly, understand common exercises and want to continue improving.',
                      selected: trainingExperience == 'Intermediate',
                      onTap: () {
                        setState(() {
                          trainingExperience = 'Intermediate';
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    optionCard(
                      title: 'Experienced',
                      subtitle:
                          'I have trained consistently for a long time and understand structured programmes.',
                      selected: trainingExperience == 'Experienced',
                      onTap: () {
                        setState(() {
                          trainingExperience = 'Experienced';
                        });
                      },
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      'How fit are you currently?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'This may be different from your training experience.',
                      style: TextStyle(fontSize: 15, color: Color(0xFF627D98)),
                    ),

                    const SizedBox(height: 18),

                    optionCard(
                      title: 'Low',
                      subtitle:
                          'Exercise currently feels difficult or I have been inactive for some time.',
                      selected: fitnessLevel == 'Low',
                      onTap: () {
                        setState(() {
                          fitnessLevel = 'Low';
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    optionCard(
                      title: 'Moderate',
                      subtitle:
                          'I can handle normal physical activity and exercise reasonably well.',
                      selected: fitnessLevel == 'Moderate',
                      onTap: () {
                        setState(() {
                          fitnessLevel = 'Moderate';
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    optionCard(
                      title: 'Good',
                      subtitle:
                          'I am currently active and have a good level of fitness.',
                      selected: fitnessLevel == 'Good',
                      onTap: () {
                        setState(() {
                          fitnessLevel = 'Good';
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    optionCard(
                      title: 'Very Good',
                      subtitle:
                          'I train frequently or currently perform at a high fitness level.',
                      selected: fitnessLevel == 'Very Good',
                      onTap: () {
                        setState(() {
                          fitnessLevel = 'Very Good';
                        });
                      },
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: canContinue
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrainingLocationScreen(
                                selectedGoal: widget.selectedGoal,
                                age: widget.age,
                                sex: widget.sex,
                                height: widget.height,
                                weight: widget.weight,
                                activityLevel: widget.activityLevel,
                                trainingExperience: trainingExperience!,
                                fitnessLevel: fitnessLevel!,
                              ),
                            ),
                          );
                        }
                      : null,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF176B87),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD9E2EC),
                    disabledForegroundColor: const Color(0xFF829AB1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrainingLocationScreen extends StatefulWidget {
  final String selectedGoal;
  final int age;
  final String sex;
  final double height;
  final double weight;
  final String activityLevel;
  final String trainingExperience;
  final String fitnessLevel;

  const TrainingLocationScreen({
    super.key,
    required this.selectedGoal,
    required this.age,
    required this.sex,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.trainingExperience,
    required this.fitnessLevel,
  });

  @override
  State<TrainingLocationScreen> createState() => _TrainingLocationScreenState();
}

class _TrainingLocationScreenState extends State<TrainingLocationScreen> {
  final Set<String> selectedLocations = {};

  void toggleLocation(String location) {
    setState(() {
      if (selectedLocations.contains(location)) {
        selectedLocations.remove(location);
      } else {
        selectedLocations.add(location);
      }
    });
  }

  Widget locationCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool isSelected = selectedLocations.contains(title);

    return InkWell(
      onTap: () {
        toggleLocation(title);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5F4F8) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF176B87)
                : const Color(0xFFD9E2EC),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF176B87)
                    : const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                icon,
                size: 30,
                color: isSelected ? Colors.white : const Color(0xFF176B87),
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF627D98),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Icon(
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              color: isSelected
                  ? const Color(0xFF176B87)
                  : const Color(0xFF9FB3C8),
              size: 27,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canContinue = selectedLocations.isNotEmpty;

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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Where can you train?',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Select everything available to you. You can choose more than one.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: Color(0xFF627D98),
                      ),
                    ),

                    const SizedBox(height: 30),

                    locationCard(
                      title: 'Home',
                      subtitle:
                          'Train at home with bodyweight or equipment you already have.',
                      icon: Icons.home_rounded,
                    ),

                    const SizedBox(height: 16),

                    locationCard(
                      title: 'Gym',
                      subtitle:
                          'Train using gym equipment, free weights, machines or cables.',
                      icon: Icons.fitness_center,
                    ),

                    const SizedBox(height: 16),

                    locationCard(
                      title: 'Outside',
                      subtitle:
                          'Walking, running, sprinting, hills or outdoor field training.',
                      icon: Icons.directions_run,
                    ),

                    const SizedBox(height: 30),

                    if (selectedLocations.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F8),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          'Selected: ${selectedLocations.join(', ')}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF486581),
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: canContinue
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EquipmentScreen(
                                selectedGoal: widget.selectedGoal,
                                age: widget.age,
                                sex: widget.sex,
                                height: widget.height,
                                weight: widget.weight,
                                activityLevel: widget.activityLevel,
                                trainingExperience: widget.trainingExperience,
                                fitnessLevel: widget.fitnessLevel,
                                selectedLocations: Set<String>.from(
                                  selectedLocations,
                                ),
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF176B87),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD9E2EC),
                    disabledForegroundColor: const Color(0xFF829AB1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EquipmentScreen extends StatefulWidget {
  final String selectedGoal;
  final int age;
  final String sex;
  final double height;
  final double weight;
  final String activityLevel;
  final String trainingExperience;
  final String fitnessLevel;
  final Set<String> selectedLocations;

  const EquipmentScreen({
    super.key,
    required this.selectedGoal,
    required this.age,
    required this.sex,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.trainingExperience,
    required this.fitnessLevel,
    required this.selectedLocations,
  });

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final Set<String> homeEquipment = {};

  String? gymAccess;

  final List<Map<String, dynamic>> homeEquipmentOptions = [
    {'name': 'Bodyweight only', 'icon': Icons.accessibility_new},
    {'name': 'Dumbbells', 'icon': Icons.fitness_center},
    {'name': 'Resistance bands', 'icon': Icons.linear_scale},
    {'name': 'Pull-up bar', 'icon': Icons.horizontal_rule},
    {'name': 'Bench', 'icon': Icons.weekend},
    {'name': 'Barbell', 'icon': Icons.fitness_center},
    {'name': 'Weight plates', 'icon': Icons.circle_outlined},
    {'name': 'Kettlebell', 'icon': Icons.sports_gymnastics},
    {'name': 'Skipping rope', 'icon': Icons.loop},
    {'name': 'Other equipment', 'icon': Icons.add_circle_outline},
  ];

  void toggleHomeEquipment(String equipment) {
    setState(() {
      if (equipment == 'Bodyweight only') {
        if (homeEquipment.contains('Bodyweight only')) {
          homeEquipment.remove('Bodyweight only');
        } else {
          homeEquipment.clear();
          homeEquipment.add('Bodyweight only');
        }

        return;
      }

      homeEquipment.remove('Bodyweight only');

      if (homeEquipment.contains(equipment)) {
        homeEquipment.remove(equipment);
      } else {
        homeEquipment.add(equipment);
      }
    });
  }

  Widget equipmentCard({required String title, required IconData icon}) {
    final bool isSelected = homeEquipment.contains(title);

    return InkWell(
      onTap: () {
        toggleHomeEquipment(title);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5F4F8) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF176B87)
                : const Color(0xFFD9E2EC),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF176B87)
                    : const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF176B87),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF102A43),
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              color: isSelected
                  ? const Color(0xFF176B87)
                  : const Color(0xFF9FB3C8),
            ),
          ],
        ),
      ),
    );
  }

  Widget gymCard({required String title, required String subtitle}) {
    final bool isSelected = gymAccess == title;

    return InkWell(
      onTap: () {
        setState(() {
          gymAccess = title;
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5F4F8) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF176B87)
                : const Color(0xFFD9E2EC),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF627D98),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color(0xFF176B87)
                  : const Color(0xFF9FB3C8),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasHome = widget.selectedLocations.contains('Home');

    final bool hasGym = widget.selectedLocations.contains('Gym');

    final bool hasOutside = widget.selectedLocations.contains('Outside');

    final bool homeReady = !hasHome || homeEquipment.isNotEmpty;

    final bool gymReady = !hasGym || gymAccess != null;

    final bool canContinue = homeReady && gymReady;

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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What equipment can you use?',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'We will only create workouts using equipment available to you.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: Color(0xFF627D98),
                      ),
                    ),

                    const SizedBox(height: 28),

                    if (hasHome) ...[
                      const Row(
                        children: [
                          Icon(Icons.home_rounded, color: Color(0xFF176B87)),
                          SizedBox(width: 10),
                          Text(
                            'Home equipment',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF102A43),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Select everything you normally have available at home.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF627D98),
                        ),
                      ),

                      const SizedBox(height: 16),

                      ...homeEquipmentOptions.map(
                        (equipment) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: equipmentCard(
                            title: equipment['name'],
                            icon: equipment['icon'],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],

                    if (hasGym) ...[
                      const Row(
                        children: [
                          Icon(Icons.fitness_center, color: Color(0xFF176B87)),
                          SizedBox(width: 10),
                          Text(
                            'Gym access',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF102A43),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Choose the option that best describes the gym you normally use.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF627D98),
                        ),
                      ),

                      const SizedBox(height: 16),

                      gymCard(
                        title: 'Full gym',
                        subtitle:
                            'Free weights, benches, machines and cable equipment are available.',
                      ),

                      const SizedBox(height: 10),

                      gymCard(
                        title: 'Basic gym',
                        subtitle:
                            'Some weights and equipment are available, but options may be limited.',
                      ),

                      const SizedBox(height: 10),

                      gymCard(
                        title: "I'm not sure",
                        subtitle:
                            'We will give alternatives whenever equipment is unavailable.',
                      ),

                      const SizedBox(height: 30),
                    ],

                    if (hasOutside) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F8),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.directions_run,
                              color: Color(0xFF176B87),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Outside training does not require additional equipment information right now.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Color(0xFF486581),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: canContinue
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WeeklyAvailabilityScreen(
                                selectedGoal: widget.selectedGoal,
                                age: widget.age,
                                sex: widget.sex,
                                height: widget.height,
                                weight: widget.weight,
                                activityLevel: widget.activityLevel,
                                trainingExperience: widget.trainingExperience,
                                fitnessLevel: widget.fitnessLevel,
                                selectedLocations: Set<String>.from(
                                  widget.selectedLocations,
                                ),
                                homeEquipment: Set<String>.from(homeEquipment),
                                gymAccess: gymAccess,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF176B87),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD9E2EC),
                    disabledForegroundColor: const Color(0xFF829AB1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeeklyAvailabilityScreen extends StatefulWidget {
  final String selectedGoal;
  final int age;
  final String sex;
  final double height;
  final double weight;
  final String activityLevel;
  final String trainingExperience;
  final String fitnessLevel;
  final Set<String> selectedLocations;
  final Set<String> homeEquipment;
  final String? gymAccess;

  const WeeklyAvailabilityScreen({
    super.key,
    required this.selectedGoal,
    required this.age,
    required this.sex,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.trainingExperience,
    required this.fitnessLevel,
    required this.selectedLocations,
    required this.homeEquipment,
    required this.gymAccess,
  });

  @override
  State<WeeklyAvailabilityScreen> createState() =>
      _WeeklyAvailabilityScreenState();
}

class _WeeklyAvailabilityScreenState extends State<WeeklyAvailabilityScreen> {
  final Set<String> selectedDays = {};

  String? sessionLength;
  String? trainingTime;

  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> sessionLengths = [
    '15 min',
    '30 min',
    '45 min',
    '60 min',
    '90+ min',
  ];

  final List<String> trainingTimes = [
    'Morning',
    'Afternoon',
    'Evening',
    'It changes',
  ];

  void toggleDay(String day) {
    setState(() {
      if (selectedDays.contains(day)) {
        selectedDays.remove(day);
      } else {
        selectedDays.add(day);
      }
    });
  }

  Widget dayCard(String day) {
    final bool selected = selectedDays.contains(day);

    return InkWell(
      onTap: () {
        toggleDay(day);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE5F4F8) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF176B87) : const Color(0xFFD9E2EC),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                day,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF102A43),
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected
                  ? const Color(0xFF176B87)
                  : const Color(0xFF9FB3C8),
            ),
          ],
        ),
      ),
    );
  }

  Widget singleChoiceCard({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE5F4F8) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF176B87) : const Color(0xFFD9E2EC),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF102A43),
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected
                  ? const Color(0xFF176B87)
                  : const Color(0xFF9FB3C8),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canContinue =
        selectedDays.isNotEmpty &&
        sessionLength != null &&
        trainingTime != null;

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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'When can you train?',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Choose a schedule you can realistically maintain.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: Color(0xFF627D98),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'Training days',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Select every day you are normally available.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF627D98)),
                    ),

                    const SizedBox(height: 16),

                    ...days.map(
                      (day) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: dayCard(day),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Typical workout length',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'How much time can you normally give to one session?',
                      style: TextStyle(fontSize: 14, color: Color(0xFF627D98)),
                    ),

                    const SizedBox(height: 16),

                    ...sessionLengths.map(
                      (length) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: singleChoiceCard(
                          title: length,
                          selected: sessionLength == length,
                          onTap: () {
                            setState(() {
                              sessionLength = length;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'When do you normally train?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'This can help us understand your normal routine.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF627D98)),
                    ),

                    const SizedBox(height: 16),

                    ...trainingTimes.map(
                      (time) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: singleChoiceCard(
                          title: time,
                          selected: trainingTime == time,
                          onTap: () {
                            setState(() {
                              trainingTime = time;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    if (selectedDays.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F8),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          '${selectedDays.length} training day${selectedDays.length == 1 ? '' : 's'} selected',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF486581),
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: canContinue
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SafetyScreen(
                                selectedGoal: widget.selectedGoal,
                                age: widget.age,
                                sex: widget.sex,
                                height: widget.height,
                                weight: widget.weight,
                                activityLevel: widget.activityLevel,
                                trainingExperience: widget.trainingExperience,
                                fitnessLevel: widget.fitnessLevel,
                                selectedLocations: Set<String>.from(
                                  widget.selectedLocations,
                                ),
                                homeEquipment: Set<String>.from(
                                  widget.homeEquipment,
                                ),
                                gymAccess: widget.gymAccess,
                                selectedDays: Set<String>.from(selectedDays),
                                sessionLength: sessionLength!,
                                trainingTime: trainingTime!,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF176B87),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD9E2EC),
                    disabledForegroundColor: const Color(0xFF829AB1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SafetyScreen extends StatefulWidget {
  final String selectedGoal;
  final int age;
  final String sex;
  final double height;
  final double weight;
  final String activityLevel;
  final String trainingExperience;
  final String fitnessLevel;
  final Set<String> selectedLocations;
  final Set<String> homeEquipment;
  final String? gymAccess;
  final Set<String> selectedDays;
  final String sessionLength;
  final String trainingTime;

  const SafetyScreen({
    super.key,
    required this.selectedGoal,
    required this.age,
    required this.sex,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.trainingExperience,
    required this.fitnessLevel,
    required this.selectedLocations,
    required this.homeEquipment,
    required this.gymAccess,
    required this.selectedDays,
    required this.sessionLength,
    required this.trainingTime,
  });

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  bool? hasLimitation;

  final Set<String> affectedAreas = {};

  final TextEditingController notesController = TextEditingController();

  final List<String> bodyAreas = [
    'Shoulder',
    'Elbow',
    'Wrist / Hand',
    'Back',
    'Hip',
    'Knee',
    'Ankle / Foot',
    'Neck',
    'Other',
  ];

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  void toggleArea(String area) {
    setState(() {
      if (affectedAreas.contains(area)) {
        affectedAreas.remove(area);
      } else {
        affectedAreas.add(area);
      }
    });
  }

  Widget yesNoCard({
    required String title,
    required String subtitle,
    required bool value,
  }) {
    final bool selected = hasLimitation == value;

    return InkWell(
      onTap: () {
        setState(() {
          hasLimitation = value;

          if (!value) {
            affectedAreas.clear();
            notesController.clear();
          }
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE5F4F8) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF176B87) : const Color(0xFFD9E2EC),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF627D98),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected
                  ? const Color(0xFF176B87)
                  : const Color(0xFF9FB3C8),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canContinue =
        hasLimitation != null &&
        (hasLimitation == false || affectedAreas.isNotEmpty);

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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Before we create your programme',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Tell us if pain, injury or a physical limitation currently affects your exercise.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: Color(0xFF627D98),
                      ),
                    ),

                    const SizedBox(height: 28),

                    yesNoCard(
                      title: 'No',
                      subtitle:
                          'I do not currently have a known pain, injury or limitation affecting exercise.',
                      value: false,
                    ),

                    const SizedBox(height: 14),

                    yesNoCard(
                      title: 'Yes',
                      subtitle:
                          'I currently have pain, an injury or another limitation that may affect training.',
                      value: true,
                    ),

                    if (hasLimitation == true) ...[
                      const SizedBox(height: 32),

                      const Text(
                        'Which area is affected?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF102A43),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Select all that apply.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF627D98),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: bodyAreas.map((area) {
                          final selected = affectedAreas.contains(area);

                          return FilterChip(
                            label: Text(area),
                            selected: selected,
                            onSelected: (_) {
                              toggleArea(area);
                            },
                            selectedColor: const Color(0xFFE5F4F8),
                            checkmarkColor: const Color(0xFF176B87),
                            side: BorderSide(
                              color: selected
                                  ? const Color(0xFF176B87)
                                  : const Color(0xFFD9E2EC),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'Optional note',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF102A43),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: notesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              'Example: My right knee hurts during deep squats.',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFD9E2EC),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFD9E2EC),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF176B87),
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF9A6700)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This app does not diagnose injuries. This information will only help the programme avoid treating your training as if no limitation exists.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Color(0xFF6B4F00),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: canContinue
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileReviewScreen(
                                selectedGoal: widget.selectedGoal,
                                age: widget.age,
                                sex: widget.sex,
                                height: widget.height,
                                weight: widget.weight,
                                activityLevel: widget.activityLevel,
                                trainingExperience: widget.trainingExperience,
                                fitnessLevel: widget.fitnessLevel,
                                selectedLocations: Set<String>.from(
                                  widget.selectedLocations,
                                ),
                                homeEquipment: Set<String>.from(
                                  widget.homeEquipment,
                                ),
                                gymAccess: widget.gymAccess,
                                selectedDays: Set<String>.from(
                                  widget.selectedDays,
                                ),
                                sessionLength: widget.sessionLength,
                                trainingTime: widget.trainingTime,
                                hasLimitation: hasLimitation!,
                                affectedAreas: Set<String>.from(affectedAreas),
                                limitationNotes: notesController.text.trim(),
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF176B87),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD9E2EC),
                    disabledForegroundColor: const Color(0xFF829AB1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileReviewScreen extends StatelessWidget {
  final String selectedGoal;
  final int age;
  final String sex;
  final double height;
  final double weight;
  final String activityLevel;
  final String trainingExperience;
  final String fitnessLevel;
  final Set<String> selectedLocations;
  final Set<String> homeEquipment;
  final String? gymAccess;
  final Set<String> selectedDays;
  final String sessionLength;
  final String trainingTime;
  final bool hasLimitation;
  final Set<String> affectedAreas;
  final String limitationNotes;

  const ProfileReviewScreen({
    super.key,
    required this.selectedGoal,
    required this.age,
    required this.sex,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.trainingExperience,
    required this.fitnessLevel,
    required this.selectedLocations,
    required this.homeEquipment,
    required this.gymAccess,
    required this.selectedDays,
    required this.sessionLength,
    required this.trainingTime,
    required this.hasLimitation,
    required this.affectedAreas,
    required this.limitationNotes,
  });

  Widget infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F4F8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: const Color(0xFF176B87)),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF829AB1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
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
    );
  }

  Widget sectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String homeEquipmentText = homeEquipment.isEmpty
        ? 'Not selected'
        : homeEquipment.join(', ');

    final String gymText = gymAccess ?? 'Not selected';

    final String limitationText = hasLimitation
        ? affectedAreas.join(', ')
        : 'None reported';

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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your training profile',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Review your information before we build your programme.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: Color(0xFF627D98),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // GOAL
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F4F8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF176B87)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF176B87),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.flag_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PRIMARY GOAL',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    color: Color(0xFF486581),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  selectedGoal,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF102A43),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    sectionCard(
                      title: 'About you',
                      children: [
                        infoRow(
                          icon: Icons.cake_outlined,
                          title: 'Age',
                          value: '$age years',
                        ),
                        infoRow(
                          icon: Icons.person_outline,
                          title: 'Sex',
                          value: sex,
                        ),
                        infoRow(
                          icon: Icons.height,
                          title: 'Height',
                          value: '${height.toStringAsFixed(0)} cm',
                        ),
                        infoRow(
                          icon: Icons.monitor_weight_outlined,
                          title: 'Weight',
                          value: '${weight.toStringAsFixed(1)} kg',
                        ),
                        infoRow(
                          icon: Icons.directions_walk,
                          title: 'Activity level',
                          value: activityLevel,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    sectionCard(
                      title: 'Training',
                      children: [
                        infoRow(
                          icon: Icons.school_outlined,
                          title: 'Experience',
                          value: trainingExperience,
                        ),
                        infoRow(
                          icon: Icons.speed,
                          title: 'Current fitness',
                          value: fitnessLevel,
                        ),
                        infoRow(
                          icon: Icons.location_on_outlined,
                          title: 'Training locations',
                          value: selectedLocations.join(', '),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    if (selectedLocations.contains('Home'))
                      sectionCard(
                        title: 'Home equipment',
                        children: [
                          infoRow(
                            icon: Icons.home_rounded,
                            title: 'Available',
                            value: homeEquipmentText,
                          ),
                        ],
                      ),

                    if (selectedLocations.contains('Home'))
                      const SizedBox(height: 18),

                    if (selectedLocations.contains('Gym'))
                      sectionCard(
                        title: 'Gym',
                        children: [
                          infoRow(
                            icon: Icons.fitness_center,
                            title: 'Gym access',
                            value: gymText,
                          ),
                        ],
                      ),

                    if (selectedLocations.contains('Gym'))
                      const SizedBox(height: 18),

                    sectionCard(
                      title: 'Availability',
                      children: [
                        infoRow(
                          icon: Icons.calendar_today_outlined,
                          title: 'Available days',
                          value: selectedDays.join(', '),
                        ),
                        infoRow(
                          icon: Icons.timer_outlined,
                          title: 'Typical session',
                          value: sessionLength,
                        ),
                        infoRow(
                          icon: Icons.schedule,
                          title: 'Normal training time',
                          value: trainingTime,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    sectionCard(
                      title: 'Physical limitations',
                      children: [
                        infoRow(
                          icon: hasLimitation
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                          title: 'Reported limitations',
                          value: limitationText,
                        ),

                        if (hasLimitation && limitationNotes.isNotEmpty)
                          infoRow(
                            icon: Icons.notes,
                            title: 'Note',
                            value: limitationNotes,
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFF176B87)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your programme will use your goal, experience, fitness level, available training locations, equipment, schedule and limitations to choose an appropriate starting structure.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: Color(0xFF486581),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProgrammeReadyScreen(
                          goal: selectedGoal,
                          experience: trainingExperience,
                          fitnessLevel: fitnessLevel,
                          availableDays: Set<String>.from(selectedDays),
                          locations: Set<String>.from(selectedLocations),
                          sessionLength: sessionLength,
                          homeEquipment: Set<String>.from(homeEquipment),
                          gymAccess: gymAccess,
                          trainingTime: trainingTime,
                          hasLimitation: hasLimitation,
                          affectedAreas: Set<String>.from(affectedAreas),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    'CREATE MY PROGRAMME',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF176B87),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgrammeReadyScreen extends StatelessWidget {
  final String goal;
  final String experience;
  final String fitnessLevel;
  final Set<String> availableDays;
  final Set<String> locations;
  final Set<String> homeEquipment;
  final String? gymAccess;
  final String sessionLength;
  final String trainingTime;
  final bool hasLimitation;
  final Set<String> affectedAreas;

  const ProgrammeReadyScreen({
    super.key,
    required this.goal,
    required this.experience,
    required this.fitnessLevel,
    required this.availableDays,
    required this.locations,
    required this.homeEquipment,
    required this.gymAccess,
    required this.sessionLength,
    required this.trainingTime,
    required this.hasLimitation,
    required this.affectedAreas,
  });

  @override
  Widget build(BuildContext context) {
    final programme = ProgrammeEngine.generate(
      goal: goal,
      experience: experience,
      fitnessLevel: fitnessLevel,
      availableDays: availableDays,
      locations: locations,
      sessionLength: sessionLength,
      trainingTime: trainingTime,
    );

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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF176B87),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Your programme is ready',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      programme.goal,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF176B87),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      programme.structure,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF627D98),
                      ),
                    ),

                    const SizedBox(height: 26),

                    if (hasLimitation)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFFD580)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFF9A6700),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                'Prototype safety notice: you reported ${affectedAreas.join(', ')}. '
                                'The injury-aware exercise-selection system has not been built yet, so this programme structure is for prototype testing only.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: Color(0xFF6B4F00),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (hasLimitation) const SizedBox(height: 22),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        programme.explanation,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Color(0xFF486581),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Your week',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (programme.sessions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFD9E2EC)),
                        ),
                        child: const Text(
                          'This goal has not been added to Programme Engine v1 yet.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF486581),
                          ),
                        ),
                      ),

                    ...programme.sessions.map(
                      (session) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorkoutDetailScreen(
                                  session: session,
                                  locations: locations,
                                  homeEquipment: homeEquipment,
                                  gymAccess: gymAccess,
                                  hasLimitation: hasLimitation,
                                  affectedAreas: Set<String>.from(
                                    affectedAreas,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFD9E2EC),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5F4F8),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.fitness_center,
                                    color: Color(0xFF176B87),
                                  ),
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.day,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF176B87),
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        session.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF102A43),
                                        ),
                                      ),

                                      const SizedBox(height: 5),

                                      Text(
                                        '${session.duration} • ${session.location}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF627D98),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFF9FB3C8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            if (programme.sessions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      final firstSession = programme.sessions.first;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutDetailScreen(
                            session: firstSession,
                            locations: locations,
                            homeEquipment: homeEquipment,
                            gymAccess: gymAccess,
                            hasLimitation: hasLimitation,
                            affectedAreas: Set<String>.from(affectedAreas),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF176B87),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'VIEW MY WORKOUTS',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class WorkoutDetailScreen extends StatefulWidget {
  final PlannedSession session;
  final Set<String> locations;
  final Set<String> homeEquipment;
  final String? gymAccess;
  final bool hasLimitation;
  final Set<String> affectedAreas;

  const WorkoutDetailScreen({
    super.key,
    required this.session,
    required this.locations,
    required this.homeEquipment,
    required this.gymAccess,
    required this.hasLimitation,
    required this.affectedAreas,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late String selectedLocation;

  @override
  void initState() {
    super.initState();

    final preferredLocation = widget.session.location;

    if (preferredLocation.contains('Outside') &&
        widget.locations.contains('Outside')) {
      selectedLocation = 'Outside';
    } else if (preferredLocation.contains('Home') &&
        widget.locations.contains('Home')) {
      selectedLocation = 'Home';
    } else if (preferredLocation.contains('Gym') &&
        widget.locations.contains('Gym')) {
      selectedLocation = 'Gym';
    } else if (widget.locations.contains('Gym')) {
      selectedLocation = 'Gym';
    } else if (widget.locations.contains('Home')) {
      selectedLocation = 'Home';
    } else {
      selectedLocation = 'Outside';
    }
  }

  @override
  Widget build(BuildContext context) {
    final workout = WorkoutEngine.generate(
      sessionTitle: widget.session.title,
      location: selectedLocation,
      homeEquipment: widget.homeEquipment,
      gymAccess: widget.gymAccess,
      sessionDuration: widget.session.duration,
    );

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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.day,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF176B87),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      workout.title,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${widget.session.duration} • '
                      '${workout.exercises.length} exercises',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF627D98),
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (widget.locations.length > 1) ...[
                      const Text(
                        'Where are you training today?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF102A43),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: ['Gym', 'Home', 'Outside']
                            .where(widget.locations.contains)
                            .map(
                              (location) => ChoiceChip(
                                label: Text(location),
                                selected: selectedLocation == location,
                                onSelected: (_) {
                                  setState(() {
                                    selectedLocation = location;
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),

                      const SizedBox(height: 24),
                    ],

                    if (widget.hasLimitation) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFF9A6700),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You reported: '
                                '${widget.affectedAreas.join(', ')}. '
                                'Exercise-level limitation adaptation '
                                'has not been built yet.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: Color(0xFF6B4F00),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],

                    const Text(
                      'Today\'s workout',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 16),

                    ...workout.exercises.asMap().entries.map((entry) {
                      final index = entry.key;
                      final exercise = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ExerciseDetailScreen(exercise: exercise),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFD9E2EC),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 74,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5F4F8),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.accessibility_new,
                                    color: Color(0xFF176B87),
                                    size: 34,
                                  ),
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${index + 1}. ${exercise.name}',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF102A43),
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      Text(
                                        exercise.target,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF176B87),
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      Text(
                                        '${exercise.summary} • '
                                        'Rest ${exercise.rest}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF486581),
                                        ),
                                      ),

                                      const SizedBox(height: 5),

                                      Text(
                                        exercise.equipment,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF829AB1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFF9FB3C8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: widget.hasLimitation
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LiveWorkoutScreen(
                                workout: workout,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF176B87),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD9E2EC),
                    disabledForegroundColor: const Color(0xFF829AB1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    widget.hasLimitation
                        ? 'REVIEW LIMITATION FIRST'
                        : 'START WORKOUT',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseDetailScreen extends StatefulWidget {
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
                          label: exercise.setsLabel,
                          value: '${exercise.sets}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ExerciseInfoBox(
                          label: exercise.repsLabel,
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


class _ExerciseInfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _ExerciseInfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF829AB1),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
        ],
      ),
    );
  }
}
