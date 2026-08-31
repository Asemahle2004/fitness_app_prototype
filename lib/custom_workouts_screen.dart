import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'custom_workout_store.dart';
import 'drop_set_engine.dart';
import 'exercise_library_screen.dart';
import 'exercise_repository.dart';
import 'live_workout_screen.dart';
import 'profile_service.dart';
import 'safety_engine.dart';
import 'superset_engine.dart';
import 'workout_editor_screen.dart';
import 'workout_engine.dart';

class CustomWorkoutsScreen extends StatefulWidget {
  final SupabaseClient client;

  const CustomWorkoutsScreen({
    super.key,
    required this.client,
  });

  @override
  State<CustomWorkoutsScreen> createState() => _CustomWorkoutsScreenState();
}

class _CustomWorkoutsScreenState extends State<CustomWorkoutsScreen> {
  late final CustomWorkoutStore _store;
  late Future<List<CustomWorkout>> _future;

  @override
  void initState() {
    super.initState();
    _store = CustomWorkoutStore(widget.client);
    _future = _store.loadAll();
  }

  Future<void> _refresh() async {
    setState(() => _future = _store.loadAll());
    await _future;
  }

  Future<void> _openBuilder([CustomWorkout? existing]) async {
    final saved = await Navigator.push<CustomWorkout>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomWorkoutBuilderScreen(
          client: widget.client,
          store: _store,
          existing: existing,
        ),
      ),
    );
    if (saved != null && mounted) await _refresh();
  }

  Future<SafetyProfile> _currentSafetyProfile() async {
    try {
      final map = await ProfileService(widget.client).currentProfileMap();
      return SafetyProfile(
        hasLimitation: map?['has_limitation'] == true,
        affectedAreas: _strings(map?['affected_areas']).toSet(),
        warningSigns: _strings(map?['warning_signs']).toSet(),
        notes: map?['limitation_notes']?.toString() ?? '',
      );
    } catch (_) {
      return const SafetyProfile(hasLimitation: false);
    }
  }

  List<String> _strings(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  Future<void> _startWorkout(CustomWorkout workout) async {
    final profile = await _currentSafetyProfile();
    final adaptation = SafetyEngine.adaptWorkout(
      workout.generatedWorkout,
      profile,
      location: 'Flexible',
    );
    if (!mounted) return;

    if (adaptation.blocksTraining) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.health_and_safety_outlined),
          title: Text(adaptation.title),
          content: Text(adaptation.guidance),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    var workoutToUse = workout.generatedWorkout;
    if (adaptation.status == SafetyStatus.modified) {
      final continueWithModified = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.health_and_safety_outlined),
          title: Text(adaptation.title),
          content: Text(
            '${adaptation.guidance}\n\nLeanIt will use the modified version for this session only. Your saved custom workout will not be overwritten.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('USE MODIFIED WORKOUT'),
            ),
          ],
        ),
      );
      if (continueWithModified != true || !mounted) return;
      workoutToUse = adaptation.workout;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveWorkoutScreen(workout: workoutToUse),
      ),
    );
  }

  Future<void> _delete(CustomWorkout workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete custom workout?'),
        content: Text('Delete “${workout.name}”? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _store.delete(workout.id);
    if (mounted) await _refresh();
  }

  String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        title: const Text('Custom workouts'),
        actions: [
          IconButton(
            tooltip: 'Create workout',
            onPressed: () => _openBuilder(),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<CustomWorkout>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final workouts = snapshot.data ?? const <CustomWorkout>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                const Text(
                  'Your workout library',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Build workouts once, change the sets/reps/rest you want, and reuse them whenever you train.',
                  style: TextStyle(
                    color: Color(0xFF627D98),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openBuilder(),
                    icon: const Icon(Icons.add_rounded),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: const Color(0xFF176B87),
                      foregroundColor: Colors.white,
                    ),
                    label: const Text(
                      'CREATE CUSTOM WORKOUT',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                if (workouts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD9E2EC)),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.view_list_rounded,
                          size: 48,
                          color: Color(0xFF829AB1),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No custom workouts yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF102A43),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Create one such as “My Chest Day”, “Home Full Body” or “Leg Day”.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF627D98)),
                        ),
                      ],
                    ),
                  )
                else
                  ...workouts.map(
                    (workout) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD9E2EC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5F4F8),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.fitness_center_rounded,
                                  color: Color(0xFF176B87),
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      workout.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF102A43),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${workout.exercises.length} exercises • updated ${_date(workout.updatedAt)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF627D98),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') _openBuilder(workout);
                                  if (value == 'delete') _delete(workout);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            workout.exercises
                                .take(4)
                                .map((exercise) => exercise.name)
                                .join(' • '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Color(0xFF486581),
                            ),
                          ),
                          if (workout.exercises.length > 4) ...[
                            const SizedBox(height: 4),
                            Text(
                              '+ ${workout.exercises.length - 4} more',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF829AB1),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _openBuilder(workout),
                                  child: const Text('EDIT'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _startWorkout(workout),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF176B87),
                                    foregroundColor: Colors.white,
                                  ),
                                  label: const Text('START'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CustomWorkoutBuilderScreen extends StatefulWidget {
  final SupabaseClient client;
  final CustomWorkoutStore store;
  final CustomWorkout? existing;

  const CustomWorkoutBuilderScreen({
    super.key,
    required this.client,
    required this.store,
    this.existing,
  });

  @override
  State<CustomWorkoutBuilderScreen> createState() =>
      _CustomWorkoutBuilderScreenState();
}

class _CustomWorkoutBuilderScreenState
    extends State<CustomWorkoutBuilderScreen> {
  late final TextEditingController _nameController;
  late final List<ExercisePrescription> _exercises;
  SafetyProfile? _safetyProfile;
  bool _profileLoading = true;
  bool _openingLibrary = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _exercises = List<ExercisePrescription>.from(
      widget.existing?.exercises ?? const [],
    );
    _loadSafetyProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSafetyProfile() async {
    try {
      final map = await ProfileService(widget.client).currentProfileMap();
      if (!mounted) return;
      setState(() {
        _safetyProfile = SafetyProfile(
          hasLimitation: map?['has_limitation'] == true,
          affectedAreas: _strings(map?['affected_areas']).toSet(),
          warningSigns: _strings(map?['warning_signs']).toSet(),
          notes: map?['limitation_notes']?.toString() ?? '',
        );
        _profileLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _safetyProfile = const SafetyProfile(hasLimitation: false);
        _profileLoading = false;
      });
    }
  }

  List<String> _strings(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  Future<void> _addExercises() async {
    if (_openingLibrary) return;
    setState(() => _openingLibrary = true);
    final selected = await Navigator.push<List<OnlineExercise>>(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseLibraryScreen(
          client: widget.client,
          selectionMode: true,
          safetyProfile: _safetyProfile,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _openingLibrary = false);
    if (selected == null || selected.isEmpty) return;

    final existingNames = _exercises
        .map((exercise) => exercise.name.trim().toLowerCase())
        .toSet();
    final additions = selected
        .where(
          (exercise) =>
              !existingNames.contains(exercise.name.trim().toLowerCase()),
        )
        .map(WorkoutEditorMapper.fromOnlineExercise)
        .toList(growable: false);
    if (additions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Those exercises are already included.')),
      );
      return;
    }
    setState(() {
      _exercises.addAll(additions);
      final normalized = SupersetEngine.normalize(_exercises);
      _exercises
        ..clear()
        ..addAll(normalized);
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final exercise = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, exercise);
      final normalized = SupersetEngine.normalize(_exercises);
      _exercises
        ..clear()
        ..addAll(normalized);
    });
  }

  void _remove(int index) {
    setState(() {
      _exercises.removeAt(index);
      final normalized = SupersetEngine.normalize(_exercises);
      _exercises
        ..clear()
        ..addAll(normalized);
    });
  }

  void _toggleSuperset(int index) {
    setState(() {
      final paired = SupersetEngine.hasValidPair(_exercises, index);
      final next = paired
          ? SupersetEngine.unpairAt(_exercises, index)
          : SupersetEngine.pairWithNext(_exercises, index);
      _exercises
        ..clear()
        ..addAll(next);
    });
  }

  Future<void> _configureDropSet(int index) async {
    final current = _exercises[index];
    if (!DropSetEngine.isLoadTrackedStrength(current)) return;
    if (current.supersetId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remove the superset pairing before adding a drop set.')),
      );
      return;
    }

    var drops = current.dropSetCount > 0 ? current.dropSetCount : 1;
    var reduction = current.dropSetReductionPercent;
    final config = await showDialog<DropSetConfig>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(current.dropSetCount > 0 ? 'Edit drop set' : 'Add drop set'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('The drop starts after the final normal set with no rest between load reductions.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: drops,
                decoration: const InputDecoration(labelText: 'Number of drops'),
                items: const [1, 2, 3]
                    .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => drops = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: reduction,
                decoration: const InputDecoration(labelText: 'Load reduction each drop'),
                items: const [10, 15, 20, 25, 30]
                    .map((value) => DropdownMenuItem(value: value, child: Text('$value%')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => reduction = value);
                },
              ),
            ],
          ),
          actions: [
            if (current.dropSetCount > 0)
              TextButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  const DropSetConfig(drops: 0, reductionPercent: 20),
                ),
                child: const Text('REMOVE'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                DropSetConfig(drops: drops, reductionPercent: reduction),
              ),
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
    if (config == null || !mounted) return;
    setState(() {
      _exercises[index] = DropSetEngine.configure(current, config);
    });
  }

  Future<void> _editPrescription(int index) async {
    final current = _exercises[index];
    final setsController = TextEditingController(text: '${current.sets}');
    final repsController = TextEditingController(text: current.reps);
    final restController = TextEditingController(text: current.rest);

    final updated = await showDialog<ExercisePrescription>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(current.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: setsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sets'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: repsController,
                decoration: const InputDecoration(
                  labelText: 'Reps / time',
                  hintText: 'Example: 8–12 or 45 sec',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: restController,
                decoration: const InputDecoration(
                  labelText: 'Rest',
                  hintText: 'Example: 75 sec',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final sets = int.tryParse(setsController.text.trim());
              final reps = repsController.text.trim();
              final rest = restController.text.trim();
              if (sets == null || sets < 1 || reps.isEmpty || rest.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter valid sets, reps/time and rest.'),
                  ),
                );
                return;
              }
              Navigator.pop(
                dialogContext,
                ExercisePrescription(
                  name: current.name,
                  sets: sets,
                  reps: reps,
                  rest: rest,
                  equipment: current.equipment,
                  target: current.target,
                  visualAsset: current.visualAsset,
                  metricLabel: current.metricLabel,
                  supersetId: current.supersetId,
                  dropSetCount: current.dropSetCount,
                  dropSetReductionPercent: current.dropSetReductionPercent,
                ),
              );
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    setsController.dispose();
    repsController.dispose();
    restController.dispose();
    if (updated == null || !mounted) return;
    setState(() => _exercises[index] = updated);
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give this workout a name.')),
      );
      return;
    }
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise.')),
      );
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final existing = widget.existing;
    final workout = CustomWorkout(
      id: existing?.id ?? now.microsecondsSinceEpoch.toString(),
      name: name,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      exercises: List<ExercisePrescription>.unmodifiable(
        SupersetEngine.normalize(_exercises),
      ),
    );
    await widget.store.save(workout);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context, workout);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        title: Text(widget.existing == null ? 'Create workout' : 'Edit workout'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Workout name',
                      hintText: 'Example: My Chest Day',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                  ),
                  if (_profileLoading) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(minHeight: 2),
                  ] else if (_safetyProfile?.hasLimitation == true) ...[
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Your saved limitation settings are applied when adding exercises and checked again when you start the workout.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Color(0xFF9A6700),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _exercises.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Text(
                          'Add exercises from LeanIt’s Exercise Library to build this workout.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF627D98)),
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      itemCount: _exercises.length,
                      onReorder: _reorder,
                      buildDefaultDragHandles: false,
                      itemBuilder: (context, index) {
                        final exercise = _exercises[index];
                        return Container(
                          key: ValueKey('custom-workout-${exercise.name}-$index'),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFD9E2EC)),
                          ),
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.drag_indicator_rounded,
                                    color: Color(0xFF829AB1),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _editPrescription(index),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exercise.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF102A43),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${exercise.summary} • Rest ${exercise.rest}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF176B87),
                                        ),
                                      ),
                                      if (exercise.dropSetCount > 0) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'DROP SET • ${DropSetEngine.badge(exercise)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF9A6700),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 3),
                                      const Text(
                                        'Tap to edit sets, reps/time and rest',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF829AB1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (SupersetEngine.hasValidPair(_exercises, index))
                                    Text(
                                      'SS ${SupersetEngine.positionLabel(_exercises, index)}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF176B87),
                                      ),
                                    ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (SupersetEngine.hasValidPair(_exercises, index) ||
                                          (index < _exercises.length - 1 &&
                                              _exercises[index].supersetId == null &&
                                              _exercises[index + 1].supersetId == null &&
                                              _exercises[index].dropSetCount == 0 &&
                                              _exercises[index + 1].dropSetCount == 0))
                                        IconButton(
                                          tooltip: SupersetEngine.hasValidPair(_exercises, index)
                                              ? 'Remove superset'
                                              : 'Pair with next exercise',
                                          onPressed: () => _toggleSuperset(index),
                                          icon: Icon(
                                            SupersetEngine.hasValidPair(_exercises, index)
                                                ? Icons.link_off_rounded
                                                : Icons.link_rounded,
                                          ),
                                        ),
                                      if (DropSetEngine.isLoadTrackedStrength(exercise) &&
                                          exercise.supersetId == null)
                                        IconButton(
                                          tooltip: exercise.dropSetCount > 0
                                              ? 'Edit drop set'
                                              : 'Add drop set',
                                          onPressed: () => _configureDropSet(index),
                                          icon: Icon(
                                            Icons.trending_down_rounded,
                                            color: exercise.dropSetCount > 0
                                                ? const Color(0xFF9A6700)
                                                : null,
                                          ),
                                        ),
                                      IconButton(
                                        tooltip: 'Remove exercise',
                                        onPressed: () => _remove(index),
                                        icon: const Icon(Icons.delete_outline_rounded),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _profileLoading || _openingLibrary
                      ? null
                      : _addExercises,
                  icon: _openingLibrary
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_rounded),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  label: Text(
                    _openingLibrary ? 'OPENING LIBRARY…' : 'ADD EXERCISES',
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    backgroundColor: const Color(0xFF176B87),
                    foregroundColor: Colors.white,
                  ),
                  label: Text(
                    _saving ? 'SAVING…' : 'SAVE WORKOUT',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
