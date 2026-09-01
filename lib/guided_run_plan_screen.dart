import 'package:flutter/material.dart';

import 'guided_run_engine.dart';
import 'live_run_screen.dart';
import 'run_tracking_engine.dart';

class GuidedRunPlanScreen extends StatelessWidget {
  const GuidedRunPlanScreen({super.key});

  Future<void> _openPlan(BuildContext context, GuidedRunPlan plan) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LiveRunScreen(guidedPlan: plan),
      ),
    );
    if (changed == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Guided run'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        children: [
          const Text(
            'Choose today’s run',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'LeanIt will guide each work and recovery phase with on-screen countdowns plus optional sound and vibration cues. GPS still records the whole session.',
            style: TextStyle(
              height: 1.5,
              color: Color(0xFF627D98),
            ),
          ),
          const SizedBox(height: 20),
          ...GuidedRunEngine.starterPlans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlanCard(
                plan: plan,
                onTap: () => _openPlan(context, plan),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD58A)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF9A6700)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These are starter guided sessions. LeanIt’s later adaptive running layer will choose and progress sessions from your programme and recent run feedback rather than asking you to pick every time.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: Color(0xFF725500),
                    ),
                  ),
                ),
              ],
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
