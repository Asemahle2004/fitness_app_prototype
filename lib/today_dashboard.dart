import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'lean_eat_theme.dart';
import 'live_workout_screen.dart';
import 'profile_service.dart';
import 'recovery_day_engine.dart';
import 'recovery_day_screen.dart';
import 'programme_engine.dart';
import 'programme_store.dart';
import 'readiness_screen.dart';
import 'safety_engine.dart';
import 'training_store.dart';
import 'workout_engine.dart';

class LeanEatTodayDashboard extends StatefulWidget {
  final Widget fallbackProgrammeHome;

  const LeanEatTodayDashboard({
    super.key,
    required this.fallbackProgrammeHome,
  });

  @override
  State<LeanEatTodayDashboard> createState() => _LeanEatTodayDashboardState();
}

class _LeanEatTodayDashboardState extends State<LeanEatTodayDashboard> {
  late final SupabaseClient _client;
  late final ProgrammeStore _store;

  Map<String, dynamic>? _profile;
  StoredProgramme? _stored;
  ReadinessRecord? _readiness;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _store = ProgrammeStore(_client);
    _load();
  }

  Set<String> _stringSet(dynamic value) {
    if (value is! List) return <String>{};
    return value.whereType<String>().toSet();
  }

  String _string(String key, String fallback) {
    final value = _profile?[key]?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  String _weekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[(weekday - 1).clamp(0, 6)];
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final profile = await ProfileService(_client).currentProfileMap();
      if (profile == null) {
        if (!mounted) return;
        setState(() {
          _profile = null;
          _stored = null;
          _loading = false;
          _error = 'Your training profile could not be loaded.';
        });
        return;
      }

      var stored = await _store.ensureForProfile(profile);
      stored = await _reconcileActiveWorkout(stored, profile);

      ReadinessRecord? readiness;
      final readinessHistory = await TrainingStore.loadReadiness();
      if (readinessHistory.isNotEmpty &&
          RecoveryDayEngine.isTodaysCheckIn(readinessHistory.first)) {
        readiness = readinessHistory.first;
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _stored = stored;
        _readiness = readiness;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'LeanIt could not refresh your programme. $error';
      });
    }
  }

  GeneratedWorkout _workoutFor(
    PlannedSession session,
    Map<String, dynamic> profile,
  ) {
    final base = WorkoutEngine.generate(
      sessionTitle: session.title,
      location: session.location,
      homeEquipment: _stringSet(profile['home_equipment']),
      gymAccess: profile['gym_access']?.toString(),
      sessionDuration: session.duration,
    );

    final safetyProfile = SafetyProfile(
      hasLimitation: profile['has_limitation'] == true,
      affectedAreas: _stringSet(profile['affected_areas']),
      warningSigns: _stringSet(profile['warning_signs']),
      notes: profile['limitation_notes']?.toString() ?? '',
    );

    return SafetyEngine.adaptWorkout(
      base,
      safetyProfile,
      location: session.location,
    ).workout;
  }

  SafetyAdaptation _adaptationFor(
    PlannedSession session,
    Map<String, dynamic> profile,
  ) {
    final base = WorkoutEngine.generate(
      sessionTitle: session.title,
      location: session.location,
      homeEquipment: _stringSet(profile['home_equipment']),
      gymAccess: profile['gym_access']?.toString(),
      sessionDuration: session.duration,
    );
    return SafetyEngine.adaptWorkout(
      base,
      SafetyProfile(
        hasLimitation: profile['has_limitation'] == true,
        affectedAreas: _stringSet(profile['affected_areas']),
        warningSigns: _stringSet(profile['warning_signs']),
        notes: profile['limitation_notes']?.toString() ?? '',
      ),
      location: session.location,
    );
  }

  Future<StoredProgramme> _reconcileActiveWorkout(
    StoredProgramme stored,
    Map<String, dynamic> profile,
  ) async {
    final activeIndex = stored.activeSessionIndex;
    final startedAt = stored.activeStartedAt;
    if (activeIndex == null || startedAt == null || stored.programme.sessions.isEmpty) {
      return stored;
    }
    if (activeIndex < 0 || activeIndex >= stored.programme.sessions.length) {
      await _store.clearActiveSession();
      return (await _store.loadCurrent()) ?? stored;
    }

    final session = stored.programme.sessions[activeIndex];
    final history = await TrainingStore.loadWorkouts();
    final sessionTitle = session.title.toLowerCase();
    final completed = history.any((record) {
      final completedAfterStart =
          record.completedAt.isAfter(startedAt.subtract(const Duration(seconds: 5)));
      return completedAfterStart && record.title.toLowerCase().contains(sessionTitle);
    });

    if (!completed) return stored;
    await _store.completeSession(activeIndex, profile: profile);
    return (await _store.loadCurrent()) ?? stored;
  }

  Future<void> _startCurrentWorkout() async {
    final stored = _stored;
    final profile = _profile;
    if (stored == null || profile == null || stored.currentSession == null) return;

    final index = stored.activeSessionIndex ?? stored.safeCurrentSessionIndex;
    if (index < 0 || index >= stored.programme.sessions.length) return;
    final session = stored.programme.sessions[index];
    final adaptation = _adaptationFor(session, profile);
    if (adaptation.blocksTraining) return;

    if (stored.activeSessionIndex == null) {
      await _store.markSessionStarted(index);
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveWorkoutScreen(workout: adaptation.workout),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _skipCurrentSession() async {
    final stored = _stored;
    final profile = _profile;
    if (stored == null ||
        profile == null ||
        stored.currentSession == null ||
        stored.activeSessionIndex != null) {
      return;
    }

    final index = stored.safeCurrentSessionIndex;
    final session = stored.programme.sessions[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip this session?'),
        content: Text(
          'LeanIt will record ${session.title} as skipped and use that information when it builds your next training week.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SKIP SESSION'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _store.skipSession(index, profile: profile);
    if (mounted) await _load();
  }

  Future<void> _startRecoveryDay() async {
    final readiness = _readiness;
    final profile = _profile;
    if (readiness == null ||
        profile == null ||
        !RecoveryDayEngine.shouldOffer(readiness)) {
      return;
    }

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RecoveryDayScreen(
          readiness: readiness,
          profile: profile,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF176B87)),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF486581),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: LeanEatColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _stored == null || _profile == null) {
      return Scaffold(
        backgroundColor: LeanEatColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    _error ?? 'Your programme is not available yet.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(onPressed: _load, child: const Text('TRY AGAIN')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final stored = _stored!;
    final programme = stored.programme;
    final activeIndex = stored.activeSessionIndex;
    final shownIndex = activeIndex ?? stored.safeCurrentSessionIndex;
    final session = programme.sessions.isEmpty ? null : programme.sessions[shownIndex];
    final nextSession = stored.nextSession;
    final todayName = _weekdayName(DateTime.now().weekday);
    final isToday = session?.day == todayName;
    final adaptation = session == null ? null : _adaptationFor(session, _profile!);
    final readiness = _readiness;
    final recoveryAvailable = readiness != null &&
        RecoveryDayEngine.shouldOffer(readiness) &&
        adaptation?.blocksTraining != true &&
        activeIndex == null;

    final heading = activeIndex != null
        ? 'Continue your workout'
        : isToday
            ? "Today's workout"
            : 'Next workout';

    return Scaffold(
      backgroundColor: LeanEatColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
            children: [
              Row(
                children: [
                  const LeanEatLogo(size: 38, showWordmark: false),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text(
                      'LeanIt',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF102A43),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh programme',
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Week ${stored.currentWeek}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF176B87),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                heading,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF102A43),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                programme.goal,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF627D98),
                ),
              ),
              const SizedBox(height: 22),
              if (session == null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFD9E2EC)),
                  ),
                  child: const Text('No sessions are available in your current programme.'),
                )
              else
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD9E2EC)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D102A43),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5F4F8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.fitness_center_rounded,
                              color: Color(0xFF176B87),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeIndex != null ? 'IN PROGRESS' : session.day.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF176B87),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  session.title,
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF102A43),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _statChip(Icons.schedule_rounded, session.duration),
                          _statChip(Icons.place_outlined, session.location),
                          _statChip(Icons.bolt_rounded, session.intensity),
                          _statChip(
                            Icons.format_list_numbered_rounded,
                            'Session ${shownIndex + 1}/${programme.sessions.length}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        session.focus,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF245B69),
                        ),
                      ),
                      if (session.personalisationNote.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          session.personalisationNote,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF627D98),
                          ),
                        ),
                      ],
                      if (adaptation != null && adaptation.status != SafetyStatus.normal) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: adaptation.blocksTraining
                                ? const Color(0xFFFFEBEE)
                                : const Color(0xFFEAF7FA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            adaptation.blocksTraining
                                ? 'Training is paused because your safety answers include a warning sign.'
                                : 'This session will use your saved limitation settings and conservative exercise substitutions.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: adaptation.blocksTraining
                                  ? const Color(0xFF8E1B1B)
                                  : const Color(0xFF245B69),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: adaptation?.blocksTraining == true
                              ? null
                              : _startCurrentWorkout,
                          icon: Icon(
                            activeIndex != null
                                ? Icons.play_circle_fill_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(58),
                            backgroundColor: const Color(0xFF176B87),
                            foregroundColor: Colors.white,
                          ),
                          label: Text(
                            adaptation?.blocksTraining == true
                                ? 'MEDICAL REVIEW BEFORE TRAINING'
                                : activeIndex != null
                                    ? 'CONTINUE SESSION'
                                    : 'START WORKOUT',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      if (activeIndex == null) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _skipCurrentSession,
                            icon: const Icon(Icons.skip_next_rounded),
                            label: const Text(
                              'SKIP THIS SESSION',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Skipping is recorded so LeanIt can adjust next week instead of assuming the plan was completed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.35,
                            color: Color(0xFF829AB1),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              if (recoveryAvailable) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F8DC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD8E89A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0C7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.self_improvement_rounded,
                              color: Color(0xFF55721B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'RECOVERY OPTION',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF55721B),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  readiness!.score < 40
                                      ? 'Recovery is the priority today'
                                      : 'Consider a lighter recovery day',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF102A43),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your readiness is ${readiness.score.round()}/100. LeanIt can guide easy movement, mobility, stretching and breathing without advancing your programme or adding strength volume.',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Color(0xFF486581),
                        ),
                      ),
                      const SizedBox(height: 13),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _startRecoveryDay,
                          icon: const Icon(Icons.self_improvement_rounded),
                          label: const Text(
                            'START RECOVERY DAY',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your planned workout remains available if you decide to train.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF829AB1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReadinessScreen()),
                  ).then((_) => _load());
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD9E2EC)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7F9),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFF176B87),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Readiness',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF102A43),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              readiness == null
                                  ? 'No check-in yet — tap to record sleep, energy, soreness and stress.'
                                  : '${readiness.score.round()}/100 • ${readiness.recommendation}',
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: Color(0xFF627D98),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
              if (nextSession != null) ...[
                const SizedBox(height: 22),
                const Text(
                  'After this',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.skip_next_rounded, color: Color(0xFF176B87)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${nextSession.day} • ${nextSession.title} • ${nextSession.duration}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF486581),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => widget.fallbackProgrammeHome),
                    ).then((_) => _load());
                  },
                  icon: const Icon(Icons.calendar_view_week_outlined),
                  label: const Text(
                    'VIEW FULL PROGRAMME',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    foregroundColor: const Color(0xFF176B87),
                    side: const BorderSide(color: Color(0xFF176B87)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${programme.structure} • ${_string('session_length', '45 min')} sessions',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF829AB1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
