import 'package:flutter/material.dart';

import 'body_progress_engine.dart';
import 'body_progress_screen.dart';
import 'body_progress_store.dart';

class BodyProgressEntrySection extends StatefulWidget {
  const BodyProgressEntrySection({super.key});

  @override
  State<BodyProgressEntrySection> createState() => _BodyProgressEntrySectionState();
}

class _BodyProgressEntrySectionState extends State<BodyProgressEntrySection> {
  late Future<List<BodyProgressEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = BodyProgressStore().loadEntries();
  }

  Future<void> _open() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const BodyProgressScreen()),
    );
    if (mounted) {
      setState(() => _future = BodyProgressStore().loadEntries());
    }
  }

  String _number(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BodyProgressEntry>>(
      future: _future,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const <BodyProgressEntry>[];
        final latestWeight = BodyProgressEngine.latestWithMetric(
          entries,
          BodyMetric.weight,
        );
        final weightPoints = BodyProgressEngine.seriesFor(
          entries,
          BodyMetric.weight,
        );
        final weightChange = BodyProgressEngine.absoluteChange(weightPoints);

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
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE5F4F8),
                    child: Icon(
                      Icons.accessibility_new_rounded,
                      color: Color(0xFF176B87),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Body progress',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF102A43),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Weight, measurements and progress photos',
                          style: TextStyle(color: Color(0xFF627D98)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 14),
              if (entries.isEmpty)
                const Text(
                  'No body measurements logged yet. Start tracking the physical results of your training.',
                  style: TextStyle(color: Color(0xFF627D98), height: 1.4),
                )
              else
                Wrap(
                  spacing: 18,
                  runSpacing: 6,
                  children: [
                    Text(
                      latestWeight?.weightKg == null
                          ? '${entries.length} measurement entries'
                          : 'Latest ${_number(latestWeight!.weightKg!)} kg',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    if (weightChange != null)
                      Text(
                        'Change ${weightChange >= 0 ? '+' : ''}${_number(weightChange)} kg',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF176B87),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _open,
                  icon: const Icon(Icons.show_chart_rounded),
                  label: const Text('OPEN BODY PROGRESS'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
