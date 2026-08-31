import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'live_run_screen.dart';
import 'run_log_form_screen.dart';
import 'run_tracking_engine.dart';
import 'run_tracking_store.dart';

class RunTrackingScreen extends StatefulWidget {
  const RunTrackingScreen({super.key});

  @override
  State<RunTrackingScreen> createState() => _RunTrackingScreenState();
}

class _RunTrackingScreenState extends State<RunTrackingScreen> {
  late Future<List<RunRecord>> _future;
  RunProgressMetric _metric = RunProgressMetric.distance;

  @override
  void initState() {
    super.initState();
    _future = RunTrackingStore.load();
  }

  Future<void> _refresh() async {
    setState(() => _future = RunTrackingStore.load());
    await _future;
  }

  Future<void> _openLiveRun() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LiveRunScreen()),
    );
    if (changed == true) await _refresh();
  }

  Future<void> _openManualRun() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RunLogFormScreen()),
    );
    if (changed == true) await _refresh();
  }

  Future<void> _delete(RunRecord run) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete run?'),
            content: Text(
              '${run.distanceKm.toStringAsFixed(2)} km on ${_date(run.startedAt)} will be removed from LeanIt history.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('DELETE'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await RunTrackingStore.delete(run.id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Running'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: FutureBuilder<List<RunRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final runs = snapshot.data ?? const <RunRecord>[];
          final all = RunTrackingEngine.summary(runs);
          final now = DateTime.now();
          final weekStart = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: now.weekday - DateTime.monday));
          final week = RunTrackingEngine.summary(
            RunTrackingEngine.since(runs, weekStart),
          );
          final best = RunTrackingEngine.bestPace(runs);
          final longest = RunTrackingEngine.longestRun(runs);
          final points = RunTrackingEngine.seriesFor(runs, _metric);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Run tracking',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track outdoor runs with foreground GPS or log treadmill/watch runs manually. LeanIt keeps your distance, time and pace history together.',
                  style: TextStyle(color: Color(0xFF627D98), height: 1.4),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _openLiveRun,
                        icon: const Icon(Icons.gps_fixed),
                        label: const Text('START GPS RUN'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openManualRun,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('ADD RUN'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Stat(
                      label: 'This week',
                      value: '${week.distanceKm.toStringAsFixed(1)} km',
                      icon: Icons.calendar_view_week_outlined,
                    ),
                    _Stat(
                      label: 'All runs',
                      value: '${all.runs}',
                      icon: Icons.directions_run_rounded,
                    ),
                    _Stat(
                      label: 'Total distance',
                      value: '${all.distanceKm.toStringAsFixed(1)} km',
                      icon: Icons.route_outlined,
                    ),
                    _Stat(
                      label: 'Best pace',
                      value: RunTrackingEngine.formatPace(
                        best?.averagePaceSecondsPerKm,
                      ),
                      icon: Icons.speed_rounded,
                    ),
                    _Stat(
                      label: 'Longest run',
                      value: longest == null
                          ? '--'
                          : '${longest.distanceKm.toStringAsFixed(2)} km',
                      icon: Icons.straighten_rounded,
                    ),
                    _Stat(
                      label: 'Total time',
                      value: RunTrackingEngine.formatDuration(
                        all.durationSeconds,
                      ),
                      icon: Icons.timer_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'Running progress',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<RunProgressMetric>(
                  segments: const [
                    ButtonSegment(
                      value: RunProgressMetric.distance,
                      label: Text('Distance'),
                      icon: Icon(Icons.route_outlined),
                    ),
                    ButtonSegment(
                      value: RunProgressMetric.pace,
                      label: Text('Pace'),
                      icon: Icon(Icons.speed_rounded),
                    ),
                  ],
                  selected: {_metric},
                  onSelectionChanged: (value) {
                    setState(() => _metric = value.first);
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  height: 250,
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD9E2EC)),
                  ),
                  child: points.isEmpty
                      ? const Center(
                          child: Text(
                            'Complete runs to build your running trend.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF627D98)),
                          ),
                        )
                      : CustomPaint(
                          painter: _RunChartPainter(
                            points: points.length > 30
                                ? points.sublist(points.length - 30)
                                : points,
                            metric: _metric,
                          ),
                          child: const SizedBox.expand(),
                        ),
                ),
                if (_metric == RunProgressMetric.pace) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'For pace, a lower min/km value means faster running. Runs under 500 m are excluded from the pace trend.',
                    style: TextStyle(color: Color(0xFF829AB1), fontSize: 12),
                  ),
                ],
                const SizedBox(height: 28),
                const Text(
                  'Run history',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 12),
                if (runs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'No runs yet. Start a GPS run or add one manually.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF627D98)),
                    ),
                  )
                else
                  ...runs.map((run) => _RunTile(
                        run: run,
                        onDelete: () => _delete(run),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _Stat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF176B87)),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102A43),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Color(0xFF627D98))),
        ],
      ),
    );
  }
}

