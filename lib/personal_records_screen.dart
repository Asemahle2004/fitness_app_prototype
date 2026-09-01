import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise_performance_store.dart';
import 'personal_record_engine.dart';
import 'run_tracking_store.dart';

enum _RecordFilter { all, strength, running }

class PersonalRecordsScreen extends StatefulWidget {
  const PersonalRecordsScreen({super.key});

  @override
  State<PersonalRecordsScreen> createState() => _PersonalRecordsScreenState();
}

class _PersonalRecordsScreenState extends State<PersonalRecordsScreen> {
  late Future<_PersonalRecordsData> _future;
  _RecordFilter _filter = _RecordFilter.all;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_PersonalRecordsData> _load() async {
    final setsFuture = ExercisePerformanceStore(
      Supabase.instance.client,
    ).loadAll();
    final runsFuture = RunTrackingStore.load();

    final sets = await setsFuture;
    final runs = await runsFuture;
    return _PersonalRecordsData(
      current: PersonalRecordEngine.currentRecords(sets: sets, runs: runs),
      history: PersonalRecordEngine.recordHistory(sets: sets, runs: runs),
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  bool _matches(PersonalRecordAchievement record) {
    switch (_filter) {
      case _RecordFilter.all:
        return true;
      case _RecordFilter.strength:
        return !record.isRunning;
      case _RecordFilter.running:
        return record.isRunning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Personal records'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: FutureBuilder<_PersonalRecordsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? const _PersonalRecordsData();
          final filteredCurrent = data.current.where(_matches).toList();
          final filteredHistory = data.history.where(_matches).toList();
          final strengthExercises = data.current
              .where((record) => !record.isRunning)
              .map((record) => record.subject.toLowerCase())
              .toSet()
              .length;
          final runningRecords =
              data.current.where((record) => record.isRunning).length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
              children: [
                const Text(
                  'Your best performances',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'LeanIt calculates records from your saved normal working sets and runs. Drop sets are excluded from strength PRs, and running pace records require at least 500 m.',
                  style: TextStyle(
                    color: Color(0xFF627D98),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _SummaryCard(
                      icon: Icons.emoji_events_rounded,
                      label: 'Current PRs',
                      value: '${data.current.length}',
                    ),
                    _SummaryCard(
                      icon: Icons.fitness_center_rounded,
                      label: 'Exercises',
                      value: '$strengthExercises',
                    ),
                    _SummaryCard(
                      icon: Icons.directions_run_rounded,
                      label: 'Running PRs',
                      value: '$runningRecords',
                    ),
                    _SummaryCard(
                      icon: Icons.history_rounded,
                      label: 'PR moments',
                      value: '${data.history.length}',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _filter == _RecordFilter.all,
                      onSelected: (_) =>
                          setState(() => _filter = _RecordFilter.all),
                    ),
                    ChoiceChip(
                      label: const Text('Strength'),
                      selected: _filter == _RecordFilter.strength,
                      onSelected: (_) =>
                          setState(() => _filter = _RecordFilter.strength),
                    ),
                    ChoiceChip(
                      label: const Text('Running'),
                      selected: _filter == _RecordFilter.running,
                      onSelected: (_) =>
                          setState(() => _filter = _RecordFilter.running),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const Text(
                  'Current personal records',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'These are your current all-time bests from the history LeanIt can access.',
                  style: TextStyle(
                    color: Color(0xFF627D98),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                if (filteredCurrent.isEmpty)
                  const _EmptyRecordsCard(
                    text:
                        'No personal records are available in this category yet. Complete a workout or save a run to establish your first benchmark.',
                  )
                else
                  ...filteredCurrent.map(
                    (record) => _CurrentRecordCard(record: record),
                  ),
                const SizedBox(height: 28),
                const Text(
                  'Personal record history',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Every time a saved performance established or beat the best result that existed at that point, it appears here.',
                  style: TextStyle(
                    color: Color(0xFF627D98),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                if (filteredHistory.isEmpty)
                  const _EmptyRecordsCard(
                    text: 'Your PR history will appear as you log performances.',
                  )
                else
                  ...filteredHistory.take(100).map(
                    (record) => _RecordHistoryTile(record: record),
                  ),
                if (filteredHistory.length > 100) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Showing the latest 100 of ${filteredHistory.length} record moments.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF829AB1),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PersonalRecordsData {
  final List<PersonalRecordAchievement> current;
  final List<PersonalRecordAchievement> history;

  const _PersonalRecordsData({
    this.current = const <PersonalRecordAchievement>[],
    this.history = const <PersonalRecordAchievement>[],
  });
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFB7791F)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF627D98),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentRecordCard extends StatelessWidget {
  final PersonalRecordAchievement record;

  const _CurrentRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final d = record.achievedAt;
    final date = '${d.day}/${d.month}/${d.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4D7A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFF4CC),
            child: Icon(
              _metricIcon(record.metric),
              color: const Color(0xFFB7791F),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  record.metric.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF627D98),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  record.displayValue,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB7791F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date • ${record.detail}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF829AB1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordHistoryTile extends StatelessWidget {
  final PersonalRecordAchievement record;

  const _RecordHistoryTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final d = record.achievedAt;
    final date = '${d.day}/${d.month}/${d.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _metricIcon(record.metric),
              size: 19,
              color: const Color(0xFF176B87),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.subject} • ${record.metric.label}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.displayValue,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF176B87),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${record.previousLabel} • $date',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF627D98),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecordsCard extends StatelessWidget {
  final String text;

  const _EmptyRecordsCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF627D98), height: 1.4),
      ),
    );
  }
}

IconData _metricIcon(PersonalRecordMetric metric) {
  switch (metric) {
    case PersonalRecordMetric.heaviestLoad:
      return Icons.monitor_weight_outlined;
    case PersonalRecordMetric.mostReps:
      return Icons.repeat_rounded;
    case PersonalRecordMetric.setVolume:
      return Icons.stacked_line_chart_rounded;
    case PersonalRecordMetric.timedDuration:
      return Icons.timer_outlined;
    case PersonalRecordMetric.longestRun:
      return Icons.route_rounded;
    case PersonalRecordMetric.fastestPace:
      return Icons.speed_rounded;
  }
}
