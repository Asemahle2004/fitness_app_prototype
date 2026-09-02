import 'package:flutter/material.dart';

import 'training_store.dart';

class WorkoutFeedbackScreen extends StatefulWidget {
  const WorkoutFeedbackScreen({super.key});

  @override
  State<WorkoutFeedbackScreen> createState() => _WorkoutFeedbackScreenState();
}

class _WorkoutFeedbackScreenState extends State<WorkoutFeedbackScreen> {
  late Future<List<WorkoutRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = TrainingStore.loadWorkouts();
  }

  Future<void> _refresh() async {
    setState(() => _future = TrainingStore.loadWorkouts());
    await _future;
  }

  Future<void> _edit(WorkoutRecord record) async {
    var effort = record.perceivedEffort ?? 'about_right';
    var rpe = record.sessionRpe?.toDouble() ?? 7.0;
    final note = TextEditingController(text: record.feedbackNote ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'How hard did the whole session feel? This helps LeanIt distinguish productive training from accumulating fatigue.',
                    style: TextStyle(color: Color(0xFF627D98), height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'easy', label: Text('Easy')),
                      ButtonSegment(
                        value: 'about_right',
                        label: Text('About right'),
                      ),
                      ButtonSegment(value: 'hard', label: Text('Hard')),
                    ],
                    selected: {effort},
                    onSelectionChanged: (value) {
                      setSheetState(() => effort = value.first);
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Session RPE',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '${rpe.round()}/10',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF176B87),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: rpe,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${rpe.round()}',
                    onChanged: (value) => setSheetState(() => rpe = value),
                  ),
                  const Text(
                    '1–3 very easy • 4–6 moderate • 7–8 hard but controlled • 9–10 near maximal',
                    style: TextStyle(fontSize: 12, color: Color(0xFF829AB1)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: note,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 250,
                    decoration: const InputDecoration(
                      labelText: 'Training note (optional)',
                      hintText: 'Example: last two sets slowed down, legs still sore...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await TrainingStore.updateWorkoutFeedback(
                          completedAt: record.completedAt,
                          effort: effort,
                          sessionRpe: rpe.round(),
                          note: note.text,
                        );
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext, true);
                        }
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('SAVE FEEDBACK'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    note.dispose();
    if (saved == true) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Workout effort & RPE'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: FutureBuilder<List<WorkoutRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data ?? const <WorkoutRecord>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'How training actually felt',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'RPE is a 1–10 whole-session effort score. LeanIt combines it with readiness, set performance and weekly load; one hard day alone does not automatically cause a deload.',
                  style: TextStyle(color: Color(0xFF627D98), height: 1.45),
                ),
                const SizedBox(height: 18),
                if (records.isEmpty)
                  _empty()
                else
                  ...records.take(30).map(
                        (record) => Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(14),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFE5F4F8),
                              child: Text(
                                record.sessionRpe?.toString() ?? '—',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF176B87),
                                ),
                              ),
                            ),
                            title: Text(
                              record.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${_date(record.completedAt)} • ${record.completedSets} sets • ${_effort(record.perceivedEffort)}'
                              '${record.sessionRpe == null ? '' : ' • RPE ${record.sessionRpe}/10'}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _edit(record),
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

  Widget _empty() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'Complete a workout first. LeanIt will then let you add an effort score and RPE.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF627D98)),
        ),
      );

  static String _date(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';

  static String _effort(String? value) {
    switch (value) {
      case 'easy':
        return 'Easy';
      case 'hard':
        return 'Hard';
      case 'about_right':
        return 'About right';
      default:
        return 'No effort rating';
    }
  }
}
