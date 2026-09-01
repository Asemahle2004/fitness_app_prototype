import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'adaptive_running_coach.dart';
import 'guided_run_engine.dart';
import 'live_run_screen.dart';
import 'profile_service.dart';
import 'run_tracking_engine.dart';
import 'run_tracking_store.dart';
import 'training_store.dart';

class GuidedRunPlanScreen extends StatefulWidget {
  const GuidedRunPlanScreen({super.key});

  @override
  State<GuidedRunPlanScreen> createState() => _GuidedRunPlanScreenState();
}

class _GuidedRunPlanScreenState extends State<GuidedRunPlanScreen> {
  late Future<AdaptiveRunRecommendation> _recommendationFuture;

  @override
  void initState() {
    super.initState();
    _recommendationFuture = _loadRecommendation();
  }

  Future<AdaptiveRunRecommendation> _loadRecommendation() async {
    final runs = await RunTrackingStore.load();
    final readiness = await TrainingStore.loadReadiness();
    String? goal;
    try {
      final profile = await ProfileService(
        Supabase.instance.client,
      ).currentProfileMap();
      goal = profile?['main_goal']?.toString();
    } catch (_) {
      // Running recommendations still work offline from local history.
    }

    return AdaptiveRunningCoach.recommend(
      runs: runs,
      readiness: readiness.isEmpty ? null : readiness.first,
      mainGoal: goal,
    );
  }

  Future<void> _openPlan(GuidedRunPlan plan) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LiveRunScreen(guidedPlan: plan),
      ),
    );
    if (changed != true || !mounted) return;

    await _attachAdaptiveFeedback(plan);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _attachAdaptiveFeedback(GuidedRunPlan plan) async {
    final runs = await RunTrackingStore.load();
    if (runs.isEmpty) return;
    final latest = runs.first;
    if (!latest.source.startsWith('gps_guided')) return;

    final effort = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('How did that run feel?'),
        content: const Text(
          'LeanIt uses this with completion, readiness and recent running load to choose the next guided session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'easy'),
            child: const Text('EASY'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'right'),
            child: const Text('ABOUT RIGHT'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'hard'),
            child: const Text('HARD'),
          ),
        ],
      ),
    );

    final note = latest.notes?.toLowerCase() ?? '';
    final completed = note.contains('• completed') ||
        latest.durationSeconds >= plan.totalSeconds;
    await RunTrackingStore.save(
      latest.copyWith(
        guidedPlanId: plan.id,
        guidedPlannedSeconds: plan.totalSeconds,
        guidedCompleted: completed,
        perceivedEffort: effort,
      ),
    );
  }

  String _actionLabel(RunningCoachAction action) {
    switch (action) {
      case RunningCoachAction.start:
        return 'STARTING POINT';
      case RunningCoachAction.progress:
        return 'PROGRESS';
      case RunningCoachAction.repeat:
        return 'REPEAT / CONSOLIDATE';
      case RunningCoachAction.reduce:
        return 'REDUCE';
      case RunningCoachAction.recovery:
        return 'RECOVERY';
    }
  }

  IconData _actionIcon(RunningCoachAction action) {
    switch (action) {
      case RunningCoachAction.start:
        return Icons.flag_outlined;
      case RunningCoachAction.progress:
        return Icons.trending_up_rounded;
      case RunningCoachAction.repeat:
        return Icons.replay_rounded;
      case RunningCoachAction.reduce:
        return Icons.south_east_rounded;
      case RunningCoachAction.recovery:
        return Icons.favorite_border_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Running coach'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: FutureBuilder<AdaptiveRunRecommendation>(
        future: _recommendationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Choose a guided run',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'LeanIt could not load the adaptive recommendation, but the guided sessions are still available.',
                  style: TextStyle(color: Color(0xFF627D98), height: 1.45),
                ),
                const SizedBox(height: 18),
                ...AdaptiveRunningCoach.allPlans
                    .where((plan) => plan.id != AdaptiveRunningCoach.recoveryPlan.id)
                    .map(
                      (plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PlanCard(
                          plan: plan,
                          onTap: () => _openPlan(plan),
                        ),
                      ),
                    ),
              ],
            );
          }

          final recommendation = snapshot.data!;
          final alternatives = AdaptiveRunningCoach.allPlans
              .where(
                (plan) =>
                    plan.id != recommendation.plan.id &&
                    plan.id != AdaptiveRunningCoach.recoveryPlan.id,
              )
              .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              const Text(
                'Today’s running coach',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF102A43),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'LeanIt combines guided-run completion, perceived effort, recent running load and a recent readiness check when one is available. Progression is deliberately gradual.',
                style: TextStyle(
                  height: 1.5,
                  color: Color(0xFF627D98),
                ),
              ),
              const SizedBox(height: 20),
              _RecommendationCard(
                recommendation: recommendation,
                actionLabel: _actionLabel(recommendation.action),
                actionIcon: _actionIcon(recommendation.action),
                onStart: () => _openPlan(recommendation.plan),
              ),
              const SizedBox(height: 28),
              const Text(
                'Other guided sessions',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF102A43),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'The recommendation is guidance, not a lock. You can still choose another session when appropriate.',
                style: TextStyle(color: Color(0xFF627D98), height: 1.4),
              ),
              const SizedBox(height: 14),
              ...alternatives.map(
                (plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PlanCard(
                    plan: plan,
                    onTap: () => _openPlan(plan),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final AdaptiveRunRecommendation recommendation;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onStart;

  const _RecommendationCard({
    required this.recommendation,
    required this.actionLabel,
    required this.actionIcon,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final plan = recommendation.plan;
    final workPhases = plan.steps
        .where((step) => step.type == GuidedRunPhaseType.run)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(actionIcon, color: Colors.white70),
              const SizedBox(width: 8),
              const Text(
                'LEANIT RECOMMENDS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            recommendation.headline,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            plan.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${plan.level} • ${RunTrackingEngine.formatDuration(plan.totalSeconds)} • $workPhases work phases',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 18),
          ...recommendation.reasons.map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 17,
                    color: Colors.white60,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${recommendation.recentRunCount} runs • ${recommendation.recentMinutes} min in the last 7 days'
              '${recommendation.readinessUsed ? ' • recent readiness included' : ' • no recent readiness used'}',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('START RECOMMENDED RUN'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF102A43),
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final GuidedRunPlan plan;
  final VoidCallback onTap;

  const _PlanCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final runSteps = plan.steps
        .where((step) => step.type == GuidedRunPhaseType.run)
        .length;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD9E2EC)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 25,
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
                    plan.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plan.level} • ${RunTrackingEngine.formatDuration(plan.totalSeconds)} • $runSteps work phases',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF176B87),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    plan.description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF627D98),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF829AB1)),
          ],
        ),
      ),
    );
  }
}
