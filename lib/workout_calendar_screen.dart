import 'package:flutter/material.dart';

import 'training_store.dart';
import 'workout_calendar_engine.dart';

class WorkoutCalendarScreen extends StatefulWidget {
  final List<WorkoutRecord>? initialRecords;

  const WorkoutCalendarScreen({
    super.key,
    this.initialRecords,
  });

  @override
  State<WorkoutCalendarScreen> createState() => _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState extends State<WorkoutCalendarScreen> {
  late Future<List<WorkoutRecord>> _future;
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  static const _monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = WorkoutCalendarEngine.dateOnly(now);
    _future = widget.initialRecords != null
        ? Future.value(widget.initialRecords!)
        : TrainingStore.loadWorkouts();
  }

  Future<void> _refresh() async {
    setState(() => _future = TrainingStore.loadWorkouts());
    await _future;
  }

  bool get _canGoForward {
    final now = DateTime.now();
    return _visibleMonth.year < now.year ||
        (_visibleMonth.year == now.year && _visibleMonth.month < now.month);
  }

  void _changeMonth(int delta) {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    if (next.isAfter(currentMonth)) return;

    setState(() {
      _visibleMonth = next;
      final isCurrent = next.year == now.year && next.month == now.month;
      _selectedDay = isCurrent
          ? WorkoutCalendarEngine.dateOnly(now)
          : DateTime(next.year, next.month, 1);
    });
  }

  String _duration(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '${hours}h' : '${hours}h ${remainder}m';
  }

