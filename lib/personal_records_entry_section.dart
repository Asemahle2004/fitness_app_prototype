import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise_performance_store.dart';
import 'personal_record_engine.dart';
import 'personal_records_screen.dart';
import 'run_tracking_store.dart';

class PersonalRecordsEntrySection extends StatefulWidget {
  const PersonalRecordsEntrySection({super.key});

  @override
  State<PersonalRecordsEntrySection> createState() =>
      _PersonalRecordsEntrySectionState();
}

class _PersonalRecordsEntrySectionState extends State<PersonalRecordsEntrySection> {
  late Future<_EntryData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_EntryData> _load() async {
    final setsFuture = ExercisePerformanceStore(
      Supabase.instance.client,
    ).loadAll();
    final runsFuture = RunTrackingStore.load();
    final sets = await setsFuture;
    final runs = await runsFuture;
    final current = PersonalRecordEngine.currentRecords(sets: sets, runs: runs);
    final history = PersonalRecordEngine.recordHistory(sets: sets, runs: runs);
    return _EntryData(current: current, history: history);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EntryData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _EntryData();
        final latest = data.history.isEmpty ? null : data.history.first;
        final exerciseCount = data.current
            .where((record) => !record.isRunning)
            .map((record) => record.subject.toLowerCase())
            .toSet()
            .length;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4D7A5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFFF4CC),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFB7791F),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal records',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF102A43),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Your all-time best strength, timed and running results.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF627D98),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(minHeight: 3)
              else if (data.current.isEmpty)
                const Text(
                  'Complete logged working sets or runs to establish your first personal records.',
                  style: TextStyle(
                    color: Color(0xFF627D98),
                    height: 1.4,
                  ),
                )
              else ...[
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text(
                      '${data.current.length} current PRs',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF486581),
                      ),
                    ),
                    Text(
                      '$exerciseCount exercises',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF486581),
                      ),
                    ),
                  ],
                ),
                if (latest != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFAEB),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      'Latest • ${latest.subject} • ${latest.metric.label}: ${latest.displayValue}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF805B10),
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PersonalRecordsScreen(),
                      ),
                    ).then((_) {
                      if (!mounted) return;
                      setState(() => _future = _load());
                    });
                  },
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: const Text('OPEN PERSONAL RECORDS'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EntryData {
  final List<PersonalRecordAchievement> current;
  final List<PersonalRecordAchievement> history;

  const _EntryData({
    this.current = const <PersonalRecordAchievement>[],
    this.history = const <PersonalRecordAchievement>[],
  });
}
