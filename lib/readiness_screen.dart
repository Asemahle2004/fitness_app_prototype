import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';
import 'recovery_day_engine.dart';
import 'recovery_day_screen.dart';
import 'training_store.dart';

class ReadinessScreen extends StatefulWidget {
  const ReadinessScreen({super.key});

  @override
  State<ReadinessScreen> createState() => _ReadinessScreenState();
}

class _ReadinessScreenState extends State<ReadinessScreen> {
  double sleep = 3;
  double energy = 3;
  double soreness = 3;
  double stress = 3;
  ReadinessRecord? latest;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await TrainingStore.loadReadiness();
    Map<String, dynamic>? profile;
    try {
      profile = await ProfileService(Supabase.instance.client).currentProfileMap();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      if (records.isNotEmpty) latest = records.first;
      _profile = profile;
    });
  }

  Future<void> _save() async {
    final record = ReadinessRecord(
      recordedAt: DateTime.now(),
      sleep: sleep,
      energy: energy,
      soreness: soreness,
      stress: stress,
    );
    await TrainingStore.saveReadiness(record);
    if (!mounted) return;
    setState(() => latest = record);
  }

  Future<void> _startRecoveryDay() async {
    final record = latest;
    if (record == null || !RecoveryDayEngine.isTodaysCheckIn(record)) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RecoveryDayScreen(
          readiness: record,
          profile: _profile,
        ),
      ),
    );
  }

  Widget _slider(
    String title,
    String low,
    String high,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
              ),
              Text(
                '${value.round()}/5',
                style: const TextStyle(
                  color: Color(0xFF176B87),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                low,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF829AB1),
                ),
              ),
              Text(
                high,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF829AB1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = latest;
    final recoveryAvailable = record != null &&
        RecoveryDayEngine.isTodaysCheckIn(record) &&
        RecoveryDayEngine.shouldOffer(record);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Readiness'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'How ready are you today?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This is a simple training-readiness check, not a medical assessment. Use it to decide whether today should be normal, lighter, or recovery-focused.',
            style: TextStyle(
              color: Color(0xFF627D98),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _slider(
            'Sleep quality',
            'Poor',
            'Excellent',
            sleep,
            (v) => setState(() => sleep = v),
          ),
          _slider(
            'Energy',
            'Very low',
            'High',
            energy,
            (v) => setState(() => energy = v),
          ),
          _slider(
            'Muscle soreness',
            'Low',
            'Very high',
            soreness,
            (v) => setState(() => soreness = v),
          ),
          _slider(
            'Stress',
            'Low',
            'Very high',
            stress,
            (v) => setState(() => stress = v),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF176B87),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'SAVE TODAY\'S READINESS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (record != null) ...[
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Readiness score',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF486581),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${record.score.round()}%',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF176B87),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    record.recommendation,
                    style: const TextStyle(
                      height: 1.4,
                      color: Color(0xFF245B69),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (recoveryAvailable) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8DC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD8E89A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.self_improvement_rounded,
                        color: Color(0xFF55721B),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Recovery day available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF102A43),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    record!.score < 40
                        ? 'Recovery is low today. LeanIt can guide a very easy recovery session instead of normal training volume.'
                        : 'Today may suit a lighter day. LeanIt can guide easy movement, mobility, stretching and breathing while leaving your planned workout unchanged.',
                    style: const TextStyle(
                      height: 1.4,
                      color: Color(0xFF486581),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startRecoveryDay,
                      icon: const Icon(Icons.self_improvement_rounded),
                      label: const Text(
                        'START RECOVERY DAY',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
