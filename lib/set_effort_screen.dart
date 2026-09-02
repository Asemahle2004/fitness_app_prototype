import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise_performance_store.dart';
import 'set_effort_store.dart';
import 'unit_display.dart';

class SetEffortScreen extends StatefulWidget {
  const SetEffortScreen({super.key});

  @override
  State<SetEffortScreen> createState() => _SetEffortScreenState();
}

class _SetEffortScreenState extends State<SetEffortScreen> {
  late Future<_Data> _future;

  String get _scope =>
      Supabase.instance.client.auth.currentUser?.id ?? 'guest';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Data> _load() async {
    final sets = await ExercisePerformanceStore(Supabase.instance.client)
        .loadRecent(limit: 120);
    final efforts = await SetEffortStore(userScope: _scope).load();
    return _Data(sets: sets, efforts: efforts);
  }

  String _id(ExerciseSetPerformance set) =>
      'effort_${set.performedAt.microsecondsSinceEpoch}_${set.setNumber}';

  Future<void> _rate(
    ExerciseSetPerformance set,
    SetEffortRecord? existing,
  ) async {
    var rpe = existing?.rpe ?? 8.0;
    var rir = existing?.rir ?? 2;
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${set.exerciseName} • ${set.setLabel}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RPE describes overall set difficulty. RIR is how many controlled reps you believe remained.',
                style: TextStyle(fontSize: 13, color: Color(0xFF627D98)),
              ),
              const SizedBox(height: 18),
              Text('RPE ${rpe.toStringAsFixed(1)}'),
              Slider(
                value: rpe,
                min: 5,
                max: 10,
                divisions: 10,
                label: rpe.toStringAsFixed(1),
                onChanged: (value) => setDialogState(() => rpe = value),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: rir,
                decoration: const InputDecoration(labelText: 'Reps in reserve (RIR)'),
                items: List.generate(6, (index) => index)
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value RIR'),
                        ))
                    .toList(growable: false),
                onChanged: (value) => setDialogState(() => rir = value ?? rir),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
    if (save != true) return;
    await SetEffortStore(userScope: _scope).rateSet(
      id: _id(set),
      workoutTitle: set.workoutTitle,
      exerciseName: set.exerciseName,
      setNumber: set.setNumber,
      rpe: rpe,
      rir: rir,
      recordedAt: set.performedAt,
    );
    if (!mounted) return;
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Set effort • RPE / RIR'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: FutureBuilder<_Data>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          if (data.sets.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Complete strength sets first, then LeanIt can learn how hard individual sets felt.'),
              ),
            );
          }
          final byId = <String, SetEffortRecord>{
            for (final item in data.efforts) item.id: item,
          };
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: data.sets.length,
            itemBuilder: (context, index) {
              final set = data.sets[index];
              final effort = byId[_id(set)];
              return Card(
                child: ListTile(
                  title: Text(set.exerciseName),
                  subtitle: Text(
                    '${set.workoutTitle} • ${set.setLabel} • ${_summary(set)}\n'
                    '${set.performedAt.day}/${set.performedAt.month} ${set.performedAt.hour.toString().padLeft(2, '0')}:${set.performedAt.minute.toString().padLeft(2, '0')}',
                  ),
                  isThreeLine: true,
                  trailing: effort == null
                      ? const Chip(label: Text('RATE SET'))
                      : Chip(
                          label: Text(
                            'RPE ${effort.estimatedRpe.toStringAsFixed(1)} • RIR ${effort.estimatedRir}',
                          ),
                        ),
                  onTap: () => _rate(set, effort),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _summary(ExerciseSetPerformance set) {
    if (set.weightKg != null && set.reps != null) {
      return '${UnitDisplay.formatWeight(set.weightKg!)} × ${set.reps} reps';
    }
    return set.summary;
  }
}

class _Data {
  final List<ExerciseSetPerformance> sets;
  final List<SetEffortRecord> efforts;

  const _Data({required this.sets, required this.efforts});
}
