import 'package:flutter/material.dart';

import 'training_store.dart';
import 'workout_calendar_engine.dart';
import 'workout_calendar_screen.dart';

class WorkoutCalendarEntrySection extends StatelessWidget {
  final List<WorkoutRecord> records;

  const WorkoutCalendarEntrySection({
    super.key,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final stats = WorkoutCalendarEngine.monthStats(records, now);
    final latestStreak = WorkoutCalendarEngine.latestStreak(records);

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
                  Icons.calendar_month_rounded,
                  color: Color(0xFF176B87),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout calendar',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'See training, recovery, rest days and session details.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF627D98),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text(
                '${stats.trainedDays} trained days',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF486581),
                ),
              ),
              Text(
                '${stats.recoveryDays} recovery days',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF486581),
                ),
              ),
              Text(
                '$latestStreak-day training streak',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF486581),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutCalendarScreen(
                      initialRecords: records,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('OPEN WORKOUT CALENDAR'),
            ),
          ),
        ],
      ),
    );
  }
}
