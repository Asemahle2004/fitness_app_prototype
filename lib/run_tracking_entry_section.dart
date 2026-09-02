import 'package:flutter/material.dart';

import 'run_tracking_engine.dart';
import 'run_tracking_screen.dart';
import 'run_tracking_store.dart';
import 'unit_display.dart';

class RunTrackingEntrySection extends StatelessWidget {
  const RunTrackingEntrySection({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RunRecord>>(
      future: RunTrackingStore.load(),
      builder: (context, snapshot) {
        final runs = snapshot.data ?? const <RunRecord>[];
        final total = RunTrackingEngine.summary(runs);
        final latest = runs.isEmpty ? null : runs.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Running',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102A43),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track outdoor runs with GPS or log treadmill/watch runs. Follow distance, duration and pace over time.',
              style: TextStyle(color: Color(0xFF627D98), height: 1.4),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RunTrackingScreen()),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD9E2EC)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE5F4F8),
                      child: Icon(
                        Icons.directions_run_rounded,
                        color: Color(0xFF176B87),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            runs.isEmpty
                                ? 'Start your running history'
                                : '${total.runs} runs • ${UnitDisplay.formatDistanceKm(total.distanceKm, decimals: 1)} total',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF102A43),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            latest == null
                                ? 'GPS tracking, manual run logging and pace progress'
                                : 'Latest: ${UnitDisplay.formatDistanceKm(latest.distanceKm)} • ${UnitDisplay.formatPace(latest.averagePaceSecondsPerKm)}',
                            style: const TextStyle(
                              color: Color(0xFF627D98),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
