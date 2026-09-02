import 'package:flutter/material.dart';

import 'live_run_screen.dart';
import 'running_distance_engine.dart';

class RunningGoalPlanScreen extends StatefulWidget {
  const RunningGoalPlanScreen({super.key});

  @override
  State<RunningGoalPlanScreen> createState() => _RunningGoalPlanScreenState();
}

class _RunningGoalPlanScreenState extends State<RunningGoalPlanScreen> {
  RunningGoalDistance _goal = RunningGoalDistance.k5;
  String _level = 'Beginner';
  int _days = 4;
  int _weeks = 10;
  final _recentKm = TextEditingController();
  final _benchmarkDistance = TextEditingController();
  final _benchmarkMinutes = TextEditingController();
  RunningTrainingPlan? _plan;

  @override
  void dispose() {
    _recentKm.dispose();
    _benchmarkDistance.dispose();
    _benchmarkMinutes.dispose();
    super.dispose();
  }

  void _generate() {
    final benchmarkKm = double.tryParse(
      _benchmarkDistance.text.trim().replaceAll(',', '.'),
    );
    final benchmarkMinutes = double.tryParse(
      _benchmarkMinutes.text.trim().replaceAll(',', '.'),
    );
    setState(() {
      _plan = RunningDistanceEngine.generate(
        RunningPlanConfig(
          goal: _goal,
          level: _level,
          daysPerWeek: _days,
          totalWeeks: _weeks,
          recentWeeklyKm:
              double.tryParse(_recentKm.text.trim().replaceAll(',', '.')) ?? 0,
          benchmarkDistanceMeters:
              benchmarkKm == null ? null : benchmarkKm * 1000,
          benchmarkSeconds:
              benchmarkMinutes == null ? null : benchmarkMinutes * 60,
        ),
      );
    });
  }

  Future<void> _start(RunningPlannedSession session) async {
    final guided = RunningDistanceEngine.toGuidedPlan(session);
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LiveRunScreen(guidedPlan: guided)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Train for a distance'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          const Text(
            '100 m to Marathon',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'LeanIt treats sprinting, middle distance and endurance as different sports. Choose the event you actually want to train for.',
            style: TextStyle(height: 1.5, color: Color(0xFF627D98)),
          ),
          const SizedBox(height: 20),
          _section(
            'Goal event',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RunningGoalDistance.values.map((goal) {
                return ChoiceChip(
                  label: Text(goal.label),
                  selected: _goal == goal,
                  onSelected: (_) {
                    setState(() {
                      _goal = goal;
                      _weeks = goal.minimumRecommendedWeeks;
                      _days = goal.recommendedDaysPerWeek;
                      _plan = null;
                    });
                  },
                );
              }).toList(growable: false),
            ),
          ),
          const SizedBox(height: 12),
          _section(
            'Training setup',
            Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _level,
                  decoration: const InputDecoration(labelText: 'Experience'),
                  items: const ['Beginner', 'Intermediate', 'Experienced']
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _level = value ?? _level;
                    _plan = null;
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _days,
                        decoration: const InputDecoration(labelText: 'Days / week'),
                        items: List.generate(6, (i) => i + 2)
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text('$value days'),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() {
                          _days = value ?? _days;
                          _plan = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _weeks,
                        decoration: const InputDecoration(labelText: 'Plan length'),
                        items: List.generate(25, (i) => i + 8)
                            .where((value) => value >= _goal.minimumRecommendedWeeks)
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text('$value weeks'),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() {
                          _weeks = value ?? _weeks;
                          _plan = null;
                        }),
                      ),
                    ),
                  ],
                ),
                if (!_goal.isSprint) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _recentKm,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Recent weekly distance (km, optional)',
                      hintText: 'e.g. 20',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            'Recent performance (optional)',
            Column(
              children: [
                TextField(
                  controller: _benchmarkDistance,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Benchmark distance (km)',
                    hintText: 'e.g. 5',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _benchmarkMinutes,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Benchmark time (minutes)',
                    hintText: 'e.g. 28.5',
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'For 100–400 m athletes, short-event predictions are kept separate from endurance predictions instead of extrapolating a sprint into a marathon.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF829AB1)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('BUILD TRAINING PLAN'),
          ),
          if (_plan != null) ...[
            const SizedBox(height: 24),
            _planOverview(_plan!),
            const SizedBox(height: 18),
            ..._plan!.weeks.map(_weekCard),
          ],
        ],
      ),
    );
  }

  Widget _planOverview(RunningTrainingPlan plan) {
    final zones = plan.paceZones;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${plan.config.goal.label} • ${plan.config.level}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${plan.weeks.length} weeks • ${plan.config.daysPerWeek} training days/week • ${plan.config.goal.discipline.name}',
            style: const TextStyle(color: Colors.white70),
          ),
          if (zones != null) ...[
            const SizedBox(height: 12),
            Text(
              'Easy: ${_pace(zones.easyMinSecondsPerKm)}–${_pace(zones.easyMaxSecondsPerKm)} /km • Threshold: ${_pace(zones.thresholdSecondsPerKm)} /km',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          ...plan.coachingNotes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('• $note', style: const TextStyle(color: Colors.white70)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekCard(RunningPlanWeek week) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            children: [
              Expanded(
                child: Text(
                  'Week ${week.weekNumber} • ${week.phase}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
              ),
              if (week.recoveryWeek || week.taperWeek)
                Chip(label: Text(week.taperWeek ? 'TAPER' : 'RECOVERY')),
            ],
          ),
          if (week.plannedKm > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                '${week.plannedKm.toStringAsFixed(1)} planned km',
                style: const TextStyle(color: Color(0xFF627D98)),
              ),
            ),
          ...week.sessions.map(
            (session) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_icon(session.type), color: const Color(0xFF176B87)),
              title: Text(session.title),
              subtitle: Text('${session.prescription}\n${session.intensity}'),
              isThreeLine: true,
              trailing: session.guidedCompatible
                  ? IconButton(
                      tooltip: 'Start guided session',
                      onPressed: () => _start(session),
                      icon: const Icon(Icons.play_circle_fill_rounded),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  static String _pace(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  static IconData _icon(RunningSessionType type) => switch (type) {
        RunningSessionType.acceleration ||
        RunningSessionType.maxVelocity ||
        RunningSessionType.speedEndurance => Icons.bolt_rounded,
        RunningSessionType.longRun => Icons.route_rounded,
        RunningSessionType.threshold || RunningSessionType.intervals =>
          Icons.speed_rounded,
        RunningSessionType.taper => Icons.flag_outlined,
        RunningSessionType.strengthSupport => Icons.fitness_center_rounded,
        _ => Icons.directions_run_rounded,
      };
}
