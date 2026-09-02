class MasterExerciseDefinition {
  final String name;
  final String section;
  final String exerciseType;
  final List<String> groups;

  const MasterExerciseDefinition({
    required this.name,
    required this.section,
    required this.exerciseType,
    required this.groups,
  });
}

/// LeanIt's human-readable master exercise taxonomy.
///
/// One movement can belong to several groups without creating duplicate cards
/// in the Exercise Library. The first section in [sectionOrder] becomes the
/// primary section and later memberships are kept in [groups].
class MasterExerciseCatalogue {
  const MasterExerciseCatalogue._();

  static const List<String> sectionOrder = [
    'Neck',
    'Shoulders',
    'Rotator Cuff & Shoulder Stability',
    'Biceps',
    'Triceps',
    'Forearms & Grip',
    'Chest',
    'Serratus Anterior',
    'Abs / Six-Pack',
    'Core & Obliques',
    'Back',
    'Lats',
    'Traps & Upper Back',
    'Whole Upper Body',
    'Glutes',
    'Outer Hip / Abductors',
    'Inner Thigh / Adductors',
    'Quadriceps',
    'Hamstrings',
    'Calves',
    'Shins / Tibialis',
    'Whole Lower Body',
    'Full Body',
    'Cardio',
    'General Warm-Up',
    'General Cooldown',
    'Stretching & Mobility',
    'Running Warm-Up',
    'Sprint Warm-Up',
    'Running Drills & Technique',
    'Running Cooldown',
    'Running Stretching & Mobility',
  ];

  static const List<String> typeOrder = [
    'Strength & Muscle',
    'Cardio',
    'Warm-Up',
    'Cooldown',
    'Stretching & Mobility',
    'Running Warm-Up',
    'Sprint Warm-Up',
    'Running Drills',
    'Running Cooldown',
    'Running Stretching & Mobility',
  ];

