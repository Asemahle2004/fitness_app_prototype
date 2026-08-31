import 'package:flutter/material.dart';

import 'exercise_performance_store.dart';
import 'exercise_progress_screen.dart';

class ExerciseProgressEntrySection extends StatelessWidget {
  final List<ExerciseSetPerformance> sets;

  const ExerciseProgressEntrySection({
    super.key,
    required this.sets,
  });

  @override
  Widget build(BuildContext context) {
    final latestByExercise = <String, ExerciseSetPerformance>{};
    for (final set in sets) {
      if (set.isDropSet) continue;
      final key = set.exerciseName.trim().toLowerCase();
      if (key.isEmpty) continue;
      final existing = latestByExercise[key];
      if (existing == null || set.performedAt.isAfter(existing.performedAt)) {
        latestByExercise[key] = set;
      }
    }

    final exercises = latestByExercise.values.toList(growable: false)
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exercise progress graphs',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Color(0xFF102A43),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Open an exercise to track load, reps, training volume or timed performance across your logged training days.',
          style: TextStyle(
            color: Color(0xFF627D98),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        if (exercises.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD9E2EC)),
            ),
            child: const Text(
              'Complete logged sets and your exercise trends will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF627D98)),
            ),
          )
        else
          ...exercises.take(12).map(
                (set) => Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD9E2EC)),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE5F4F8),
                      child: Icon(
                        Icons.show_chart_rounded,
                        color: Color(0xFF176B87),
                      ),
                    ),
                    title: Text(
                      set.exerciseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    subtitle: Text(
                      'Latest: ${set.summary}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExerciseProgressScreen(
                            exerciseName: set.exerciseName,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
      ],
    );
  }
}
