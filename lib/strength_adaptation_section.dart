import 'package:flutter/material.dart';

import 'adaptive_strength_engine.dart';

class StrengthAdaptationSection extends StatelessWidget {
  final StrengthAdaptationRecommendation recommendation;

  const StrengthAdaptationSection({
    super.key,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    final tone = _tone(recommendation.action);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adaptive strength coach',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Color(0xFF102A43),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'LeanIt combines recent strength workload, repeated exercise performance, session effort and fresh readiness before deciding whether the next target should progress, hold or back off.',
          style: TextStyle(color: Color(0xFF627D98), height: 1.4),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: tone.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tone.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(tone.icon, color: tone.foreground),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _actionLabel(recommendation.action),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: tone.foreground,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          recommendation.headline,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF102A43),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                recommendation.explanation,
                style: const TextStyle(
                  color: Color(0xFF486581),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricChip(
                    label: 'This week',
                    value:
                        '${recommendation.currentWeekWorkouts} workouts • ${recommendation.currentWeekSets} sets',
                  ),
                  _MetricChip(
                    label: 'Previous week',
                    value:
                        '${recommendation.previousWeekWorkouts} workouts • ${recommendation.previousWeekSets} sets',
                  ),
                  _MetricChip(
                    label: 'Readiness',
                    value: recommendation.readinessScore == null
                        ? 'No fresh check'
                        : '${recommendation.readinessScore!.round()}%',
                  ),
                  _MetricChip(
                    label: 'Exercise trend',
                    value:
                        '${recommendation.improvingExercises} up • ${recommendation.decliningExercises} down',
                  ),
                  _MetricChip(
                    label: 'Hard sessions',
                    value: '${recommendation.recentHardSessions} in 7 days',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Why LeanIt chose this',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF102A43),
                ),
              ),
              const SizedBox(height: 8),
              ...recommendation.reasons.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 17,
                        color: tone.foreground,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF486581),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (recommendation.protectsRecovery) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    recommendation.action == StrengthAdaptationAction.deload
                        ? 'Live progression will favour about ${(recommendation.suggestedLoadMultiplier * 100).round()}% of the previous working load and about ${(recommendation.suggestedVolumeMultiplier * 100).round()}% of normal working-set volume.'
                        : 'Live progression will intentionally trim the next target and avoid adding a second workload jump.',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFF486581),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _actionLabel(StrengthAdaptationAction action) {
    switch (action) {
      case StrengthAdaptationAction.buildBaseline:
        return 'BUILD BASELINE';
      case StrengthAdaptationAction.progress:
        return 'PROGRESS';
      case StrengthAdaptationAction.maintain:
        return 'HOLD';
      case StrengthAdaptationAction.reduce:
        return 'REDUCE';
      case StrengthAdaptationAction.deload:
        return 'DELOAD';
    }
  }

  static _Tone _tone(StrengthAdaptationAction action) {
    switch (action) {
      case StrengthAdaptationAction.progress:
        return const _Tone(
          background: Color(0xFFF0F9F4),
          border: Color(0xFFB7E4C7),
          foreground: Color(0xFF0F6B4B),
          icon: Icons.trending_up_rounded,
        );
      case StrengthAdaptationAction.deload:
        return const _Tone(
          background: Color(0xFFFFF4E8),
          border: Color(0xFFFFD4A3),
          foreground: Color(0xFF9A5B00),
          icon: Icons.battery_saver_outlined,
        );
      case StrengthAdaptationAction.reduce:
        return const _Tone(
          background: Color(0xFFFFF8E1),
          border: Color(0xFFFFE082),
          foreground: Color(0xFF8A6500),
          icon: Icons.trending_down_rounded,
        );
      case StrengthAdaptationAction.maintain:
      case StrengthAdaptationAction.buildBaseline:
        return const _Tone(
          background: Color(0xFFEAF7FA),
          border: Color(0xFFB9E2EA),
          foreground: Color(0xFF176B87),
          icon: Icons.balance_rounded,
        );
    }
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, color: Color(0xFF627D98)),
          children: [
            TextSpan(
              text: '$label\n',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102A43),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tone {
  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;

  const _Tone({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });
}