class _RunTile extends StatelessWidget {
  final RunRecord run;
  final VoidCallback onDelete;

  const _RunTile({required this.run, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final d = run.startedAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE5F4F8),
          child: Icon(
            run.source == 'gps' ? Icons.gps_fixed : Icons.edit_location_alt_outlined,
            color: const Color(0xFF176B87),
          ),
        ),
        title: Text(
          '${run.distanceKm.toStringAsFixed(2)} km',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF102A43),
          ),
        ),
        subtitle: Text(
          '${d.day}/${d.month}/${d.year} • '
          '${RunTrackingEngine.formatDuration(run.durationSeconds)} • '
          '${RunTrackingEngine.formatPace(run.averagePaceSecondsPerKm)}'
          '${run.notes == null ? '' : '\n${run.notes}'}',
          maxLines: run.notes == null ? 2 : 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: run.notes != null,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

class _RunChartPainter extends CustomPainter {
  final List<RunProgressPoint> points;
  final RunProgressMetric metric;

  const _RunChartPainter({required this.points, required this.metric});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;
    const left = 44.0;
    const right = 10.0;
    const top = 8.0;
    const bottom = 26.0;
    final width = math.max(1.0, size.width - left - right);
    final height = math.max(1.0, size.height - top - bottom);

    var minValue = points.map((p) => p.value).reduce(math.min);
    var maxValue = points.map((p) => p.value).reduce(math.max);
    if (minValue == maxValue) {
      minValue = math.max(0, minValue - 1);
      maxValue += 1;
    } else {
      final pad = (maxValue - minValue) * 0.12;
      minValue = math.max(0, minValue - pad);
      maxValue += pad;
    }

    final grid = Paint()
      ..color = const Color(0xFFE5EAF0)
      ..strokeWidth = 1;
    final line = Paint()
      ..color = const Color(0xFF176B87)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..color = const Color(0xFF176B87);

    for (var i = 0; i <= 4; i++) {
      final y = top + height * i / 4;
      canvas.drawLine(Offset(left, y), Offset(left + width, y), grid);
      final value = maxValue - (maxValue - minValue) * i / 4;
      _text(
        canvas,
        metric == RunProgressMetric.distance
            ? value.toStringAsFixed(1)
            : value.toStringAsFixed(1),
        Offset(0, y - 7),
        left - 5,
      );
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? left + width / 2
          : left + width * i / (points.length - 1);
      final ratio = (points[i].value - minValue) / (maxValue - minValue);
      final y = top + height * (1 - ratio);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dot);
    }
    if (points.length > 1) canvas.drawPath(path, line);

    _text(
      canvas,
      '${points.first.date.day}/${points.first.date.month}',
      Offset(left, size.height - 18),
      width / 2,
    );
    final last = '${points.last.date.day}/${points.last.date.month}';
    final painter = TextPainter(
      text: TextSpan(
        text: last,
        style: const TextStyle(fontSize: 10, color: Color(0xFF627D98)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(left + width - painter.width, size.height - 18),
    );
  }

  void _text(Canvas canvas, String text, Offset offset, double maxWidth) {
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
  bool shouldRepaint(covariant _RunChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.metric != metric;
}