  static const Map<String, String> _rawSections = {
    'Neck': '''
Chin Tuck
Supine Neck Flexion
Prone Neck Extension
Side-Lying Neck Flexion
Neck Flexion Isometric
Neck Extension Isometric
Left Lateral Neck Isometric
Right Lateral Neck Isometric
Neck Rotation Isometric
Light Band Neck Flexion
Light Band Neck Extension
Light Band Lateral Neck Flexion
''',
    'Shoulders': '''
Barbell Overhead Press
Dumbbell Shoulder Press
Seated Dumbbell Shoulder Press
Arnold Press
Machine Shoulder Press
Single-Arm Landmine Press
Dumbbell Lateral Raise
Cable Lateral Raise
Lean-Away Cable Lateral Raise
Machine Lateral Raise
Dumbbell Front Raise
Cable Front Raise
Plate Front Raise
Dumbbell Reverse Fly
Cable Reverse Fly
Reverse Pec Deck
Face Pull
Cable Y-Raise
Dumbbell Scaption Raise
Pike Push-Up
Handstand Push-Up
Lateral Raise
Reverse Fly
''',
    'Rotator Cuff & Shoulder Stability': '''
Band External Rotation
Cable External Rotation
Side-Lying External Rotation
Band Internal Rotation
Cable Internal Rotation
Face Pull to External Rotation
Wall Slide
Serratus Wall Slide
Serratus Punch
Push-Up Plus
Prone Y Raise
Prone T Raise
Prone W Raise
Scapular Pull-Up
Band Pull-Apart
Bottoms-Up Kettlebell Carry
Overhead Carry
Scapular Push-Up
Prone Y-T Raise
''',
    'Biceps': '''
Barbell Curl
EZ-Bar Curl
Dumbbell Curl
Alternating Dumbbell Curl
Incline Dumbbell Curl
Preacher Curl
Dumbbell Preacher Curl
Cable Curl
Bayesian Cable Curl
High Cable Curl
Concentration Curl
Spider Curl
Hammer Curl
Rope Hammer Curl
Cross-Body Hammer Curl
Reverse Curl
Zottman Curl
Machine Biceps Curl
Chin-Up
Resistance Band Curl
Band Biceps Curl
''',
    'Triceps': '''
Close-Grip Bench Press
Diamond Push-Up
Close-Grip Push-Up
Parallel-Bar Dip
Assisted Dip
Machine Dip
EZ-Bar Skull Crusher
Dumbbell Skull Crusher
Lying Dumbbell Triceps Extension
Overhead Dumbbell Triceps Extension
Overhead Cable Triceps Extension
Single-Arm Overhead Cable Extension
Rope Pushdown
Straight-Bar Pushdown
Single-Arm Cable Pushdown
Reverse-Grip Pushdown
Cable Cross-Body Triceps Extension
Dumbbell Kickback
Cable Kickback
JM Press
Cable Overhead Extension
Overhead Triceps Extension
Triceps Pushdown
''',
    'Forearms & Grip': '''
Barbell Wrist Curl
Dumbbell Wrist Curl
Barbell Reverse Wrist Curl
Dumbbell Reverse Wrist Curl
Reverse Barbell Curl
Reverse EZ-Bar Curl
Hammer Curl
Zottman Curl
Wrist Roller - Flexion
Wrist Roller - Extension
Dumbbell Pronation
Dumbbell Supination
Radial Deviation
Ulnar Deviation
Farmer's Carry
Suitcase Carry
Plate Pinch Hold
Dead Hang
Towel Hang
Towel Pull-Up
''',
    'Chest': '''
Barbell Bench Press
Incline Barbell Bench Press
Decline Barbell Bench Press
Dumbbell Bench Press
Incline Dumbbell Press
Decline Dumbbell Press
Dumbbell Floor Press
Dumbbell Squeeze Press
Machine Chest Press
Incline Machine Chest Press
Push-Up
Incline Push-Up
Decline Push-Up
Weighted Push-Up
Deficit Push-Up
Chest-Focused Dip
Cable Chest Fly
Low-to-High Cable Fly
High-to-Low Cable Fly
Pec Deck Fly
''',
    'Serratus Anterior': '''
Push-Up Plus
Scapular Push-Up
Serratus Punch
Cable Serratus Punch
Wall Slide
Foam-Roller Wall Slide
Bear Crawl
Plank Plus
Dumbbell Pullover
Landmine Press
''',
    'Abs / Six-Pack': '''
Crunch
Cable Crunch
Machine Crunch
Reverse Crunch
Decline Crunch
Stability-Ball Crunch
Hanging Knee Raise
Hanging Leg Raise
Captain's Chair Knee Raise
Lying Leg Raise
Toe Reach
V-Up
Jackknife
Ab-Wheel Rollout
Body Saw
Hollow-Body Hold
Hollow Rock
Tuck-Up
Dead Bug
Mountain Climber
''',
    'Core & Obliques': '''
Front Plank
Side Plank
Copenhagen Side Plank
Dead Bug
Bird Dog
Bear Plank
Bear Plank Shoulder Tap
Pallof Press
Half-Kneeling Pallof Press
Cable Wood Chop
Cable Lift
Russian Twist
Bicycle Crunch
Suitcase Carry
Farmer's Carry
Overhead Carry
Stir-the-Pot
Ab-Wheel Rollout
Renegade Row
Hollow-Body Hold
Plank
Plank Shoulder Tap
''',
    'Back': '''
Pull-Up
Assisted Pull-Up
Chin-Up
Lat Pulldown
Neutral-Grip Lat Pulldown
Single-Arm Lat Pulldown
Straight-Arm Pulldown
Barbell Bent-Over Row
Pendlay Row
One-Arm Dumbbell Row
Chest-Supported Dumbbell Row
Seated Cable Row
Machine Row
T-Bar Row
Inverted Row
Face Pull
Dumbbell Shrug
Barbell Shrug
Back Extension
Good Morning
Band Row
''',
    'Lats': '''
Pull-Up
Assisted Pull-Up
Chin-Up
Neutral-Grip Pull-Up
Wide-Grip Lat Pulldown
Neutral-Grip Lat Pulldown
Underhand Lat Pulldown
Single-Arm Lat Pulldown
Straight-Arm Cable Pulldown
Cable Pullover
Dumbbell Pullover
One-Arm Dumbbell Row
Chest-Supported Row
Seated Cable Row
Kneeling Single-Arm Pulldown
''',
    'Traps & Upper Back': '''
Dumbbell Shrug
Barbell Shrug
Trap-Bar Shrug
Cable Shrug
Farmer's Carry
Rack Pull
Face Pull
Reverse Pec Deck
Cable Reverse Fly
Dumbbell Reverse Fly
Chest-Supported Rear-Delt Row
Prone Y Raise
Prone T Raise
Scapular Pull-Up
High Cable Row
''',
    'Whole Upper Body': '''
Bench Press
Incline Bench Press
Dumbbell Bench Press
Overhead Press
Dumbbell Shoulder Press
Push-Up
Weighted Push-Up
Dip
Pull-Up
Chin-Up
Lat Pulldown
Barbell Row
Dumbbell Row
Seated Cable Row
Inverted Row
Landmine Press
Push Press
Renegade Row
Farmer's Carry
Bear Crawl
''',
    'Glutes': '''
Barbell Hip Thrust
Dumbbell Hip Thrust
Glute Bridge
Weighted Glute Bridge
Single-Leg Glute Bridge
Frog Pump
Romanian Deadlift
Single-Leg Romanian Deadlift
Sumo Deadlift
Conventional Deadlift
Bulgarian Split Squat
Reverse Lunge
Walking Lunge
Deep Squat
Cable Pull-Through
Cable Glute Kickback
Machine Hip Extension
45-Degree Back Extension - Glute Bias
Kettlebell Swing
Hip Thrust
''',
    'Outer Hip / Abductors': '''
Side-Lying Hip Abduction
Standing Cable Hip Abduction
Machine Hip Abduction
Resistance-Band Hip Abduction
Lateral Band Walk
Monster Walk
Clamshell
Banded Clamshell
Fire Hydrant
Side Plank Hip Abduction
Lateral Step-Up
Single-Leg Squat
Lateral Step-Down
Hip Airplane
Lateral Lunge
Cossack Squat
Banded Squat
Standing Hip Hike
Wall Hip-Abduction Isometric
Skater Squat
''',
    'Inner Thigh / Adductors': '''
Adductor Machine
Standing Cable Hip Adduction
Resistance-Band Hip Adduction
Side-Lying Hip Adduction
Short-Lever Copenhagen Plank
Long-Lever Copenhagen Plank
Ball Adductor Squeeze
Isometric Adductor Squeeze
Sumo Squat
Goblet Sumo Squat
Wide-Stance Back Squat
Sumo Deadlift
Wide-Stance Leg Press
Lateral Lunge
Dumbbell Lateral Lunge
Cossack Squat
Slider Lateral Lunge
Side-Lunge Hold
Lateral Squat Shift
Assisted Cossack Squat
''',
    'Quadriceps': '''
Back Squat
Front Squat
Goblet Squat
Hack Squat
Belt Squat
Leg Press
Single-Leg Press
Leg Extension
Bulgarian Split Squat
Split Squat
Forward Lunge
Reverse Lunge
Walking Lunge
Step-Up
Heel-Elevated Squat
Cyclist Squat
Spanish Squat
Wall Sit
Sled Push
Sissy Squat
Bodyweight Squat
''',
    'Hamstrings': '''
Barbell Romanian Deadlift
Dumbbell Romanian Deadlift
Single-Leg Romanian Deadlift
Stiff-Leg Deadlift
Conventional Deadlift
Good Morning
Seated Leg Curl
Lying Leg Curl
Standing Single-Leg Curl
Nordic Hamstring Curl
Assisted Nordic Curl
Glute-Ham Raise
Slider Hamstring Curl
Stability-Ball Hamstring Curl
Resistance-Band Leg Curl
Hamstring Walkout
45-Degree Back Extension - Hamstring Bias
Cable Pull-Through
Kettlebell Swing
Reverse Hyperextension
Band Romanian Deadlift
Leg Curl
''',
    'Calves': '''
Standing Calf Raise
Single-Leg Standing Calf Raise
Machine Standing Calf Raise
Smith-Machine Calf Raise
Dumbbell Calf Raise
Barbell Calf Raise
Seated Calf Raise
Single-Leg Seated Calf Raise
Bent-Knee Calf Raise
Leg-Press Calf Raise
Donkey Calf Raise
Stair Calf Raise
Eccentric Heel Drop
Bent-Knee Eccentric Heel Drop
Soleus Wall-Sit Calf Raise
Farmer's Walk on Toes
Pogo Jump
Single-Leg Pogo
Jump Rope
Low Box Calf Bounce
Calf Raise
''',
    'Shins / Tibialis': '''
Wall Tibialis Raise
Machine Tibialis Raise
Resistance-Band Dorsiflexion
Cable Dorsiflexion
Seated Tibialis Raise
Weighted Tibialis Raise
Heel Walk
Toe-Up Walk
Single-Leg Tibialis Raise
Controlled Ankle Dorsiflexion
''',
    'Whole Lower Body': '''
Back Squat
Front Squat
Goblet Squat
Deadlift
Romanian Deadlift
Sumo Deadlift
Trap-Bar Deadlift
Bulgarian Split Squat
Split Squat
Forward Lunge
Reverse Lunge
Walking Lunge
Lateral Lunge
Step-Up
Leg Press
Hack Squat
Hip Thrust
Kettlebell Swing
Sled Push
Sled Drag
''',
    'Full Body': '''
Conventional Deadlift
Trap-Bar Deadlift
Clean
Power Clean
Hang Power Clean
Clean and Press
Push Press
Dumbbell Thruster
Barbell Thruster
Kettlebell Swing
Kettlebell Clean and Press
Turkish Get-Up
Farmer's Carry
Sandbag Carry
Sled Push
Medicine-Ball Slam
Burpee
Bear Crawl
Renegade Row
Dumbbell Devil Press
''',
    'Cardio': '''
Walking
Brisk Walking
Incline Treadmill Walk
Jogging
Easy Running
Tempo Running
Interval Running
Outdoor Cycling
Stationary Cycling
Rowing Ergometer
Elliptical
Stair Climber
Jump Rope
Swimming
Aqua Jogging
Hiking
Dance Cardio
Shadow Boxing
Ski Ergometer
Low-Impact Step-Ups
Easy Run
Fartlek Run
Interval Run
Long Easy Run
Recovery Run
Run-Walk Intervals
Stationary Bike
Tempo Run
Treadmill Easy Run
Treadmill Intervals
''',
    'General Warm-Up': '''
Brisk Walk
Easy Jog
Easy Stationary Bike
Jumping Jacks
Arm Circles
Shoulder Rolls
Band Pull-Aparts
Thoracic Rotations
Cat-Cow
Inchworm
Walking Lunge
Reverse Lunge
Bodyweight Squat
Front-to-Back Leg Swing
Side-to-Side Leg Swing
Hip Circles
Ankle Rock
Glute Bridge
High Knees
Butt Kicks
March in Place
Warm-Up Walk
''',
    'General Cooldown': '''
Easy Walking
Slow Treadmill Walk
Easy Cycling
Easy Rowing
Diaphragmatic Breathing
Slow Nasal Breathing
Standing Calf Stretch
Bent-Knee Soleus Stretch
Standing Quad Stretch
Kneeling Hip-Flexor Stretch
Hamstring Stretch
Figure-Four Glute Stretch
Butterfly Adductor Stretch
Child's Pose
Kneeling Lat Stretch
Doorway Chest Stretch
Cross-Body Shoulder Stretch
Upper-Trap Stretch
Gentle Thoracic Rotation
Supine Knee-to-Chest Stretch
''',
    'Stretching & Mobility': '''
Calf Stretch
Soleus Stretch
Ankle Dorsiflexion Wall Mobilisation
Standing Quad Stretch
Couch Stretch
Kneeling Hip-Flexor Stretch
Standing Hamstring Stretch
Supine Hamstring Stretch
Figure-Four Glute Stretch
90/90 Hip Rotation
Butterfly Adductor Stretch
Frog Stretch
Cossack Mobility
World's Greatest Stretch
Thoracic Open Book
Cat-Cow
Child's Pose
Kneeling Lat Stretch
Doorway Pec Stretch
Cross-Body Shoulder Stretch
Hip Flexor Stretch
Thoracic Rotation
''',
    'Running Warm-Up': '''
Brisk Walk
Easy Jog
Ankle Rocks
Ankle Circles
Walking Calf Raise
Front-to-Back Leg Swing
Lateral Leg Swing
Walking Lunge
Walking Lunge + Rotation
A-March
A-Skip
B-Skip
High Knees
Butt Kicks
Straight-Leg Run / Toy Soldier
Carioca / Grapevine
Lateral Shuffle
Fast Feet
Running Strides
Progressive Build-Up Acceleration
''',
    'Sprint Warm-Up': '''
Easy Jog
Ankle Bounce
Pogos
A-March
A-Skip
B-Skip
High Knees
Butt Kicks
Straight-Leg Bounds
Walking Lunges
Leg Swings
Hip Circles
Lateral Shuffle
Carioca
Fast Feet
Wall Sprint Drill
Falling Start Drill
60% Stride
75% Stride
85-90% Build-Up
''',
    'Running Drills & Technique': '''
A-March
A-Skip
B-Skip
Power Skip
High Knees
Butt Kicks
Straight-Leg Bounds
Ankling
Pogo Hops
Wall March
Wall Switch
Falling Start
Accelerations
Strides
Hill Strides
Hill Sprints
Lateral Shuffle
Carioca
Fast Feet
Bounding
''',
    'Running Cooldown': '''
Slow Jog
Easy Walk
5-10 Minute Walk
Diaphragmatic Breathing
Calf Stretch
Soleus Stretch
Quad Stretch
Hip-Flexor Stretch
Hamstring Stretch
Figure-Four Glute Stretch
Adductor Stretch
Gentle 90/90 Hip Mobility
Child's Pose
Thoracic Rotation
Easy Ankle Mobility
''',
    'Running Stretching & Mobility': '''
Gastrocnemius Calf Stretch
Soleus Stretch
Tibialis Anterior Stretch
Ankle Dorsiflexion Mobilisation
Standing Quad Stretch
Couch Stretch
Kneeling Hip-Flexor Stretch
Standing Hamstring Stretch
Supine Hamstring Stretch
Figure-Four Glute Stretch
Piriformis Stretch
Butterfly Adductor Stretch
Frog Adductor Stretch
Lateral Adductor Stretch
90/90 Hip Mobility
Hip Internal-Rotation Mobility
Hip External-Rotation Mobility
World's Greatest Stretch
Thoracic Rotation
Gentle Lower-Back Rotation
''',
  };

