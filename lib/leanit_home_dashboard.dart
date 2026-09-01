import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'adaptive_strength_engine.dart';
import 'lean_eat_theme.dart';
import 'leanit_control_center_screen.dart';
import 'leanit_preferences.dart';
import 'periodization_engine.dart';
import 'programme_store.dart';
import 'progress_screen.dart';
import 'readiness_screen.dart';
import 'strength_adaptation_cache.dart';
import 'sync_queue.dart';
import 'today_dashboard.dart';
import 'training_decision_explainer.dart';
import 'training_store.dart';

class LeanItHomeDashboard extends StatefulWidget {
  final Widget fallbackProgrammeHome;

  const LeanItHomeDashboard({
    super.key,
    required this.fallbackProgrammeHome,
  });

  @override
  State<LeanItHomeDashboard> createState() => _LeanItHomeDashboardState();
}

class _LeanItHomeDashboardState extends State<LeanItHomeDashboard> {
  late final SupabaseClient _client;
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final scope = _client.auth.currentUser?.id ?? 'guest';
    final programmeFuture = ProgrammeStore(_client).loadCurrent();
    final readinessFuture = TrainingStore.loadReadiness();
    final workoutsFuture = TrainingStore.loadWorkouts();
    final preferencesFuture = LeanItPreferencesStore(userScope: scope).load();
    final queueFuture = SyncQueueStore(userScope: scope).load();

    final programme = await programmeFuture;
    final readiness = await readinessFuture;
    final workouts = await workoutsFuture;
    final preferences = await preferencesFuture;
    final queue = await queueFuture;
    final strength = StrengthAdaptationCache.current;
    final week = programme?.currentWeek ?? 1;
    final periodization = PeriodizationEngine.forWeek(
      programmeWeek: week,
      forceRecovery: strength?.action == StrengthAdaptationAction.deload,
      consolidate: strength?.action == StrengthAdaptationAction.reduce ||
          strength?.action == StrengthAdaptationAction.maintain,
      progressionSupported:
          strength?.action == StrengthAdaptationAction.progress,
    );
    final explanation = TrainingDecisionExplainer.explain(
      strength: strength,
      periodization: periodization,
    );

