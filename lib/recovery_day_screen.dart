import 'package:flutter/material.dart';

import 'recovery_day_engine.dart';
import 'session_phase_flow_screen.dart';
import 'training_store.dart';

class RecoveryDayScreen extends StatefulWidget {
  final ReadinessRecord readiness;
  final Map<String, dynamic>? profile;

  const RecoveryDayScreen({
    super.key,
    required this.readiness,
    this.profile,
  });

  @override
  State<RecoveryDayScreen> createState() => _RecoveryDayScreenState();
}

class _RecoveryDayScreenState extends State<RecoveryDayScreen> {
  late RecoveryDayPlan _plan;
  bool _starting = false;
  bool _completed = false;
  bool _saved = false;

  Set<String> _stringSet(dynamic value) {
    if (value is! List) return <String>{};
    return value.whereType<String>().toSet();
  }

  bool get _hasSafetyWarningSigns =>
      _stringSet(widget.profile?['warning_signs']).isNotEmpty;

  @override
  void initState() {
    super.initState();
    _plan = RecoveryDayEngine.forReadiness(
      widget.readiness,
      locations: _stringSet(widget.profile?['training_locations']),
    );
  }

  Future<void> _startRecovery() async {
    if (_starting || _completed || _hasSafetyWarningSigns) return;
    setState(() => _starting = true);
    final startedAt = DateTime.now();

    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SessionPhaseFlowScreen(
          title: 'Guided recovery day',
          subtitle:
              'Keep every step easy and comfortable. This session is for movement and recovery, not performance, strength volume or progressive overload.',
          steps: _plan.steps,
          completeLabel: 'RECOVERY SESSION COMPLETE',
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _starting = false);
    if (completed != true) return;

    final finishedAt = DateTime.now();
    final elapsed = finishedAt.difference(startedAt).inSeconds.clamp(1, 7200).toInt();
    if (!_saved) {
      _saved = true;
      await TrainingStore.saveWorkout(
        WorkoutRecord(
          title: _plan.title,
          completedAt: finishedAt,
          durationSeconds: elapsed,
          completedSets: 0,
          exercises: _plan.steps.map((step) => step.name).toList(growable: false),
        ),
      );
    }

    if (!mounted) return;
    setState(() => _completed = true);
  }

  String _minutes(int seconds) {
    final value = (seconds / 60).ceil();
    return '$value min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Recovery day'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7FA),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFB9E2EA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.self_improvement_rounded,
                  size: 34,
                  color: Color(0xFF176B87),
                ),
                const SizedBox(height: 12),
                Text(
                  _completed ? 'Recovery session complete' : _plan.headline,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _completed
                      ? 'LeanIt saved this as a recovery day. It does not add strength sets, exercise progression or personal-record attempts.'
                      : _plan.rationale,
                  style: const TextStyle(
                    height: 1.45,
                    color: Color(0xFF486581),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.schedule_rounded,
                text: _minutes(_plan.totalSeconds),
              ),
              _InfoChip(
                icon: Icons.place_outlined,
                text: _plan.location,
              ),
              _InfoChip(
                icon: Icons.low_priority_rounded,
                text: '${_plan.steps.length} easy steps',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Today’s recovery plan',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 10),
          ..._plan.steps.asMap().entries.map(
                (entry) => Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: const Color(0xFFD9E2EC)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: const Color(0xFFF0F7F9),
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF176B87),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF102A43),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${entry.value.type.label} • ${_minutes(entry.value.durationSeconds)} • ${entry.value.target}',
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
                ),
              ),
          const SizedBox(height: 8),
          if (_hasSafetyWarningSigns)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Your saved safety profile includes a warning sign, so LeanIt will not direct an exercise or recovery session. Use appropriate medical guidance before app-directed training.',
                style: TextStyle(
                  height: 1.4,
                  color: Color(0xFF8E1B1B),
                ),
              ),
            )
          else
            const Text(
              'Keep the effort easy. Skip any movement that is uncomfortable, and stop if you experience unusual or increasing pain. This is a general recovery option, not medical treatment or rehabilitation.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF627D98),
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _completed
                  ? () => Navigator.pop(context, true)
                  : (_starting || _hasSafetyWarningSigns ? null : _startRecovery),
              icon: Icon(
                _completed
                    ? Icons.check_rounded
                    : Icons.self_improvement_rounded,
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                backgroundColor: const Color(0xFF176B87),
                foregroundColor: Colors.white,
              ),
              label: Text(
                _completed
                    ? 'DONE'
                    : _starting
                        ? 'OPENING RECOVERY…'
                        : 'START GUIDED RECOVERY',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF176B87)),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF486581),
            ),
          ),
        ],
      ),
    );
  }
}
