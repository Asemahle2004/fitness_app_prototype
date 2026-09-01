import 'package:flutter/material.dart';

import 'progress_insights_engine.dart';

class ProgressInsightsSection extends StatelessWidget {
  final ProgressInsights insights;

  const ProgressInsightsSection({
    super.key,
    required this.insights,
  });

  String _minutes(int value) {
    if (value < 60) return '$value min';
    final hours = value ~/ 60;
    final minutes = value % 60;
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
  }

  String _volume(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k kg·reps';
    return '${value.round()} kg·reps';
  }

  String _trend(double? change, double current, double previous) {
    if (previous == 0 && current > 0) return 'New this week';
    if (change == null) return 'No comparison yet';
    final rounded = change.round();
    if (rounded == 0) return 'About the same';
    return rounded > 0 ? '+$rounded% vs last week' : '$rounded% vs last week';
  }

  Color _trendColor(double? change, double current, double previous) {
    if (previous == 0 && current > 0) return const Color(0xFF176B87);
    if (change == null || change == 0) return const Color(0xFF627D98);
    return change > 0 ? const Color(0xFF176B87) : const Color(0xFF9A6700);
  }

  String _weekLabel(DateTime value) => '${value.day}/${value.month}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Training trends',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Color(0xFF102A43),
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'See whether your recent training is becoming more consistent instead of relying only on lifetime totals.',
          style: TextStyle(
            color: Color(0xFF627D98),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        if (!insights.hasTrainingHistory)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD9E2EC)),
            ),
            child: const Text(
              'Complete workouts and log sets to unlock week-over-week trends, consistency and your most-trained exercises.',
              style: TextStyle(
                color: Color(0xFF627D98),
                height: 1.45,
              ),
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _ComparisonCard(
                  icon: Icons.calendar_view_week_outlined,
                  label: 'This week',
                  value: '${insights.currentWeekWorkouts} workouts',
                  detail: _trend(
                    insights.workoutChangePercent,
                    insights.currentWeekWorkouts.toDouble(),
                    insights.previousWeekWorkouts.toDouble(),
                  ),
                  detailColor: _trendColor(
                    insights.workoutChangePercent,
                    insights.currentWeekWorkouts.toDouble(),
                    insights.previousWeekWorkouts.toDouble(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ComparisonCard(
                  icon: Icons.timer_outlined,
                  label: 'Training time',
                  value: _minutes(insights.currentWeekMinutes),
                  detail: _trend(
                    insights.minutesChangePercent,
                    insights.currentWeekMinutes.toDouble(),
                    insights.previousWeekMinutes.toDouble(),
                  ),
                  detailColor: _trendColor(
                    insights.minutesChangePercent,
                    insights.currentWeekMinutes.toDouble(),
                    insights.previousWeekMinutes.toDouble(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                    Icons.balance_rounded,
                    color: Color(0xFF176B87),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Logged strength volume this week',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF627D98),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _volume(insights.currentWeekVolumeKg),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF102A43),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _trend(
                    insights.volumeChangePercent,
                    insights.currentWeekVolumeKg,
                    insights.previousWeekVolumeKg,
                  ),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _trendColor(
                      insights.volumeChangePercent,
                      insights.currentWeekVolumeKg,
                      insights.previousWeekVolumeKg,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ConsistencyCard(insights: insights),
          const SizedBox(height: 14),
          _EightWeekChart(
            weeks: insights.weeklySeries,
            weekLabel: _weekLabel,
          ),
          if (insights.mostTrainedExercises.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD9E2EC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Most trained exercises',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Based on logged sets where available.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF829AB1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var index = 0;
                      index < insights.mostTrainedExercises.length;
                      index += 1)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == insights.mostTrainedExercises.length - 1
                            ? 0
                            : 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F7F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF176B87),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              insights.mostTrainedExercises[index].exerciseName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF102A43),
                              ),
                            ),
                          ),
                          Text(
                            '${insights.mostTrainedExercises[index].appearances} logged sets',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF627D98),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color detailColor;

  const _ComparisonCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.detailColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF176B87)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF627D98),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: detailColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsistencyCard extends StatelessWidget {
  final ProgressInsights insights;

  const _ConsistencyCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB6E0EA)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: insights.consistencyPercent / 100,
                  strokeWidth: 6,
                  backgroundColor: const Color(0xFFD9E2EC),
                  color: const Color(0xFF176B87),
                ),
                Center(
                  child: Text(
                    '${insights.consistencyPercent}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${insights.activeWeeks} of ${insights.trackedWeeks} weeks active',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insights.weeklyStreak > 0
                      ? '${insights.weeklyStreak}-week active streak. Keep the routine realistic enough to repeat.'
                      : 'No active-week streak yet. One completed session this week starts it again.',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF486581),
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

class _EightWeekChart extends StatelessWidget {
  final List<WeeklyTrainingPoint> weeks;
  final String Function(DateTime) weekLabel;

  const _EightWeekChart({
    required this.weeks,
    required this.weekLabel,
  });

  @override
  Widget build(BuildContext context) {
    final maxWorkouts = weeks.fold<int>(
      1,
      (maxValue, week) => week.workouts > maxValue ? week.workouts : maxValue,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 8 weeks',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Completed workouts per calendar week',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF829AB1),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 105,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeks.map((week) {
                final height = week.workouts == 0
                    ? 5.0
                    : 12 + (58 * (week.workouts / maxWorkouts));
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${week.workouts}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF486581),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: double.infinity,
                          height: height,
                          decoration: BoxDecoration(
                            color: week.workouts == 0
                                ? const Color(0xFFE7EEF4)
                                : const Color(0xFF86CBD8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          weekLabel(week.weekStart),
                          style: const TextStyle(
                            fontSize: 8,
                            color: Color(0xFF829AB1),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}