  String _time(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Workout calendar'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: FutureBuilder<List<WorkoutRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data ?? const <WorkoutRecord>[];
          final grouped = WorkoutCalendarEngine.groupByDay(records);
          final stats = WorkoutCalendarEngine.monthStats(records, _visibleMonth);
          final selected = WorkoutCalendarEngine.recordsForDay(
            records,
            _selectedDay,
          );
          final days = WorkoutCalendarEngine.daysInMonth(_visibleMonth);
          final leading = WorkoutCalendarEngine.leadingBlankCount(_visibleMonth);
          final cellCount = ((leading + days + 6) ~/ 7) * 7;
          final now = WorkoutCalendarEngine.dateOnly(DateTime.now());

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const Text(
                  'Your training calendar',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'See when you trained, how often you trained, and what you completed on each day.',
                  style: TextStyle(
                    color: Color(0xFF627D98),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous month',
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF102A43),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next month',
                      onPressed: _canGoForward ? () => _changeMonth(1) : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _CalendarStat(
                      label: 'Trained days',
                      value: '${stats.trainedDays}',
                      icon: Icons.fitness_center_rounded,
                    ),
                    _CalendarStat(
                      label: 'Recovery days',
                      value: '${stats.recoveryDays}',
                      icon: Icons.self_improvement_rounded,
                    ),
                    _CalendarStat(
                      label: 'Rest days',
                      value: '${stats.restDays}',
                      icon: Icons.hotel_rounded,
                    ),
                    _CalendarStat(
                      label: 'Workouts',
                      value: '${stats.workouts}',
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    _CalendarStat(
                      label: 'Days / week',
                      value: stats.trainingDaysPerWeek.toStringAsFixed(1),
                      icon: Icons.repeat_rounded,
                    ),
                    _CalendarStat(
                      label: 'Latest streak',
                      value: '${WorkoutCalendarEngine.latestStreak(records)} days',
                      icon: Icons.local_fire_department_outlined,
                    ),
                    _CalendarStat(
                      label: 'Best streak',
                      value: '${WorkoutCalendarEngine.longestStreak(records)} days',
                      icon: Icons.emoji_events_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFD9E2EC)),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          _Weekday('Mon'),
                          _Weekday('Tue'),
                          _Weekday('Wed'),
                          _Weekday('Thu'),
                          _Weekday('Fri'),
                          _Weekday('Sat'),
                          _Weekday('Sun'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cellCount,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 5,
                          childAspectRatio: 0.88,
                        ),
                        itemBuilder: (context, index) {
                          final dayNumber = index - leading + 1;
                          if (dayNumber < 1 || dayNumber > days) {
                            return const SizedBox.shrink();
                          }

                          final day = DateTime(
                            _visibleMonth.year,
                            _visibleMonth.month,
                            dayNumber,
                          );
                          final workouts = grouped[day] ?? const <WorkoutRecord>[];
                          final trained = workouts.isNotEmpty;
                          final recoveryOnly = workouts.isNotEmpty &&
                              workouts.every(WorkoutCalendarEngine.isRecoveryRecord);
                          final selectedDay =
                              WorkoutCalendarEngine.sameDay(day, _selectedDay);
                          final today = WorkoutCalendarEngine.sameDay(day, now);
                          final future = day.isAfter(now);

                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _selectedDay = day),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              decoration: BoxDecoration(
                                color: selectedDay
                                    ? const Color(0xFFE5F4F8)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedDay
                                      ? const Color(0xFF176B87)
                                      : today
                                          ? const Color(0xFF9FB3C8)
                                          : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$dayNumber',
                                    style: TextStyle(
                                      fontWeight: today || selectedDay
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: future
                                          ? const Color(0xFFBCCCDC)
                                          : const Color(0xFF102A43),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  if (trained)
                                    Container(
                                      width: workouts.length > 1 ? 18 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: recoveryOnly
                                            ? const Color(0xFF55721B)
                                            : const Color(0xFF176B87),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 8),
                                  if (workouts.length > 1) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${workouts.length}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF176B87),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      const Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 18,
                        runSpacing: 7,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LegendDot(),
                              SizedBox(width: 7),
                              Text(
                                'Training',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF627D98),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LegendDot(recovery: true),
                              SizedBox(width: 7),
                              Text(
                                'Recovery',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF627D98),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  '${_selectedDay.day} ${_monthNames[_selectedDay.month - 1]} ${_selectedDay.year}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 10),
                if (selected.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD9E2EC)),
                    ),
                    child: Text(
                      _selectedDay.isAfter(now)
                          ? 'No training yet — this date is still in the future.'
                          : 'No completed workout was logged on this day.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF627D98)),
                    ),
                  )
                else
                  ...selected.map(
                    (record) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD9E2EC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: WorkoutCalendarEngine.isRecoveryRecord(record)
                                    ? const Color(0xFFF3F8DC)
                                    : const Color(0xFFE5F4F8),
                                child: Icon(
                                  WorkoutCalendarEngine.isRecoveryRecord(record)
                                      ? Icons.self_improvement_rounded
                                      : Icons.fitness_center_rounded,
                                  color: WorkoutCalendarEngine.isRecoveryRecord(record)
                                      ? const Color(0xFF55721B)
                                      : const Color(0xFF176B87),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.title,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF102A43),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      WorkoutCalendarEngine.isRecoveryRecord(record)
                                          ? '${_time(record.completedAt)} • ${_duration(record.durationSeconds)} • recovery session'
                                          : '${_time(record.completedAt)} • ${_duration(record.durationSeconds)} • ${record.completedSets} sets',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF627D98),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (record.exercises.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              WorkoutCalendarEngine.isRecoveryRecord(record)
                                  ? 'Recovery steps'
                                  : 'Exercises',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF486581),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: record.exercises
                                  .map(
                                    (exercise) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F7F9),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        exercise,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF486581),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                if (stats.workouts > 0) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insights_rounded,
                          color: Color(0xFF176B87),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This month: ${_duration(stats.totalDurationSeconds)} logged training/recovery time and ${stats.completedSets} completed working sets.',
                            style: const TextStyle(
                              color: Color(0xFF486581),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CalendarStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CalendarStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF176B87)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF627D98)),
          ),
        ],
      ),
    );
  }
}

class _Weekday extends StatelessWidget {
  final String label;

  const _Weekday(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF829AB1),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final bool recovery;

  const _LegendDot({this.recovery = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: recovery
            ? const Color(0xFF55721B)
            : const Color(0xFF176B87),
        shape: BoxShape.circle,
      ),
    );
  }
}