  static final List<MasterExerciseDefinition> definitions = _build();

  static List<MasterExerciseDefinition> _build() {
    final sectionsByName = <String, List<String>>{};
    final originalName = <String, String>{};
    for (final section in sectionOrder) {
      for (final name in namesForSection(section)) {
        final key = normalize(name);
        originalName.putIfAbsent(key, () => name);
        sectionsByName.putIfAbsent(key, () => <String>[]).add(section);
      }
    }

    return sectionsByName.entries.map((entry) {
      final groups = List<String>.unmodifiable(entry.value);
      final section = groups.first;
      return MasterExerciseDefinition(
        name: originalName[entry.key]!,
        section: section,
        exerciseType: typeForSection(section),
        groups: groups,
      );
    }).toList(growable: false);
  }

  static List<String> namesForSection(String section) {
    final raw = _rawSections[section] ?? '';
    return raw
        .split('\n')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  static MasterExerciseDefinition? findByName(String name) {
    final key = normalize(name);
    for (final definition in definitions) {
      if (normalize(definition.name) == key) return definition;
    }
    return null;
  }

  static String typeForSection(String section) {
    if (section == 'Cardio') return 'Cardio';
    if (section == 'General Warm-Up') return 'Warm-Up';
    if (section == 'General Cooldown') return 'Cooldown';
    if (section == 'Stretching & Mobility') return 'Stretching & Mobility';
    if (section == 'Running Warm-Up') return 'Running Warm-Up';
    if (section == 'Sprint Warm-Up') return 'Sprint Warm-Up';
    if (section == 'Running Drills & Technique') return 'Running Drills';
    if (section == 'Running Cooldown') return 'Running Cooldown';
    if (section == 'Running Stretching & Mobility') {
      return 'Running Stretching & Mobility';
    }
    return 'Strength & Muscle';
  }

  static int sectionIndex(String? section) {
    final index = sectionOrder.indexOf(section ?? '');
    return index < 0 ? sectionOrder.length : index;
  }

  static int typeIndex(String? type) {
    final index = typeOrder.indexOf(type ?? '');
    return index < 0 ? typeOrder.length : index;
  }

  static List<String> primaryMusclesFor(String section) {
    return switch (section) {
      'Neck' => const ['Neck'],
      'Shoulders' => const ['Shoulders', 'Deltoids'],
      'Rotator Cuff & Shoulder Stability' =>
        const ['Rotator Cuff', 'Shoulder Stabilizers'],
      'Biceps' => const ['Biceps'],
      'Triceps' => const ['Triceps'],
      'Forearms & Grip' => const ['Forearms', 'Grip'],
      'Chest' => const ['Chest', 'Pectorals'],
      'Serratus Anterior' => const ['Serratus Anterior'],
      'Abs / Six-Pack' => const ['Abs', 'Rectus Abdominis'],
      'Core & Obliques' => const ['Core', 'Obliques'],
      'Back' => const ['Back'],
      'Lats' => const ['Lats'],
      'Traps & Upper Back' => const ['Upper Back', 'Traps'],
      'Whole Upper Body' => const ['Upper Body'],
      'Glutes' => const ['Glutes'],
      'Outer Hip / Abductors' => const ['Glute Medius', 'Hip Abductors'],
      'Inner Thigh / Adductors' => const ['Inner Thigh', 'Adductors'],
      'Quadriceps' => const ['Quadriceps'],
      'Hamstrings' => const ['Hamstrings'],
      'Calves' => const ['Calves'],
      'Shins / Tibialis' => const ['Shins', 'Tibialis Anterior'],
      'Whole Lower Body' => const ['Lower Body'],
      'Full Body' => const ['Full Body'],
      'Cardio' => const ['Cardiovascular'],
      'General Warm-Up' => const ['Full Body'],
      'General Cooldown' => const ['Full Body'],
      'Stretching & Mobility' => const ['Mobility'],
      'Running Warm-Up' => const ['Running'],
      'Sprint Warm-Up' => const ['Sprint'],
      'Running Drills & Technique' => const ['Running Technique'],
      'Running Cooldown' => const ['Running'],
      'Running Stretching & Mobility' => const ['Running Mobility'],
      _ => const ['Full Body'],
    };
  }

  static List<String> inferredEquipment(String name, String exerciseType) {
    final value = name.toLowerCase();
    if (value.contains('smith-machine')) return const ['Smith Machine'];
    if (value.contains('trap-bar')) return const ['Trap Bar'];
    if (value.contains('ez-bar')) return const ['EZ-Bar'];
    if (value.contains('t-bar')) return const ['T-Bar / Landmine'];
    if (value.contains('barbell') ||
        const ['back squat', 'front squat', 'bench press', 'overhead press', 'deadlift', 'rack pull', 'good morning', 'jm press']
            .contains(value)) {
      return const ['Barbell'];
    }
    if (value.contains('dumbbell')) return const ['Dumbbells'];
    if (value.contains('kettlebell')) return const ['Kettlebell'];
    if (value.contains('cable') ||
        value.contains('pushdown') ||
        value.contains('pallof')) {
      return const ['Cable Machine'];
    }
    if (value.contains('machine') ||
        value.contains('leg press') ||
        value.contains('hack squat') ||
        value.contains('leg extension') ||
        value.contains('leg curl')) {
      return const ['Machine'];
    }
    if (value.contains('band') || value.contains('resistance-band')) {
      return const ['Resistance Band'];
    }
    if (value.contains('landmine')) return const ['Landmine'];
    if (value.contains('sled')) return const ['Sled'];
    if (value.contains('medicine-ball')) return const ['Medicine Ball'];
    if (value.contains('sandbag')) return const ['Sandbag'];
    if (value.contains('stability-ball')) return const ['Stability Ball'];
    if (value.contains('ab-wheel')) return const ['Ab Wheel'];
    if (value.contains('wrist roller')) return const ['Wrist Roller'];
    if (value.contains('plate pinch') || value.contains('plate front')) {
      return const ['Weight Plate'];
    }
    if (value.contains('treadmill')) return const ['Treadmill'];
    if (value.contains('stationary bike') || value == 'stationary cycling') {
      return const ['Stationary Bike'];
    }
    if (value == 'outdoor cycling') return const ['Bicycle'];
    if (value.contains('rowing')) return const ['Rowing Machine'];
    if (value.contains('elliptical')) return const ['Elliptical'];
    if (value.contains('stair climber')) return const ['Stair Climber'];
    if (value.contains('ski erg')) return const ['Ski Erg'];
    if (value.contains('jump rope')) return const ['Jump Rope'];
    if (value.contains('pull-up') ||
        value.contains('chin-up') ||
        value.contains('dead hang') ||
        value.contains('towel hang')) {
      return const ['Pull-Up Bar'];
    }
    if (value.contains('dip')) return const ['Dip Bars'];
    if (value.contains('carry')) return const ['Dumbbells or Kettlebells'];
    if (value.contains('hip thrust')) return const ['Bench, Barbell or Bodyweight'];
    if (value.contains('preacher')) return const ['Preacher Bench, Dumbbell or EZ-Bar'];
    if (value.contains('reverse curl')) return const ['Barbell or EZ-Bar'];
    if (value.contains('skull crusher')) return const ['EZ-Bar or Dumbbells'];
    if (value.contains('goblet')) return const ['Dumbbell or Kettlebell'];
    if (value.contains('belt squat')) return const ['Belt Squat Machine'];
    if (value.contains('weighted')) return const ['Bodyweight + External Load'];
    if (value.contains('swim') || value.contains('aqua')) return const ['Pool'];
    return const ['Bodyweight'];
  }

  static String inferredDifficulty(String name, String exerciseType) {
    if (exerciseType != 'Strength & Muscle') return 'Beginner';
    final value = name.toLowerCase();
    if (value.contains('assisted') || value.contains('wall ') || value == 'chin tuck') {
      return 'Beginner';
    }
    const advancedTerms = [
      'handstand', 'power clean', 'hang power clean', 'turkish get-up',
      'nordic', 'sissy squat', 'devil press', 'long-lever copenhagen',
    ];
    if (advancedTerms.any(value.contains) || value == 'clean') return 'Advanced';
    return 'Intermediate';
  }

  static String inferredMovementPattern(String name, String exerciseType) {
    final value = name.toLowerCase();
    if (exerciseType == 'Cardio') return 'Cardio';
    if (exerciseType == 'Warm-Up' || exerciseType == 'Running Warm-Up' || exerciseType == 'Sprint Warm-Up') {
      return 'Dynamic Warm-Up';
    }
    if (exerciseType == 'Cooldown' || exerciseType == 'Running Cooldown') {
      return 'Cooldown / Recovery';
    }
    if (exerciseType.contains('Stretching')) return 'Mobility / Stretching';
    if (exerciseType == 'Running Drills') return 'Running Drill';
    if (value.contains('squat') || value.contains('leg press') || value.contains('leg extension')) {
      return 'Squat / Knee Dominant';
    }
    if (value.contains('deadlift') || value.contains('hip thrust') || value.contains('glute bridge') || value.contains('good morning')) {
      return 'Hip Hinge / Hip Extension';
    }
    if (value.contains('lunge') || value.contains('split squat') || value.contains('step-up')) {
      return 'Lunge / Single-Leg';
    }
    if (value.contains('bench') || value.contains('chest') || value.contains('push-up') || value.contains('fly')) {
      return 'Horizontal Push';
    }
    if (value.contains('shoulder press') || value.contains('overhead press') || value.contains('landmine press') || value.contains('push press') || value.contains('handstand')) {
      return 'Vertical Push';
    }
    if (value.contains('row') || value.contains('reverse fly') || value.contains('face pull')) {
      return 'Horizontal Pull';
    }
    if (value.contains('pull-up') || value.contains('chin-up') || value.contains('pulldown') || value.contains('pullover')) {
      return 'Vertical Pull';
    }
    if (value.contains('curl')) return 'Elbow Flexion';
    if (value.contains('triceps') || value.contains('pushdown') || value.contains('skull') || value.contains('kickback')) {
      return 'Elbow Extension';
    }
    if (value.contains('carry')) return 'Loaded Carry';
    return 'Accessory / Integrated';
  }

  static List<String> inferredLocations(String name, String exerciseType, List<String> equipment) {
    final value = name.toLowerCase();
    if (exerciseType.startsWith('Running') || exerciseType == 'Sprint Warm-Up') {
      return const ['Outside', 'Gym'];
    }
    if (exerciseType == 'Cardio') {
      if (value.contains('walk') || value.contains('jog') || value.contains('run') || value.contains('hiking')) {
        return const ['Outside', 'Home', 'Gym'];
      }
      return const ['Gym', 'Outside'];
    }
    final joined = equipment.join(' ').toLowerCase();
    if (joined.contains('bodyweight')) return const ['Home', 'Gym', 'Outside'];
    if (joined.contains('band') || joined.contains('dumbbell') || joined.contains('kettlebell') || joined.contains('medicine') || joined.contains('ab wheel') || joined.contains('plate')) {
      return const ['Home', 'Gym'];
    }
    if (joined.contains('sled')) return const ['Gym', 'Outside'];
    return const ['Gym'];
  }

  static String normalize(String value) => value
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}
