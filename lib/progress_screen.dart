import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise_performance_store.dart';
import 'exercise_progress_entry_section.dart';
import 'training_store.dart';
import 'workout_calendar_entry_section.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<_ProgressData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadProgress();
  }

  Future<_ProgressData> _loadProgress() async {
    final workoutsFuture = TrainingStore.loadWorkouts();
    final setsFuture = ExercisePerformanceStore(
      Supabase.instance.client,
    ).loadRecent(limit: 150);

    return _ProgressData(
      workouts: await workoutsFuture,
      sets: await setsFuture,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadProgress());
    await _future;
  }

  int _streak(List<WorkoutRecord> records) {
    if (records.isEmpty) return 0;
    final days = records
        .map(
          (r) => DateTime(
            r.completedAt.year,
            r.completedAt.month,
            r.completedAt.day,
          ),
        )
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    var streak = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i - 1].difference(days[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  String _duration(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  String _volume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}k kg·reps';
    }
    return '${volume.round()} kg·reps';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Progress'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: FutureBuilder<_ProgressData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? const _ProgressData();
          final records = data.workouts;
          final sets = data.sets;
          final totalSeconds = records.fold<int>(
            0,
            (sum, r) => sum + r.durationSeconds,
          );
          final totalSets = records.fold<int>(
            0,
            (sum, r) => sum + r.completedSets,
          );
          final totalVolume = sets.fold<double>(
            0,
            (sum, set) => sum + set.volumeKg,
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Your training progress',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'LeanIt keeps workout and set history on this device first, so your progress still works when you train offline.',
                  style: TextStyle(
                    color: Color(0xFF627D98),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(
                      label: 'Workouts',
                      value: '${records.length}',
                      icon: Icons.fitness_center,
                    ),
                    _StatCard(
                      label: 'Training time',
                      value: _duration(totalSeconds),
                      icon: Icons.timer_outlined,
                    ),
                    _StatCard(
                      label: 'Sets completed',
                      value: '$totalSets',
                      icon: Icons.repeat,
                    ),
                    _StatCard(
                      label: 'Logged sets',
                      value: '${sets.length}',
                      icon: Icons.fact_check_outlined,
                    ),
                    _StatCard(
                      label: 'Logged volume',
                      value: _volume(totalVolume),
                      icon: Icons.monitor_weight_outlined,
                    ),
                    _StatCard(
                      label: 'Current streak',
                      value: '${_streak(records)} days',
                      icon: Icons.local_fire_department_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                WorkoutCalendarEntrySection(records: records),
                const SizedBox(height: 28),
                ExerciseProgressEntrySection(sets: sets),
                const SizedBox(height: 28),
                const Text(
                  'Recent set performance',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your most recent logged sets become the reference LeanIt can use for future progression targets.',
                  style: TextStyle(
                    color: Color(0xFF627D98),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                if (sets.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Complete a set in Live Workout Mode and your reps, load or timed result will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF627D98)),
                    ),
                  )
                else
                  ...sets.take(20).map(
                        (set) => _SetPerformanceTile(performance: set),
                      ),
                const SizedBox(height: 28),
                const Text(
                  'Recent workouts',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 12),
                if (records.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Complete your first live workout and it will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF627D98)),
                    ),
                  )
                else
                  ...records.take(20).map(
                        (record) => _WorkoutTile(record: record),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProgressData {
  final List<WorkoutRecord> workouts;
  final List<ExerciseSetPerformance> sets;

  const _ProgressData({
    this.workouts = const <WorkoutRecord>[],
    this.sets = const <ExerciseSetPerformance>[],
  });
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF176B87)),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF627D98)),
          ),
        ],
      ),
    );
  }
}

class _SetPerformanceTile extends StatelessWidget {
  final ExerciseSetPerformance performance;

  const _SetPerformanceTile({required this.performance});

  @override
  Widget build(BuildContext context) {
    final d = performance.performedAt;
    final date = '${d.day}/${d.month}/${d.year}';
    final suggestion = performance.nextTargetSuggestion;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE5F4F8),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF176B87),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      performance.exerciseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      performance.summary,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF176B87),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${performance.workoutTitle} • Set ${performance.setNumber} • $date',
                      style: const TextStyle(
                        color: Color(0xFF627D98),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (suggestion != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                suggestion,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: Color(0xFF486581),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  final WorkoutRecord record;

  const _WorkoutTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final d = record.completedAt;
    final date = '${d.day}/${d.month}/${d.year}';
    final minutes = (record.durationSeconds / 60).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE5F4F8),
            child: Icon(Icons.check, color: Color(0xFF176B87)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date • $minutes min • ${record.completedSets} sets',
                  style: const TextStyle(
                    color: Color(0xFF627D98),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.exercises.length} exercises',
                  style: const TextStyle(
                    color: Color(0xFF829AB1),
                    fontSize: 12,
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
