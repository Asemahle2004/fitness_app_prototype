import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'advanced_strength_progression_engine.dart';
import 'exercise_performance_store.dart';
import 'muscle_intelligence_engine.dart';
import 'set_effort_screen.dart';
import 'set_effort_store.dart';
import 'strength_adaptation_cache.dart';
import 'unit_display.dart';

class StrengthIntelligenceScreen extends StatefulWidget {
  const StrengthIntelligenceScreen({super.key});

  @override
  State<StrengthIntelligenceScreen> createState() =>
      _StrengthIntelligenceScreenState();
}

class _StrengthIntelligenceScreenState
    extends State<StrengthIntelligenceScreen> {
  late Future<_StrengthData> _future;

  String get _scope =>
      Supabase.instance.client.auth.currentUser?.id ?? 'guest';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StrengthData> _load() async {
    final sets = await ExercisePerformanceStore(Supabase.instance.client).loadAll();
    final efforts = await SetEffortStore(userScope: _scope).load();
    final report = MuscleIntelligenceEngine.analyse(
      sets: sets,
      efforts: efforts,
    );
    final names = sets
        .where((item) => !item.isDropSet)
        .map((item) => item.exerciseName)
        .toSet()
        .toList(growable: false)
      ..sort();
    return _StrengthData(
      sets: sets,
      efforts: efforts,
      report: report,
      exerciseNames: names,
    );
  }

  Future<void> _showProgression(
    String exerciseName,
    _StrengthData data,
  ) async {
    final recommendation = AdvancedStrengthProgressionEngine.recommend(
      exerciseName: exerciseName,
      history: data.sets,
      efforts: data.efforts,
      globalAdaptation: StrengthAdaptationCache.current,
      muscleReport: data.report,
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exerciseName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF102A43),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                recommendation.headline,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF176B87),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                recommendation.explanation,
                style: const TextStyle(height: 1.45, color: Color(0xFF486581)),
              ),
              if (recommendation.targetWeightKg != null ||
                  recommendation.targetReps != null) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (recommendation.targetWeightKg != null)
                      Chip(
                        label: Text(
                          'Target ${UnitDisplay.formatWeight(recommendation.targetWeightKg!)}',
                        ),
                      ),
                    if (recommendation.targetReps != null)
                      Chip(label: Text('${recommendation.targetReps} reps')),
                    if (recommendation.estimatedOneRepMaxKg != null)
                      Chip(
                        label: Text(
                          'Est. 1RM ${UnitDisplay.formatWeight(recommendation.estimatedOneRepMaxKg!)}',
                        ),
                      ),
                  ],
                ),
              ],
              if (recommendation.backOffSets != null) ...[
                const SizedBox(height: 10),
                Text(
                  '${recommendation.backOffSets} back-off sets at about ${((recommendation.backOffLoadMultiplier ?? 0.9) * 100).round()}% of the top-set load.',
                  style: const TextStyle(color: Color(0xFF627D98)),
                ),
              ],
              const SizedBox(height: 14),
              ...recommendation.reasons.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text('• $reason'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Strength intelligence'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: FutureBuilder<_StrengthData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
              children: [
                const Text(
                  'Muscle recovery & weekly volume',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'These are training-readiness estimates from recent sets, time since training and set effort. They are not a medical recovery measurement.',
                  style: TextStyle(height: 1.45, color: Color(0xFF627D98)),
                ),
                const SizedBox(height: 18),
                ...data.report.muscles.map(_muscleCard),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () async {
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute(builder: (_) => const SetEffortScreen()),
                    );
                    if (!mounted) return;
                    setState(() => _future = _load());
                  },
                  icon: const Icon(Icons.speed_rounded),
                  label: const Text('LOG SET RPE / RIR'),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Advanced exercise progression',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'LeanIt checks repeated performance, recovery, RPE/RIR and plateaus before adding reps or load.',
                  style: TextStyle(color: Color(0xFF627D98)),
                ),
                const SizedBox(height: 10),
                if (data.exerciseNames.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Complete strength workouts to unlock exercise-specific progression.'),
                    ),
                  )
                else
                  ...data.exerciseNames.take(30).map(
                        (name) => Card(
                          child: ListTile(
                            title: Text(name),
                            subtitle: const Text('Open LeanIt progression decision'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _showProgression(name, data),
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

  Widget _muscleCard(MuscleTrainingStatus status) {
    final recovery = status.recoveryPercent.clamp(0, 100).toDouble();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    status.muscle.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text('${recovery.round()}% recovered'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: recovery / 100),
            const SizedBox(height: 8),
            Text(
              '${status.currentWeekSets} sets this week • ${status.previousWeekSets} previous week • ${status.loadStatus.name}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF627D98)),
            ),
            if (status.currentWeekVolumeKg > 0)
              Text(
                'Weighted volume: ${UnitDisplay.formatWeight(status.currentWeekVolumeKg, decimals: 0)}·reps',
                style: const TextStyle(fontSize: 12, color: Color(0xFF829AB1)),
              ),
          ],
        ),
      ),
    );
  }
}

class _StrengthData {
  final List<ExerciseSetPerformance> sets;
  final List<SetEffortRecord> efforts;
  final MuscleIntelligenceReport report;
  final List<String> exerciseNames;

  const _StrengthData({
    required this.sets,
    required this.efforts,
    required this.report,
    required this.exerciseNames,
  });
}