    return _HomeData(
      programme: programme,
      readiness: readiness.isEmpty ? null : readiness.first,
      workouts: workouts,
      preferences: preferences,
      pendingSync: queue.length,
      strength: strength,
      periodization: periodization,
      explanation: explanation,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _openToday() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LeanEatTodayDashboard(
          fallbackProgrammeHome: widget.fallbackProgrammeHome,
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LeanEatColors.background,
      body: SafeArea(
        child: FutureBuilder<_HomeData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data ?? const _HomeData();
            final next = data.programme?.currentSession;
            final reminder = data.preferences == null
                ? null
                : WorkoutReminderPlanner.nextReminder(data.preferences!);
            final readiness = data.readiness;
            final todayWorkouts = data.workouts.where((workout) {
              final now = DateTime.now();
              final at = workout.completedAt;
              return at.year == now.year &&
                  at.month == now.month &&
                  at.day == now.day;
            }).length;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
                children: [
                  Row(
                    children: [
                      const LeanEatLogo(size: 42, showWordmark: false),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LeanIt',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF102A43),
                              ),
                            ),
                            Text(
                              'Adaptive training dashboard',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF627D98),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Control Center',
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LeanItControlCenterScreen(),
                            ),
                          );
                          if (mounted) await _refresh();
                        },
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _hero(data),
                  const SizedBox(height: 14),
                  if (next != null)
                    _nextSessionCard(
                      week: data.programme?.currentWeek ?? 1,
                      title: next.title,
                      day: next.day,
                      duration: next.duration,
                      location: next.location,
                      intensity: next.intensity,
                      onStart: _openToday,
                    )
                  else
                    _simpleCard(
                      icon: Icons.fitness_center_rounded,
                      title: 'Open today’s training',
                      body:
                          'Your programme workspace is ready. Open it to review or start the current session.',
                      buttonLabel: 'OPEN TRAINING',
                      onPressed: _openToday,
                    ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _metric(
                        Icons.favorite_outline_rounded,
                        'Readiness',
                        readiness == null ? 'No check-in' : '${readiness.score.round()}%',
                      ),
                      _metric(
                        Icons.calendar_today_outlined,
                        'Today',
                        '$todayWorkouts workout${todayWorkouts == 1 ? '' : 's'}',
                      ),
                      _metric(
                        Icons.cloud_sync_outlined,
                        'Sync queue',
                        data.pendingSync == 0
                            ? 'Up to date'
                            : '${data.pendingSync} waiting',
                      ),
                      _metric(
                        Icons.notifications_none_rounded,
                        'Reminder',
                        reminder == null ? 'Off / none' : _shortReminder(reminder),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _periodizationCard(data.periodization),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReadinessScreen(),
                            ),
                          ).then((_) => _refresh()),
                          icon: const Icon(Icons.favorite_outline_rounded),
                          label: const Text('READINESS'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProgressScreen(),
                            ),
                          ).then((_) => _refresh()),
                          icon: const Icon(Icons.insights_outlined),
                          label: const Text('PROGRESS'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _hero(_HomeData data) {
    final explanation = data.explanation;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF123C34), Color(0xFF176B87)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  explanation?.decision ?? 'BUILD BASELINE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Week ${data.programme?.currentWeek ?? 1}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data.strength?.headline ?? data.periodization?.headline ??
                'Train consistently and let the evidence build',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            explanation?.why ??
                'LeanIt will keep collecting readiness and training performance before it makes aggressive changes.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.45,
            ),
          ),
          if (explanation != null) ...[
            const SizedBox(height: 12),
            Text(
              'WHAT CHANGES • ${explanation.whatChanges}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _nextSessionCard({
    required int week,
    required String title,
    required String day,
    required String duration,
    required String location,
    required String intensity,
    required VoidCallback onStart,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NEXT TRAINING SESSION',
            style: TextStyle(
              color: Color(0xFF176B87),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$day • $duration • $location • $intensity',
            style: const TextStyle(color: Color(0xFF627D98)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('OPEN TODAY’S TRAINING'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodizationCard(PeriodizationPlan? plan) {
    if (plan == null) return const SizedBox.shrink();
    return Container(
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
            backgroundColor: Color(0xFFF3F8DC),
            child: Icon(Icons.auto_graph_rounded, color: Color(0xFF55721B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${plan.phase.label} block',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.headline,
                  style: const TextStyle(color: Color(0xFF627D98), height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Volume ${(plan.strengthSetMultiplier * 100).round()}% • load ${(plan.workingLoadMultiplier * 100).round()}% • ${plan.allowDropSets ? 'drop sets available' : 'drop sets off'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

  Widget _metric(IconData icon, String label, String value) => Container(
        width: 165,
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
            const SizedBox(height: 9),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF102A43),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF627D98)),
            ),
          ],
        ),
      );

  Widget _simpleCard({
    required IconData icon,
    required String title,
    required String body,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF176B87)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(body, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      );

  static String _shortReminder(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month} $h:$m';
  }
}

class _HomeData {
  final StoredProgramme? programme;
  final ReadinessRecord? readiness;
  final List<WorkoutRecord> workouts;
  final LeanItPreferences? preferences;
  final int pendingSync;
  final StrengthAdaptationRecommendation? strength;
  final PeriodizationPlan? periodization;
  final TrainingDecisionExplanation? explanation;

  const _HomeData({
    this.programme,
    this.readiness,
    this.workouts = const <WorkoutRecord>[],
    this.preferences,
    this.pendingSync = 0,
    this.strength,
    this.periodization,
    this.explanation,
  });
}
