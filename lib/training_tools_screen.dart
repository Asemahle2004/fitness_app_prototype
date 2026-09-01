import 'package:flutter/material.dart';

import 'training_settings.dart';
import 'training_tools_engine.dart';

class TrainingToolsScreen extends StatefulWidget {
  final TrainingSettings settings;

  const TrainingToolsScreen({
    super.key,
    required this.settings,
  });

  @override
  State<TrainingToolsScreen> createState() => _TrainingToolsScreenState();
}

class _TrainingToolsScreenState extends State<TrainingToolsScreen> {
  final _oneRmWeight = TextEditingController();
  final _oneRmReps = TextEditingController(text: '8');
  final _paceDistance = TextEditingController(text: '5');
  final _paceTime = TextEditingController(text: '25:00');
  final _plateTarget = TextEditingController(text: '60');
  late final TextEditingController _barWeight;

  @override
  void initState() {
    super.initState();
    _barWeight = TextEditingController(
      text: widget.settings.isMetric ? '20' : '45',
    );
  }

  @override
  void dispose() {
    _oneRmWeight.dispose();
    _oneRmReps.dispose();
    _paceDistance.dispose();
    _paceTime.dispose();
    _plateTarget.dispose();
    _barWeight.dispose();
    super.dispose();
  }

  double? _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  int? _durationSeconds(String raw) {
    final parts = raw.trim().split(':').map(int.tryParse).toList();
    if (parts.any((part) => part == null)) return null;
    final values = parts.cast<int>();
    if (values.length == 2) {
      if (values[1] > 59) return null;
      return values[0] * 60 + values[1];
    }
    if (values.length == 3) {
      if (values[1] > 59 || values[2] > 59) return null;
      return values[0] * 3600 + values[1] * 60 + values[2];
    }
    return null;
  }

  String _duration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Training tools'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Text(
            'Useful numbers, connected to training',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'LeanIt keeps stored training data in metric base values and converts only what you see. Your history stays unchanged when you switch units.',
            style: const TextStyle(color: Color(0xFF627D98), height: 1.45),
          ),
          const SizedBox(height: 20),
          _oneRmCard(settings),
          const SizedBox(height: 14),
          _paceCard(settings),
          const SizedBox(height: 14),
          _plateCard(settings),
        ],
      ),
    );
  }

  Widget _oneRmCard(TrainingSettings settings) {
    final entered = _number(_oneRmWeight);
    final reps = int.tryParse(_oneRmReps.text.trim());
    double? oneRmKg;
    if (entered != null && reps != null && reps > 0) {
      final kg = TrainingToolsEngine.toCanonicalWeight(entered, settings.unitSystem);
      oneRmKg = TrainingToolsEngine.estimatedOneRepMaxKg(weightKg: kg, reps: reps);
    }
    final working = oneRmKg == null
        ? const <int, double>{}
        : TrainingToolsEngine.workingWeightsKg(oneRmKg);

    return _toolCard(
      icon: Icons.fitness_center_rounded,
      title: 'Estimated 1RM & working weights',
      subtitle: 'Estimate a sensible strength reference from a completed set. Use it as guidance, not a requirement to attempt a true max.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _oneRmWeight,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Weight',
                    suffixText: settings.weightUnit,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _oneRmReps,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Reps (1–15)'),
                ),
              ),
            ],
          ),
          if (oneRmKg != null && oneRmKg > 0) ...[
            const SizedBox(height: 16),
            _resultBox(
              'Estimated 1RM',
              TrainingToolsEngine.formatWeight(oneRmKg, settings.unitSystem),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: working.entries
                  .map(
                    (entry) => Chip(
                      label: Text(
                        '${entry.key}% • ${TrainingToolsEngine.formatWeight(entry.value, settings.unitSystem)}',
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paceCard(TrainingSettings settings) {
    final distanceDisplay = _number(_paceDistance);
    final seconds = _durationSeconds(_paceTime.text);
    double? pace;
    if (distanceDisplay != null && seconds != null && distanceDisplay > 0) {
      final distanceKm = TrainingToolsEngine.toCanonicalDistanceKm(
        distanceDisplay,
        settings.unitSystem,
      );
      pace = TrainingToolsEngine.paceSecondsPerKm(
        distanceKm: distanceKm,
        durationSeconds: seconds,
      );
    }

    return _toolCard(
      icon: Icons.directions_run_rounded,
      title: 'Running pace calculator',
      subtitle: 'Enter a distance and finish time to get the pace LeanIt would need to target.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _paceDistance,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Distance',
                    suffixText: settings.distanceUnit,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _paceTime,
                  keyboardType: TextInputType.datetime,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Finish time',
                    hintText: '25:00',
                  ),
                ),
              ),
            ],
          ),
          if (pace != null) ...[
            const SizedBox(height: 16),
            _resultBox(
              'Required average pace',
              TrainingToolsEngine.formatPace(pace, settings.unitSystem),
            ),
            const SizedBox(height: 8),
            Text(
              'At the same pace: 1 ${settings.distanceUnit} ≈ ${_duration(TrainingToolsEngine.paceForDisplay(pace, settings.unitSystem).round())}.',
              style: const TextStyle(color: Color(0xFF627D98), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _plateCard(TrainingSettings settings) {
    final target = _number(_plateTarget);
    final bar = _number(_barWeight);
    final inventory = settings.isMetric
        ? const <double>[25, 20, 15, 10, 5, 2.5, 1.25]
        : const <double>[45, 35, 25, 10, 5, 2.5];
    PlateLoadResult? result;
    if (target != null && bar != null && target >= bar && bar >= 0) {
      result = TrainingToolsEngine.plateLoad(
        targetTotal: target,
        barWeight: bar,
        availablePlates: inventory,
      );
    }

    return _toolCard(
      icon: Icons.calculate_outlined,
      title: 'Barbell plate calculator',
      subtitle: 'Shows plates per side using common ${settings.weightUnit} plates. It never changes your logged workout weight.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _plateTarget,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Target total',
                    suffixText: settings.weightUnit,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _barWeight,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Bar',
                    suffixText: settings.weightUnit,
                  ),
                ),
              ),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: 16),
            _resultBox(
              'Load each side',
              result.platesPerSide.isEmpty
                  ? 'No plates'
                  : result.platesPerSide
                      .map((plate) => '${plate % 1 == 0 ? plate.toStringAsFixed(0) : plate} ${settings.weightUnit}')
                      .join(' + '),
            ),
            const SizedBox(height: 8),
            Text(
              'Achieved total: ${result.achievedTotal.toStringAsFixed(result.achievedTotal % 1 == 0 ? 0 : 1)} ${settings.weightUnit}${result.difference.abs() < 0.01 ? '' : ' • nearest load below target'}',
              style: const TextStyle(color: Color(0xFF627D98), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _toolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              CircleAvatar(
                backgroundColor: const Color(0xFFE5F4F8),
                child: Icon(icon, color: const Color(0xFF176B87)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF627D98), height: 1.4),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _resultBox(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Color(0xFF627D98),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
        ],
      ),
    );
  }
}
