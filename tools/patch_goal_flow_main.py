from pathlib import Path

path = Path("lib/main.dart")
text = path.read_text(encoding="utf-8")

def replace_once(old: str, new: str, label: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected exactly 1 match, found {count}")
    text = text.replace(old, new, 1)

replace_once(
"""  @override
  void initState() {
    super.initState();

    if (widget.locations.contains('Gym')) {
      selectedLocation = 'Gym';
    } else if (widget.locations.contains('Home')) {
      selectedLocation = 'Home';
    } else {
      selectedLocation = 'Outside';
    }
  }
""",
"""  @override
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
""",
"preferred workout location",
)

replace_once(
"""    final workout = WorkoutEngine.generate(
      sessionTitle: widget.session.title,
      location: selectedLocation,
    );
""",
"""    final workout = WorkoutEngine.generate(
      sessionTitle: widget.session.title,
      location: selectedLocation,
      homeEquipment: widget.homeEquipment,
      gymAccess: widget.gymAccess,
      sessionDuration: widget.session.duration,
    );
""",
"workout engine profile inputs",
)

replace_once(
"""                    if (widget.locations.contains('Home') &&
                        widget.locations.contains('Gym')) ...[
                      const Text(
                        'Where are you training today?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF102A43),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const SizedBox(
                                width: double.infinity,
                                child: Text('Gym', textAlign: TextAlign.center),
                              ),
                              selected: selectedLocation == 'Gym',
                              onSelected: (_) {
                                setState(() {
                                  selectedLocation = 'Gym';
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
                                  'Home',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              selected: selectedLocation == 'Home',
                              onSelected: (_) {
                                setState(() {
                                  selectedLocation = 'Home';
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
""",
"""                    if (widget.locations.length > 1) ...[
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
""",
"location selector",
)

replace_once(
"""                                      Text(
                                        '${exercise.sets} sets × '
                                        '${exercise.reps} • '
                                        'Rest ${exercise.rest}',
""",
"""                                      Text(
                                        '${exercise.summary} • '
                                        'Rest ${exercise.rest}',
""",
"workout prescription summary",
)

replace_once(
"""                        child: _ExerciseInfoBox(
                          label: 'SETS',
                          value: '${exercise.sets}',
                        ),
""",
"""                        child: _ExerciseInfoBox(
                          label: exercise.setsLabel,
                          value: '${exercise.sets}',
                        ),
""",
"sets label",
)

replace_once(
"""                        child: _ExerciseInfoBox(
                          label: 'REPS',
                          value: exercise.reps,
                        ),
""",
"""                        child: _ExerciseInfoBox(
                          label: exercise.repsLabel,
                          value: exercise.reps,
                        ),
""",
"reps label",
)

replace_once(
"""                    onPressed: () {
                      // Workout exercise generation comes next.
                    },
""",
"""                    onPressed: () {
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
""",
"view my workouts button",
)

path.write_text(text, encoding="utf-8")
print("main.dart patched successfully")
