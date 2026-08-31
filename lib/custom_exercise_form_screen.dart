import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'custom_exercise_store.dart';
import 'exercise_repository.dart';

class CustomExerciseFormScreen extends StatefulWidget {
  final SupabaseClient client;
  final CustomExerciseRecord? existing;

  const CustomExerciseFormScreen({
    super.key,
    required this.client,
    this.existing,
  });

  @override
  State<CustomExerciseFormScreen> createState() =>
      _CustomExerciseFormScreenState();
}

class _CustomExerciseFormScreenState extends State<CustomExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _primaryMuscles;
  late final TextEditingController _secondaryMuscles;
  late final TextEditingController _equipment;
  late final TextEditingController _movementPattern;
  late final TextEditingController _instructions;
  late final TextEditingController _sets;
  late final TextEditingController _reps;
  late final TextEditingController _rest;

  late final CustomExerciseStore _store;
  String _category = 'Strength';
  String _difficulty = 'Custom';
  final Set<String> _locations = {'Gym'};
  bool _saving = false;

  static const _categories = [
    'Strength',
    'Cardio',
    'Stretching',
    'Mobility',
    'Conditioning',
    'Other',
  ];

  static const _difficulties = [
    'Custom',
    'Beginner',
    'Intermediate',
    'Expert',
  ];

  @override
  void initState() {
    super.initState();
    _store = CustomExerciseStore(widget.client);
    final item = widget.existing;
    _name = TextEditingController(text: item?.name ?? '');
    _primaryMuscles = TextEditingController(
      text: item?.primaryMuscles.join(', ') ?? '',
    );
    _secondaryMuscles = TextEditingController(
      text: item?.secondaryMuscles.join(', ') ?? '',
    );
    _equipment = TextEditingController(
      text: item?.equipment.join(', ') ?? 'Bodyweight',
    );
    _movementPattern = TextEditingController(text: item?.movementPattern ?? '');
    _instructions = TextEditingController(
      text: item?.instructions.join('\n') ?? '',
    );
    _sets = TextEditingController(text: '${item?.defaultSets ?? 3}');
    _reps = TextEditingController(text: item?.defaultReps ?? '8–12');
    _rest = TextEditingController(text: item?.defaultRest ?? '75 sec');
    _category = item?.category ?? 'Strength';
    _difficulty = item?.difficulty ?? 'Custom';
    _locations
      ..clear()
      ..addAll(item?.locations.isNotEmpty == true ? item!.locations : const ['Gym']);
  }

  @override
  void dispose() {
    _name.dispose();
    _primaryMuscles.dispose();
    _secondaryMuscles.dispose();
    _equipment.dispose();
    _movementPattern.dispose();
    _instructions.dispose();
    _sets.dispose();
    _reps.dispose();
    _rest.dispose();
    super.dispose();
  }

  List<String> _csv(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);

  List<String> _lines(String value) => value
      .split(RegExp(r'\r?\n'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose at least one training location.')),
      );
      return;
    }

    setState(() => _saving = true);
    final name = _name.text.trim();

    try {
      final duplicateCustom = await _store.nameExists(
        name,
        excludingId: widget.existing?.id,
      );
      if (duplicateCustom) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already have a custom exercise with this name.')),
        );
        return;
      }

      final originalName = widget.existing?.name.trim().toLowerCase();
      if (originalName != name.toLowerCase()) {
        try {
          final builtIn = await ExerciseRepository(widget.client).fetchByName(name);
          if (builtIn != null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('That name already exists in the LeanIt Exercise Library.'),
              ),
            );
            return;
          }
        } catch (_) {
          // Offline creation is allowed. A local duplicate is still blocked above.
        }
      }

      final sets = int.tryParse(_sets.text.trim()) ?? 3;
      final record = widget.existing == null
          ? CustomExerciseRecord.create(
              name: name,
              category: _category,
              primaryMuscles: _csv(_primaryMuscles.text),
              secondaryMuscles: _csv(_secondaryMuscles.text),
              equipment: _csv(_equipment.text),
              difficulty: _difficulty,
              movementPattern: _movementPattern.text,
              locations: _locations.toList(growable: false),
              instructions: _lines(_instructions.text),
              defaultSets: sets,
              defaultReps: _reps.text,
              defaultRest: _rest.text,
            )
          : widget.existing!.copyWith(
              name: name,
              category: _category,
              primaryMuscles: _csv(_primaryMuscles.text),
              secondaryMuscles: _csv(_secondaryMuscles.text),
              equipment: _csv(_equipment.text),
              difficulty: _difficulty,
              movementPattern: _movementPattern.text,
              clearMovementPattern: _movementPattern.text.trim().isEmpty,
              locations: _locations.toList(growable: false),
              instructions: _lines(_instructions.text),
              defaultSets: sets,
              defaultReps: _reps.text,
              defaultRest: _rest.text,
            );

      await _store.save(record);
      if (!mounted) return;
      Navigator.pop(context, record);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        title: Text(editing ? 'Edit custom exercise' : 'Create custom exercise'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _field(
                controller: _name,
                label: 'Exercise name',
                hint: 'Example: Single-arm cable press',
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Enter an exercise name.'
                    : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories
                          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                          .toList(growable: false),
                      onChanged: (value) => setState(() => _category = value ?? _category),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _difficulty,
                      decoration: const InputDecoration(labelText: 'Difficulty'),
                      items: _difficulties
                          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                          .toList(growable: false),
                      onChanged: (value) => setState(() => _difficulty = value ?? _difficulty),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _field(
                controller: _primaryMuscles,
                label: 'Primary muscles',
                hint: 'Chest, Shoulders',
                helper: 'Separate multiple muscles with commas.',
                validator: (value) => _csv(value ?? '').isEmpty
                    ? 'Add at least one primary muscle.'
                    : null,
              ),
              const SizedBox(height: 14),
              _field(
                controller: _secondaryMuscles,
                label: 'Secondary muscles (optional)',
                hint: 'Triceps',
              ),
              const SizedBox(height: 14),
              _field(
                controller: _equipment,
                label: 'Equipment',
                hint: 'Bodyweight or Dumbbells, Bench',
                validator: (value) => _csv(value ?? '').isEmpty
                    ? 'Add equipment or use Bodyweight.'
                    : null,
              ),
              const SizedBox(height: 14),
              _field(
                controller: _movementPattern,
                label: 'Movement pattern (optional)',
                hint: 'Push, Pull, Squat, Hinge, Core…',
              ),
              const SizedBox(height: 18),
              const Text(
                'Training locations',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102A43)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Home', 'Gym', 'Outside']
                    .map(
                      (location) => FilterChip(
                        label: Text(location),
                        selected: _locations.contains(location),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _locations.add(location);
                            } else {
                              _locations.remove(location);
                            }
                          });
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 18),
              const Text(
                'Default workout prescription',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102A43)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _sets,
                      label: 'Sets',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final parsed = int.tryParse(value?.trim() ?? '');
                        return parsed == null || parsed < 1 || parsed > 20
                            ? '1–20'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _field(
                      controller: _reps,
                      label: 'Reps / time',
                      hint: '8–12 or 45 sec',
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _field(
                      controller: _rest,
                      label: 'Rest',
                      hint: '75 sec',
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _field(
                controller: _instructions,
                label: 'Instructions (optional)',
                hint: 'One instruction per line',
                maxLines: 6,
              ),
              const SizedBox(height: 10),
              const Text(
                'Custom exercises are user-defined. LeanIt does not independently verify their technique or suitability. Saved limitation filters still apply when you add them to a workout.',
                style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF627D98)),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: const Color(0xFF176B87),
                  foregroundColor: Colors.white,
                ),
                label: Text(
                  _saving ? 'SAVING…' : editing ? 'SAVE CHANGES' : 'CREATE EXERCISE',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? helper,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
