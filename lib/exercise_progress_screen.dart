import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise_performance_store.dart';
import 'progress_trend_engine.dart';

class ExerciseProgressScreen extends StatefulWidget {
  final String exerciseName;

  const ExerciseProgressScreen({
    super.key,
    required this.exerciseName,
  });

  @override
  State<ExerciseProgressScreen> createState() => _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState extends State<ExerciseProgressScreen> {
  late Future<List<ExerciseSetPerformance>> _future;
  ProgressMetric? _selectedMetric;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ExerciseSetPerformance>> _load() {
    return ExercisePerformanceStore(
      Supabase.instance.client,
    ).loadForExercise(widget.exerciseName, limit: 500);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  String _formatValue(double value, ProgressMetric metric) {
    if (metric == ProgressMetric.time) {
      final seconds = value.round();
      if (seconds >= 60) {
        final minutes = seconds ~/ 60;
        final remainder = seconds % 60;
        return remainder == 0 ? '${minutes}m' : '${minutes}m ${remainder}s';
      }
      return '${seconds}s';
    }
    if (metric == ProgressMetric.volume) {
      if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
      return value.round().toString();
    }
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        title: const Text('Exercise progress'),
      ),
      body: FutureBuilder<List<ExerciseSetPerformance>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data ?? const <ExerciseSetPerformance>[];
          final series = ProgressTrendEngine.build(widget.exerciseName, records);
          final metrics = series.availableMetrics;

          if (metrics.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    widget.exerciseName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD9E2EC)),
                    ),
                    child: const Text(
                      'Complete more logged sets for this exercise and LeanIt will build your progress graph here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF627D98), height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }

          final metric = metrics.contains(_selectedMetric)
              ? _selectedMetric!
              : metrics.first;
          final points = series.forMetric(metric);
          final latest = points.last.value;
          final best = points.map((point) => point.value).reduce(math.max);
          final change = ProgressTrendEngine.percentChange(points);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              children: [
                Text(
                  widget.exerciseName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'See how your normal working sets change over time. Drop-set reductions are kept out of the main progression trend.',
                  style: TextStyle(
                    color: Color(0xFF627D98),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: metrics
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(item.label),
                              selected: item == metric,
                              onSelected: (_) {
                                setState(() => _selectedMetric = item);
                              },
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricCard(
                      label: 'Latest',
                      value: '${_formatValue(latest, metric)} ${metric.unit}',
                    ),
                    _MetricCard(
                      label: 'Best',
                      value: '${_formatValue(best, metric)} ${metric.unit}',
                    ),
                    _MetricCard(
                      label: 'Change',
                      value: change == null
                          ? 'Need 2+ days'
                          : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFD9E2EC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${metric.label} trend',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF102A43),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${points.length} training ${points.length == 1 ? 'day' : 'days'} • ${_date(points.first.date)} to ${_date(points.last.date)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF627D98),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 250,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _ProgressLinePainter(points: points),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Recent training days',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 10),
                ...points.reversed.take(10).map(
                      (point) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD9E2EC)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _date(point.date),
                                style: const TextStyle(
                                  color: Color(0xFF486581),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${_formatValue(point.value, metric)} ${metric.unit}',
                              style: const TextStyle(
                                color: Color(0xFF176B87),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 105),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF829AB1)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressLinePainter extends CustomPainter {
  final List<ProgressPoint> points;

  const _ProgressLinePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;

    const left = 42.0;
    const right = 10.0;
    const top = 12.0;
    const bottom = 30.0;
    final chartWidth = math.max(1.0, size.width - left - right);
    final chartHeight = math.max(1.0, size.height - top - bottom);

    var minValue = points.map((point) => point.value).reduce(math.min);
    var maxValue = points.map((point) => point.value).reduce(math.max);
    if (minValue == maxValue) {
      final padding = minValue == 0 ? 1.0 : minValue.abs() * 0.1;
      minValue -= padding;
      maxValue += padding;
    } else {
      final padding = (maxValue - minValue) * 0.12;
      minValue = math.max(0, minValue - padding);
      maxValue += padding;
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE5EAF0)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = const Color(0xFF176B87)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dotPaint = Paint()..color = const Color(0xFF176B87);

    for (var i = 0; i <= 4; i += 1) {
      final y = top + chartHeight * i / 4;
      canvas.drawLine(Offset(left, y), Offset(left + chartWidth, y), gridPaint);
      final value = maxValue - (maxValue - minValue) * i / 4;
      _paintText(
        canvas,
        _compact(value),
        Offset(0, y - 7),
        maxWidth: left - 6,
      );
    }

    final path = Path();
    for (var i = 0; i < points.length; i += 1) {
      final x = points.length == 1
          ? left + chartWidth / 2
          : left + chartWidth * i / (points.length - 1);
      final ratio = (points[i].value - minValue) / (maxValue - minValue);
      final y = top + chartHeight * (1 - ratio);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    if (points.length > 1) canvas.drawPath(path, linePaint);

    _paintText(
      canvas,
      _shortDate(points.first.date),
      Offset(left, size.height - 20),
      maxWidth: chartWidth / 2,
    );
    final lastText = _shortDate(points.last.date);
    final lastPainter = TextPainter(
      text: TextSpan(
        text: lastText,
        style: const TextStyle(fontSize: 10, color: Color(0xFF627D98)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    lastPainter.paint(
      canvas,
      Offset(left + chartWidth - lastPainter.width, size.height - 20),
    );
  }

  String _compact(double value) {
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(0)}k';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  String _shortDate(DateTime value) => '${value.day}/${value.month}';

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 10, color: Color(0xFF627D98)),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ProgressLinePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
