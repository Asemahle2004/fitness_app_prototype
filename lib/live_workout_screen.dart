import 'package:flutter/material.dart';

import 'workout_engine.dart';

class LiveWorkoutScreen extends StatefulWidget {
  final GeneratedWorkout workout;

  const LiveWorkoutScreen({
    super.key,
    required this.workout,
  });

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen> {
  int currentIndex = 0;
  final Set<int> completed = {};

  bool get isComplete =>
      widget.workout.exercises.isNotEmpty &&
      completed.length == widget.workout.exercises.length;

  void completeCurrent() {
    if (widget.workout.exercises.isEmpty) return;

    setState(() {
      completed.add(currentIndex);
      if (currentIndex < widget.workout.exercises.length - 1) {
        currentIndex += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.workout.exercises;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Workout'),
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
      ),
      body: SafeArea(
        child: exercises.isEmpty
            ? const Center(child: Text('No exercises are available for this workout.'))
            : isComplete
                ? _completeView(context)
                : _activeView(exercises[currentIndex]),
      ),
    );
  }

  Widget _activeView(ExercisePrescription exercise) {
    final total = widget.workout.exercises.length;
    final progress = completed.length / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.workout.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF176B87),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Exercise ${currentIndex + 1} of $total',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: const Color(0xFFD9E2EC),
            color: const Color(0xFF176B87),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD9E2EC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F4F8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      size: 34,
                      color: Color(0xFF176B87),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exercise.target,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF176B87),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _detailRow('Target', exercise.summary),
                  _detailRow('Rest', exercise.rest),
                  _detailRow('Equipment', exercise.equipment),
                  const Spacer(),
                  const Text(
                    'Complete the prescribed work with controlled form. Stop if you experience unusual pain.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF627D98),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              if (currentIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        currentIndex -= 1;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    child: const Text('PREVIOUS'),
                  ),
                ),
              if (currentIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: completeCurrent,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: const Color(0xFF176B87),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    currentIndex == total - 1
                        ? 'COMPLETE WORKOUT'
                        : 'COMPLETE & NEXT',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _completeView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFE5F4F8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 50,
                color: Color(0xFF176B87),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Workout complete',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102A43),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.workout.exercises.length} exercise${widget.workout.exercises.length == 1 ? '' : 's'} completed.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF627D98),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: const Color(0xFF176B87),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'BACK TO WORKOUT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF829AB1),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF102A43),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
