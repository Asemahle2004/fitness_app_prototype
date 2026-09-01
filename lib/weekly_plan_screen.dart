import 'package:flutter/material.dart';

import 'missed_workout_engine.dart';
import 'programme_engine.dart';
import 'weekly_schedule_store.dart';

typedef PlannedSessionOpenHandler = void Function(
  BuildContext context,
  PlannedSession session,
);

class WeeklyPlanScreen extends StatefulWidget {
  final List<PlannedSession> baseSessions;
  final Set<String> availableDays;
  final String userScope;
  final PlannedSessionOpenHandler onOpenSession;

  const WeeklyPlanScreen({
    super.key,
    required this.baseSessions,
    required this.availableDays,
    required this.userScope,
    required this.onOpenSession,
  });

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  late final WeeklyScheduleStore _store;
  List<PlannedSession> _sessions = <PlannedSession>[];
  List<String> _scheduleNotes = <String>[];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _store = WeeklyScheduleStore(userScope: widget.userScope);
    _load();
  }

  Future<void> _load() async {
    final snapshot = await _store.load(baseSessions: widget.baseSessions);
    if (!mounted) return;
    setState(() {
      _sessions = List<PlannedSession>.from(snapshot.sessions);
      _scheduleNotes = List<String>.from(snapshot.skippedSessions);
      _sortSessions();
      _loading = false;
    });
  }

  void _sortSessions() {
    _sessions.sort(
      (a, b) => MissedWorkoutEngine.weekOrder
          .indexOf(a.day)
          .compareTo(MissedWorkoutEngine.weekOrder.indexOf(b.day)),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _store.save(
      baseSessions: widget.baseSessions,
      sessions: _sessions,
      skippedSessions: _scheduleNotes,
    );
    if (!mounted) return;
    setState(() => _saving = false);
  }

  Future<void> _resetWeek() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset this week?'),
        content: const Text(
          'This restores the original programme days for this week. Your permanent programme and workout history are not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('RESET WEEK'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _store.reset();
    if (!mounted) return;
    setState(() {
      _sessions = List<PlannedSession>.from(widget.baseSessions);
      _scheduleNotes = <String>[];
      _sortSessions();
    });
  }

  Future<void> _handleMissed(int index) async {
    if (_saving || index < 0 || index >= _sessions.length) return;
    final recommendation = MissedWorkoutEngine.recommend(
      sessions: _sessions,
      missedIndex: index,
      availableDays: widget.availableDays,
    );

    final selected = await showModalBottomSheet<MissedWorkoutOption>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Plans change. What should LeanIt do?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF102A43),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${recommendation.missedSession.day} • ${recommendation.missedSession.title}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF176B87),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'LeanIt will not tell you to cram several missed sessions together. It checks the rest of the week first.',
                style: TextStyle(height: 1.4, color: Color(0xFF627D98)),
              ),
              const SizedBox(height: 18),
              _optionCard(
                sheetContext,
                recommendation.recommended,
                recommended: true,
              ),
              if (recommendation.alternatives.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Other options',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF486581),
                  ),
                ),
                const SizedBox(height: 8),
                ...recommendation.alternatives.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _optionCard(sheetContext, option),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!mounted || selected == null) return;
    final missed = recommendation.missedSession;
    setState(() {
      _sessions = List<PlannedSession>.from(selected.revisedSessions);
      _sortSessions();
      switch (selected.action) {
        case MissedWorkoutAction.moveLater:
          _scheduleNotes.insert(
            0,
            'Moved ${missed.title}: ${missed.day} → ${selected.targetDay}',
          );
          break;
        case MissedWorkoutAction.skipToday:
          _scheduleNotes.insert(0, 'Skipped ${missed.day} • ${missed.title}');
          break;
        case MissedWorkoutAction.continuePlan:
          _scheduleNotes.insert(
            0,
            'Missed ${missed.day} • ${missed.title}; schedule unchanged',
          );
          break;
      }
    });
    await _save();
  }

  Widget _optionCard(
    BuildContext sheetContext,
    MissedWorkoutOption option, {
    bool recommended = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.pop(sheetContext, option),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: recommended ? const Color(0xFFEAF7FA) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: recommended
                ? const Color(0xFF86CBD8)
                : const Color(0xFFD9E2EC),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              option.action == MissedWorkoutAction.moveLater
                  ? Icons.event_repeat_rounded
                  : option.action == MissedWorkoutAction.skipToday
                      ? Icons.skip_next_rounded
                      : Icons.calendar_view_week_outlined,
              color: const Color(0xFF176B87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recommended)
                    const Text(
                      'RECOMMENDED',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF176B87),
                      ),
                    ),
                  if (recommended) const SizedBox(height: 3),
                  Text(
                    option.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.explanation,
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

  String get _todayName => MissedWorkoutEngine.weekOrder[DateTime.now().weekday - 1];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('This week'),
        backgroundColor: const Color(0xFFF7F9FC),
        actions: [
          IconButton(
            tooltip: 'Reset week',
            onPressed: _loading || _saving ? null : _resetWeek,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    const Text(
                      'Your training week',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Open any session when you are ready. If plans change, LeanIt can reorganise the week without turning one missed workout into a punishment.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF627D98),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_scheduleNotes.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFD58A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.auto_awesome, color: Color(0xFF9A6700)),
                                SizedBox(width: 8),
                                Text(
                                  'Week adapted',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF102A43),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._scheduleNotes.take(3).map(
                              (note) => Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  '• $note',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: Color(0xFF627D98),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_sessions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          'No remaining sessions this week. Continue with the programme next week rather than cramming missed work.',
                          style: TextStyle(height: 1.5, color: Color(0xFF486581)),
                        ),
                      )
                    else
                      for (var index = 0; index < _sessions.length; index += 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _sessionCard(index, _sessions[index]),
                        ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sessionCard(int index, PlannedSession session) {
    final today = session.day == _todayName;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: today ? const Color(0xFF176B87) : const Color(0xFFD9E2EC),
          width: today ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.day,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF176B87),
                  ),
                ),
              ),
              if (today)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7FA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF176B87),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            session.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${session.duration} • ${session.location} • ${session.intensity}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF627D98)),
          ),
          if (session.focus.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              session.focus,
              style: const TextStyle(fontSize: 12, color: Color(0xFF829AB1)),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving
                      ? null
                      : () => widget.onOpenSession(context, session),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('OPEN WORKOUT'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _saving ? null : () => _handleMissed(index),
                child: const Text('MISSED / CAN’T DO'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
