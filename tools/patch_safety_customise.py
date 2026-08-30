from pathlib import Path

path = Path('lib/main.dart')
text = path.read_text(encoding='utf-8')


def replace_once(old: str, new: str, label: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected exactly 1 match, found {count}')
    text = text.replace(old, new, 1)


replace_once(
    "import 'live_workout_screen.dart';\nimport 'package:supabase_flutter/supabase_flutter.dart';",
    "import 'live_workout_screen.dart';\nimport 'safety_engine.dart';\nimport 'movement_visual.dart';\nimport 'exercise_library_screen.dart';\nimport 'package:supabase_flutter/supabase_flutter.dart';",
    'imports',
)

# Add a direct entry to the full exercise catalogue from onboarding.
replace_once(
"""              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class AboutYouScreen""",
"""              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExerciseLibraryScreen(client: supabase),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text(
                    'BROWSE ALL EXERCISES',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF176B87),
                    side: const BorderSide(color: Color(0xFF176B87)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class AboutYouScreen""",
    'exercise library onboarding entry',
)

# Original LeanIt safety screening. These are not copied from a proprietary
# questionnaire; they are app-specific warning sign prompts informed by the
# curated ACSM/NHS/APTA/NICE evidence catalogue.
replace_once(
"""  final Set<String> affectedAreas = {};

  final TextEditingController notesController = TextEditingController();

  final List<String> bodyAreas = [""",
"""  final Set<String> affectedAreas = {};
  final Set<String> warningSigns = {};

  final TextEditingController notesController = TextEditingController();

  final List<String> warningSignOptions = [
    'Severe pain after an injury, I cannot put weight on the area, or it looks out of position',
    'New numbness, tingling or unusual weakness',
    'A joint is hot or swollen and I also feel feverish or generally unwell',
    'Chest pain, fainting, severe dizziness or unusual breathlessness with activity',
    'A clinician has told me not to exercise this area yet',
  ];

  final List<String> bodyAreas = [""",
    'safety warning state',
)

replace_once(
"""  void toggleArea(String area) {
    setState(() {
      if (affectedAreas.contains(area)) {
        affectedAreas.remove(area);
      } else {
        affectedAreas.add(area);
      }
    });
  }

  Widget yesNoCard""",
"""  void toggleArea(String area) {
    setState(() {
      if (affectedAreas.contains(area)) {
        affectedAreas.remove(area);
      } else {
        affectedAreas.add(area);
      }
    });
  }

  void toggleWarningSign(String sign) {
    setState(() {
      if (warningSigns.contains(sign)) {
        warningSigns.remove(sign);
      } else {
        warningSigns.add(sign);
      }
    });
  }

  Widget yesNoCard""",
    'warning sign toggle',
)

replace_once(
"""                                'This app does not diagnose injuries. This information will only help the programme avoid treating your training as if no limitation exists.',
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

                    const SizedBox(height: 30),""",
"""                                'LeanIt does not diagnose injuries. It can modify clearly conflicting exercises, but it cannot replace an assessment by a doctor, physiotherapist or other qualified clinician.',
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

                    const SizedBox(height: 28),

                    const Text(
                      'Safety warning signs',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select anything that applies right now. Leave all unchecked if none apply.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF627D98),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...warningSignOptions.map(
                      (sign) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CheckboxListTile(
                          value: warningSigns.contains(sign),
                          onChanged: (_) => toggleWarningSign(sign),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          title: Text(
                            sign,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF486581),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),""",
    'safety warning UI',
)

replace_once(
"""                                limitationNotes: notesController.text.trim(),
                              ),""",
"""                                limitationNotes: notesController.text.trim(),
                                warningSigns: Set<String>.from(warningSigns),
                              ),""",
    'pass warnings to review',
)

# Profile review fields and constructor.
replace_once(
"""  final Set<String> affectedAreas;
  final String limitationNotes;

  const ProfileReviewScreen({""",
"""  final Set<String> affectedAreas;
  final String limitationNotes;
  final Set<String> warningSigns;

  const ProfileReviewScreen({""",
    'profile warning field',
)

replace_once(
"""    required this.affectedAreas,
    required this.limitationNotes,
  });""",
"""    required this.affectedAreas,
    required this.limitationNotes,
    required this.warningSigns,
  });""",
    'profile warning constructor',
)

replace_once(
"""                        if (hasLimitation && limitationNotes.isNotEmpty)
                          infoRow(
                            icon: Icons.notes,
                            title: 'Note',
                            value: limitationNotes,
                          ),
                      ],""",
"""                        if (hasLimitation && limitationNotes.isNotEmpty)
                          infoRow(
                            icon: Icons.notes,
                            title: 'Note',
                            value: limitationNotes,
                          ),
                        if (warningSigns.isNotEmpty)
                          infoRow(
                            icon: Icons.health_and_safety_outlined,
                            title: 'Safety review required',
                            value: warningSigns.join('; '),
                          ),
                      ],""",
    'profile safety summary',
)

replace_once(
"""                          hasLimitation: hasLimitation,
                          affectedAreas: Set<String>.from(affectedAreas),
                        ),""",
"""                          hasLimitation: hasLimitation,
                          affectedAreas: Set<String>.from(affectedAreas),
                          limitationNotes: limitationNotes,
                          warningSigns: Set<String>.from(warningSigns),
                        ),""",
    'pass safety to programme',
)

# ProgrammeReady fields / constructor.
replace_once(
"""  final bool hasLimitation;
  final Set<String> affectedAreas;

  const ProgrammeReadyScreen({""",
"""  final bool hasLimitation;
  final Set<String> affectedAreas;
  final String limitationNotes;
  final Set<String> warningSigns;

  const ProgrammeReadyScreen({""",
    'programme safety fields',
)

replace_once(
"""    required this.hasLimitation,
    required this.affectedAreas,
  });""",
"""    required this.hasLimitation,
    required this.affectedAreas,
    required this.limitationNotes,
    required this.warningSigns,
  });""",
    'programme safety constructor',
)

replace_once(
"""    final programme = ProgrammeEngine.generate(
      goal: goal,
      experience: experience,
      fitnessLevel: fitnessLevel,
      availableDays: availableDays,
      locations: locations,
      sessionLength: sessionLength,
      trainingTime: trainingTime,
    );

    return Scaffold(""",
"""    final programme = ProgrammeEngine.generate(
      goal: goal,
      experience: experience,
      fitnessLevel: fitnessLevel,
      availableDays: availableDays,
      locations: locations,
      sessionLength: sessionLength,
      trainingTime: trainingTime,
    );
    final safetyProfile = SafetyProfile(
      hasLimitation: hasLimitation,
      affectedAreas: affectedAreas,
      warningSigns: warningSigns,
      notes: limitationNotes,
    );

    return Scaffold(""",
    'programme safety profile',
)

old_programme_warning = """                    if (hasLimitation)
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

                    if (hasLimitation) const SizedBox(height: 22),"""
new_programme_warning = """                    if (safetyProfile.needsMedicalReview)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFEF9A9A)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.health_and_safety, color: Color(0xFFC62828)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your safety answers include a warning sign. LeanIt will show the plan for reference but will pause app-directed training until you have appropriate medical guidance.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: Color(0xFF8E1B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (hasLimitation)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7FA),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF86CBD8)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.tune, color: Color(0xFF176B87)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You reported ${affectedAreas.join(', ')}. Each workout will now remove clearly conflicting movements and substitute conservative alternatives. This is evidence-informed exercise modification, not diagnosis or injury treatment.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: Color(0xFF245B69),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (hasLimitation || safetyProfile.needsMedicalReview)
                      const SizedBox(height: 22),"""
replace_once(old_programme_warning, new_programme_warning, 'programme safety notice')

# Every WorkoutDetailScreen construction needs the complete safety context.
text = text.replace(
"""                                  hasLimitation: hasLimitation,
                                  affectedAreas: Set<String>.from(
                                    affectedAreas,
                                  ),
                                ),""",
"""                                  hasLimitation: hasLimitation,
                                  affectedAreas: Set<String>.from(
                                    affectedAreas,
                                  ),
                                  limitationNotes: limitationNotes,
                                  warningSigns: Set<String>.from(warningSigns),
                                ),""",
)
text = text.replace(
"""                            hasLimitation: hasLimitation,
                            affectedAreas: Set<String>.from(affectedAreas),
                          ),""",
"""                            hasLimitation: hasLimitation,
                            affectedAreas: Set<String>.from(affectedAreas),
                            limitationNotes: limitationNotes,
                            warningSigns: Set<String>.from(warningSigns),
                          ),""",
)

# Workout detail safety context and custom workout state.
replace_once(
"""  final bool hasLimitation;
  final Set<String> affectedAreas;

  const WorkoutDetailScreen({""",
"""  final bool hasLimitation;
  final Set<String> affectedAreas;
  final String limitationNotes;
  final Set<String> warningSigns;

  const WorkoutDetailScreen({""",
    'workout safety fields',
)

replace_once(
"""    required this.hasLimitation,
    required this.affectedAreas,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();""",
"""    required this.hasLimitation,
    required this.affectedAreas,
    required this.limitationNotes,
    required this.warningSigns,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();""",
    'workout safety constructor',
)

replace_once(
"""class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late String selectedLocation;

  @override""",
"""class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late String selectedLocation;
  List<ExercisePrescription>? customExercises;

  ExercisePrescription _fromOnlineExercise(OnlineExercise exercise) {
    final pattern = (exercise.movementPattern ?? '').toLowerCase();
    final category = (exercise.category ?? '').toLowerCase();
    final isCardio = pattern == 'cardio' || category == 'cardio';
    final isMobility = pattern == 'mobility' ||
        category.contains('mobility') ||
        category.contains('knee support');

    return ExercisePrescription(
      name: exercise.name,
      sets: isCardio ? 1 : (isMobility ? 2 : 3),
      reps: isCardio
          ? '10–20 min comfortable'
          : (isMobility ? '10–15' : '8–12'),
      rest: isCardio ? 'As needed' : (isMobility ? '45 sec' : '75 sec'),
      equipment: exercise.equipment.isEmpty
          ? 'Bodyweight'
          : exercise.equipment.join(', '),
      target: exercise.primaryMuscles.isEmpty
          ? (exercise.category ?? 'General fitness')
          : exercise.primaryMuscles.join(', '),
      metricLabel: isCardio ? 'TARGET' : null,
    );
  }

  @override""",
    'custom workout state',
)

# Reset custom selection if the training location changes.
text = text.replace(
"""                                  setState(() {
                                    selectedLocation = location;
                                  });""",
"""                                  setState(() {
                                    selectedLocation = location;
                                    customExercises = null;
                                  });""",
)

replace_once(
"""    final workout = WorkoutEngine.generate(
      sessionTitle: widget.session.title,
      location: selectedLocation,
      homeEquipment: widget.homeEquipment,
      gymAccess: widget.gymAccess,
      sessionDuration: widget.session.duration,
    );

    return Scaffold(""",
"""    final generatedWorkout = WorkoutEngine.generate(
      sessionTitle: widget.session.title,
      location: selectedLocation,
      homeEquipment: widget.homeEquipment,
      gymAccess: widget.gymAccess,
      sessionDuration: widget.session.duration,
    );
    final selectedWorkout = customExercises == null
        ? generatedWorkout
        : GeneratedWorkout(
            title: '${generatedWorkout.title} — Custom',
            exercises: customExercises!,
          );
    final safetyProfile = SafetyProfile(
      hasLimitation: widget.hasLimitation,
      affectedAreas: widget.affectedAreas,
      warningSigns: widget.warningSigns,
      notes: widget.limitationNotes,
    );
    final adaptation = SafetyEngine.adaptWorkout(
      selectedWorkout,
      safetyProfile,
      location: selectedLocation,
    );
    final workout = adaptation.workout;

    return Scaffold(""",
    'adapt generated workout',
)

old_workout_warning = """                    if (widget.hasLimitation) ...[
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
                    ],"""
new_workout_warning = """                    if (adaptation.status != SafetyStatus.normal) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: adaptation.blocksTraining
                              ? const Color(0xFFFFEBEE)
                              : const Color(0xFFEAF7FA),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: adaptation.blocksTraining
                                ? const Color(0xFFEF9A9A)
                                : const Color(0xFF86CBD8),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  adaptation.blocksTraining
                                      ? Icons.health_and_safety
                                      : Icons.tune,
                                  color: adaptation.blocksTraining
                                      ? const Color(0xFFC62828)
                                      : const Color(0xFF176B87),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    adaptation.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: adaptation.blocksTraining
                                          ? const Color(0xFF8E1B1B)
                                          : const Color(0xFF245B69),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              adaptation.guidance,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: adaptation.blocksTraining
                                    ? const Color(0xFF8E1B1B)
                                    : const Color(0xFF486581),
                              ),
                            ),
                            if (adaptation.evidenceLabels.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Evidence framework: ${adaptation.evidenceLabels.join(' • ')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF627D98),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],"""
replace_once(old_workout_warning, new_workout_warning, 'workout adaptation card')

# Give each recommended exercise a real in-app START/FINISH movement visual,
# even before its final reviewed photo/video has been uploaded.
replace_once(
"""                                  child: const Icon(
                                    Icons.accessibility_new,
                                    color: Color(0xFF176B87),
                                    size: 34,
                                  ),""",
"""                                  clipBehavior: Clip.antiAlias,
                                  child: MovementVisual(
                                    exerciseName: exercise.name,
                                    compact: true,
                                  ),""",
    'workout card visual',
)

# Add customisation above the start button and only block for actual warning signs.
replace_once(
"""            Padding(
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
                        },""",
"""            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: adaptation.blocksTraining
                      ? null
                      : () async {
                          final result = await Navigator.push<List<OnlineExercise>>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExerciseLibraryScreen(
                                client: supabase,
                                selectionMode: true,
                                initialSelectedNames: workout.exercises
                                    .map((exercise) => exercise.name)
                                    .toSet(),
                                safetyProfile: safetyProfile,
                              ),
                            ),
                          );
                          if (result != null && result.isNotEmpty && mounted) {
                            setState(() {
                              customExercises = result
                                  .map(_fromOnlineExercise)
                                  .toList(growable: false);
                            });
                          }
                        },
                  icon: const Icon(Icons.tune),
                  label: Text(
                    customExercises == null
                        ? 'CUSTOMISE WORKOUT'
                        : 'EDIT CUSTOM WORKOUT',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF176B87),
                    side: const BorderSide(color: Color(0xFF176B87)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: adaptation.blocksTraining
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
                        },""",
    'customise workout button',
)

replace_once(
"""                  child: Text(
                    widget.hasLimitation
                        ? 'REVIEW LIMITATION FIRST'
                        : 'START WORKOUT',""",
"""                  child: Text(
                    adaptation.blocksTraining
                        ? 'MEDICAL REVIEW BEFORE TRAINING'
                        : 'START WORKOUT',""",
    'start workout safety label',
)

# Universal vector movement guide fallback in exercise details.
old_placeholder = """  Widget _placeholderVisual() {
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
"""
new_placeholder = """  Widget _placeholderVisual([String? movementPattern]) {
    return MovementVisual(
      exerciseName: exercise.name,
      movementPattern: movementPattern,
    );
  }

  Widget _localVisual([String? movementPattern]) {
    final visualAsset = exercise.visualAsset;
    if (visualAsset == null || visualAsset.isEmpty) {
      return _placeholderVisual(movementPattern);
    }

    return Image.asset(
      visualAsset,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          _placeholderVisual(movementPattern),
    );
  }
"""
replace_once(old_placeholder, new_placeholder, 'movement visual fallback')

replace_once(
"""        errorBuilder: (context, error, stackTrace) => _localVisual(),
      );""",
"""        errorBuilder: (context, error, stackTrace) =>
            _localVisual(onlineExercise?.movementPattern),
      );""",
    'online image fallback',
)

replace_once(
"""    return _localVisual();
  }

  @override
  Widget build(BuildContext context) {""",
"""    return _localVisual(onlineExercise?.movementPattern);
  }

  @override
  Widget build(BuildContext context) {""",
    'local movement pattern fallback',
)

path.write_text(text, encoding='utf-8')
print('main.dart safety, visuals and customisation patch applied')
