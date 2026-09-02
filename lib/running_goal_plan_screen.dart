import 'package:flutter/material.dart';

import 'live_run_screen.dart';
import 'running_distance_engine.dart';
import 'running_weather_service.dart';

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
  final _benchmarkTime = TextEditingController();
  RunningTrainingPlan? _plan;
  RunningWeatherConditions? _weather;
  bool _loadingWeather = false;

  @override
  void dispose() {
    _recentKm.dispose();
    _benchmarkDistance.dispose();
    _benchmarkTime.dispose();
    super.dispose();
  }

  void _generate() {
    final benchmarkDistance = double.tryParse(
      _benchmarkDistance.text.trim().replaceAll(',', '.'),
    );
    final benchmarkTime = double.tryParse(
      _benchmarkTime.text.trim().replaceAll(',', '.'),
    );
    final distanceMeters = benchmarkDistance == null
        ? null
        : (_goal.isSprint ? benchmarkDistance : benchmarkDistance * 1000);
    final seconds = benchmarkTime == null
        ? null
        : (_goal.isSprint ? benchmarkTime : benchmarkTime * 60);
    setState(() {
      _plan = RunningDistanceEngine.generate(
        RunningPlanConfig(
          goal: _goal,
          level: _level,
          daysPerWeek: _days,
          totalWeeks: _weeks,
          recentWeeklyKm:
              double.tryParse(_recentKm.text.trim().replaceAll(',', '.')) ?? 0,
          benchmarkDistanceMeters: distanceMeters,
          benchmarkSeconds: seconds,
        ),
      );
    });
  }

  Future<void> _checkWeather() async {
    if (_loadingWeather) return;
    setState(() => _loadingWeather = true);
    try {
      final weather = await const RunningWeatherService().currentForDevice();
      if (!mounted) return;
      setState(() => _weather = weather);
      if (weather == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Current weather is unavailable. Check location permission/service or try again later.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load current running weather.')),
      );
    } finally {
      if (mounted) setState(() => _loadingWeather = false);
    }
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
                      _weather = null;
                      _benchmarkDistance.clear();
                      _benchmarkTime.clear();
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
                  decoration: InputDecoration(
                    labelText: _goal.isSprint
                        ? 'Benchmark distance (metres)'
                        : 'Benchmark distance (km)',
                    hintText: _goal.isSprint ? 'e.g. 100' : 'e.g. 5',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _benchmarkTime,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _goal.isSprint
                        ? 'Benchmark time (seconds)'
                        : 'Benchmark time (minutes)',
                    hintText: _goal.isSprint ? 'e.g. 13.2' : 'e.g. 28.5',
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Short-event predictions stay inside the sprint family instead of extrapolating a 100 m performance into marathon pace.',
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadingWeather ? null : _checkWeather,
              icon: const Icon(Icons.wb_sunny_outlined),
              label: Text(
                _loadingWeather ? 'CHECKING WEATHER…' : 'CHECK LIVE RUNNING WEATHER',
              ),
            ),
            if (_weather != null) ...[
              const SizedBox(height: 12),
              _weatherCard(_weather!),
            ],
            const SizedBox(height: 18),
            ..._plan!.weeks.map(_weekCard),
          ],
        ],
      ),
    );
  }

  Widget _planOverview(RunningTrainingPlan plan) {
    final zones = plan.paceZones;
    final prediction = plan.config.benchmarkDistanceMeters == null ||
            plan.config.benchmarkSeconds == null
        ? null
        : RunningDistanceEngine.predict(
            benchmarkDistanceMeters: plan.config.benchmarkDistanceMeters!,
            benchmarkSeconds: plan.config.benchmarkSeconds!,
            goal: plan.config.goal,
          );
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
          if (prediction != null) ...[
            const SizedBox(height: 8),
            Text(
              'Model estimate for ${prediction.goal.label}: ${_duration(prediction.predictedSeconds)} • ${prediction.confidence.toLowerCase()} confidence',
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

  Widget _weatherCard(RunningWeatherConditions weather) {
    final adjustment = weather.adjustmentFor(_goal);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD58A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.thermostat_rounded, color: Color(0xFF9A6700)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${weather.temperatureC.toStringAsFixed(1)}°C • ${weather.humidityPercent.round()}% humidity'
                  '${weather.windKmh == null ? '' : ' • ${weather.windKmh!.round()} km/h wind'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            adjustment.headline,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B4F00),
            ),
          ),
          const SizedBox(height: 5),
          ...adjustment.notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text('• $note', style: const TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Weather: ${weather.source}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF829AB1)),
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

  static String _duration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '$minutes:${secs.toString().padLeft(2, '0')}';
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
