import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'community_challenge_engine.dart';
import 'motivation_engine.dart';
import 'run_tracking_store.dart';
import 'training_store.dart';

class MotivationCommunityScreen extends StatefulWidget {
  const MotivationCommunityScreen({super.key});

  @override
  State<MotivationCommunityScreen> createState() =>
      _MotivationCommunityScreenState();
}

class _MotivationCommunityScreenState extends State<MotivationCommunityScreen> {
  late Future<_Data> _future;
  bool _includeNumbers = true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Data> _load() async {
    final workouts = await TrainingStore.loadWorkouts();
    final runs = await RunTrackingStore.load();
    return _Data(workouts: workouts, runs: runs);
  }

  Future<void> _share(_Data data) async {
    final review = MotivationEngine.weeklyReview(
      workouts: data.workouts,
      runs: data.runs,
    );
    final text = CommunityChallengeEngine.shareText(
      headline: review.headline,
      workouts: review.workouts,
      runs: review.runningSessions,
      runningKm: review.runningKm,
      includeNumbers: _includeNumbers,
    );
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share summary copied. Nothing was posted automatically.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Achievements & challenges'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: FutureBuilder<_Data>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final achievements = MotivationEngine.achievements(
            workouts: data.workouts,
            runs: data.runs,
          );
          final weekly = MotivationEngine.weeklyReview(
            workouts: data.workouts,
            runs: data.runs,
          );
          final wrapped = MotivationEngine.wrapped(
            year: DateTime.now().year,
            workouts: data.workouts,
            runs: data.runs,
          );
          final challenges = CommunityChallengeEngine.starterChallenges
              .map((challenge) => CommunityChallengeEngine.progress(
                    challenge: challenge,
                    workouts: data.workouts,
                    runs: data.runs,
                  ))
              .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
            children: [
              _summaryCard(weekly),
              const SizedBox(height: 18),
              const Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF102A43),
                ),
              ),
              const SizedBox(height: 10),
              ...achievements.map(
                (achievement) => Card(
                  child: ListTile(
                    leading: Icon(
                      achievement.unlocked
                          ? Icons.emoji_events_rounded
                          : Icons.lock_outline_rounded,
                      color: achievement.unlocked
                          ? const Color(0xFF9A6700)
                          : const Color(0xFF9FB3C8),
                    ),
                    title: Text(achievement.title),
                    subtitle: Text(achievement.description),
                    trailing: achievement.unlocked
                        ? const Icon(Icons.check_circle, color: Color(0xFF0F6B4B))
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Opt-in challenges',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF102A43),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Challenges are calculated locally from your own history. There is no public leaderboard or friend graph in this version.',
                style: TextStyle(color: Color(0xFF627D98)),
              ),
              const SizedBox(height: 10),
              ...challenges.map(
                (progress) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                progress.challenge.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (progress.complete)
                              const Icon(Icons.check_circle, color: Color(0xFF0F6B4B)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(progress.challenge.description),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: progress.fraction),
                        const SizedBox(height: 5),
                        Text(
                          '${progress.value.toStringAsFixed(progress.value % 1 == 0 ? 0 : 1)} / ${progress.challenge.target.toStringAsFixed(progress.challenge.target % 1 == 0 ? 0 : 1)} ${progress.challenge.unit}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF627D98)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LeanIt ${wrapped.year} Wrapped',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(wrapped.headline),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text('${wrapped.workouts} workouts')),
                          Chip(label: Text('${wrapped.completedSets} sets')),
                          Chip(label: Text('${wrapped.runs} runs')),
                          Chip(label: Text('${wrapped.runningKm.toStringAsFixed(1)} km')),
                          Chip(label: Text('${wrapped.trainingMinutes} min')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include training numbers in share text'),
                subtitle: const Text('Turn this off to share only a general achievement message.'),
                value: _includeNumbers,
                onChanged: (value) => setState(() => _includeNumbers = value),
              ),
              FilledButton.icon(
                onPressed: () => _share(data),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('COPY PRIVATE SHARE SUMMARY'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(WeeklyTrainingReview review) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THIS WEEK',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            review.headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${review.workouts} strength workouts • ${review.runningSessions} runs • ${review.runningKm.toStringAsFixed(1)} km • ${review.trainingMinutes} min',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _Data {
  final List<WorkoutRecord> workouts;
  final List<RunRecord> runs;

  const _Data({required this.workouts, required this.runs});
}
