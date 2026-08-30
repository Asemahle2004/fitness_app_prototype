import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    TrainingStore.loadReadiness().then((records) {
      if (!mounted || records.isEmpty) return;
      setState(() => latest = records.first);
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

  Widget _slider(String title, String low, String high, double value, ValueChanged<double> onChanged) {
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
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102A43)))),
              Text('${value.round()}/5', style: const TextStyle(color: Color(0xFF176B87), fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(value: value, min: 1, max: 5, divisions: 4, onChanged: onChanged),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(low, style: const TextStyle(fontSize: 11, color: Color(0xFF829AB1))), Text(high, style: const TextStyle(fontSize: 11, color: Color(0xFF829AB1)))],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(title: const Text('Readiness'), backgroundColor: const Color(0xFFF7F9FC)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('How ready are you today?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF102A43))),
          const SizedBox(height: 8),
          const Text('This is a simple training-readiness check, not a medical assessment. Use it to decide whether today should be normal, lighter, or recovery-focused.', style: TextStyle(color: Color(0xFF627D98), height: 1.4)),
          const SizedBox(height: 20),
          _slider('Sleep quality', 'Poor', 'Excellent', sleep, (v) => setState(() => sleep = v)),
          _slider('Energy', 'Very low', 'High', energy, (v) => setState(() => energy = v)),
          _slider('Muscle soreness', 'Low', 'Very high', soreness, (v) => setState(() => soreness = v)),
          _slider('Stress', 'Low', 'Very high', stress, (v) => setState(() => stress = v)),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF176B87), foregroundColor: Colors.white),
              child: const Text('SAVE TODAY\'S READINESS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          if (latest != null) ...[
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFEAF7FA), borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Readiness score', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF486581))),
                  const SizedBox(height: 6),
                  Text('${latest!.score.round()}%', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF176B87))),
                  const SizedBox(height: 8),
                  Text(latest!.recommendation, style: const TextStyle(height: 1.4, color: Color(0xFF245B69))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
