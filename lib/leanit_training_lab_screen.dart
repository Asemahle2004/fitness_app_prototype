import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'evidence_review_screen.dart';
import 'fitness_integrations_screen.dart';
import 'motivation_community_screen.dart';
import 'offline_training_pack.dart';
import 'programme_library_screen.dart';
import 'running_goal_plan_screen.dart';
import 'strength_intelligence_screen.dart';
import 'training_context_cache.dart';
import 'training_context_engine.dart';
import 'training_store.dart';

class LeanItTrainingLabScreen extends StatefulWidget {
  const LeanItTrainingLabScreen({super.key});

  @override
  State<LeanItTrainingLabScreen> createState() =>
      _LeanItTrainingLabScreenState();
}

class _LeanItTrainingLabScreenState extends State<LeanItTrainingLabScreen> {
  OfflineTrainingPackStatus? _offlineStatus;
  bool _preparingOffline = false;
  int? _readinessScore;
  TrainingContextMode _contextMode = TrainingContextMode.normal;

  String get _scope =>
      Supabase.instance.client.auth.currentUser?.id ?? 'guest';

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final pack = OfflineTrainingPack(
      client: Supabase.instance.client,
      userScope: _scope,
    );
    final statusFuture = pack.status();
    final readinessFuture = TrainingStore.loadReadiness();
    final status = await statusFuture;
    final readiness = await readinessFuture;
    if (!mounted) return;
    setState(() {
      _offlineStatus = status;
      _readinessScore = readiness.isEmpty ? null : readiness.first.score.round();
      _contextMode = TrainingContextCache.current?.mode ?? TrainingContextMode.normal;
    });
  }

  Future<void> _prepareOffline() async {
    if (_preparingOffline) return;
    setState(() => _preparingOffline = true);
    try {
      final status = await OfflineTrainingPack(
        client: Supabase.instance.client,
        userScope: _scope,
      ).prepare();
      if (!mounted) return;
      setState(() => _offlineStatus = status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Offline pack ready: ${status.exercises} exercises and ${status.programmeSessions} current programme sessions cached.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _preparingOffline = false);
    }
  }

  void _selectContext(TrainingContextMode mode) {
    setState(() => _contextMode = mode);
    if (mode == TrainingContextMode.normal) {
      TrainingContextCache.clear();
    } else {
      TrainingContextCache.set(mode, readinessScore: _readinessScore);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mode == TrainingContextMode.normal
              ? 'Temporary training context cleared.'
              : '${mode.label} will adapt workouts opened during the next 8 hours.',
        ),
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('LeanIt Training Lab'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
        children: [
          const Text(
            'Adaptive training systems',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _readinessScore == null
                ? 'Advanced coaching, programme design, running goals, evidence, offline tools and integrations.'
                : 'Latest readiness: $_readinessScore/100 • advanced coaching, programme design, running goals and app integrations.',
            style: const TextStyle(height: 1.45, color: Color(0xFF627D98)),
          ),
          const SizedBox(height: 20),
          _featureCard(
            icon: Icons.bolt_rounded,
            title: 'Running coach • 100 m to Marathon',
            description:
                'Sprint, long sprint, middle-distance and endurance plans with guided sessions, pace zones, race predictions, tapering and weather/recovery adjustment.',
            onTap: () => _open(const RunningGoalPlanScreen()),
          ),
          _featureCard(
            icon: Icons.fitness_center_rounded,
            title: 'Strength intelligence',
            description:
                'Per-muscle recovery and weekly volume, set-level RPE/RIR, plateaus, estimated strength, double progression and back-off recommendations.',
            onTap: () => _open(const StrengthIntelligenceScreen()),
          ),
          _featureCard(
            icon: Icons.library_books_rounded,
            title: 'Programme library & builder',
            description:
                'Reviewed multi-week blocks plus a custom 4–12 week builder that can become your current programme.',
            onTap: () => _open(const ProgrammeLibraryScreen()),
          ),
          const SizedBox(height: 10),
          _section(
            title: 'How are you training today?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Temporary modes expire automatically and never rewrite your permanent equipment/location profile.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF627D98)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TrainingContextMode.values.map((mode) {
                    return ChoiceChip(
                      label: Text(mode.label),
                      selected: _contextMode == mode,
                      onSelected: (_) => _selectContext(mode),
                    );
                  }).toList(growable: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _featureCard(
            icon: Icons.rule_folder_rounded,
            title: 'Evidence & review portal',
            description:
                'Inspect programme rules, sources and review status. Only Approved rules can drive automation.',
            onTap: () => _open(const EvidenceReviewScreen()),
          ),
          _featureCard(
            icon: Icons.watch_rounded,
            title: 'Health & device ecosystem',
            description:
                'Health Connect, Apple Health, Strava, Garmin, Wear OS and Apple Watch integration architecture with honest setup state.',
            onTap: () => _open(const FitnessIntegrationsScreen()),
          ),
          _featureCard(
            icon: Icons.emoji_events_rounded,
            title: 'Achievements, reviews & challenges',
            description:
                'Weekly review, annual LeanIt Wrapped, milestones, local challenges and privacy-controlled share summaries.',
            onTap: () => _open(const MotivationCommunityScreen()),
          ),
          const SizedBox(height: 10),
          _section(
            title: 'Offline training pack',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _offlineStatus == null
                      ? 'No explicit offline pack prepared yet. Existing workout history remains local-first.'
                      : 'Prepared ${_date(_offlineStatus!.preparedAt)} • ${_offlineStatus!.exercises} exercises • ${_offlineStatus!.programmeSessions} current sessions • ${_offlineStatus!.approvedEvidenceRules} approved rules.',
                  style: const TextStyle(color: Color(0xFF486581)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _preparingOffline ? null : _prepareOffline,
                    icon: const Icon(Icons.offline_pin_rounded),
                    label: Text(
                      _preparingOffline
                          ? 'PREPARING…'
                          : _offlineStatus == null
                              ? 'PREPARE OFFLINE PACK'
                              : 'REFRESH OFFLINE PACK',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Equipment intelligence is live',
            child: const Text(
              'Inside Live Workout, LeanIt already separates temporarily occupied equipment, equipment missing at this location and equipment unavailable only today. You can substitute, move the exercise later or skip it; moved work stays pending and LeanIt asks again later if the equipment becomes free.',
              style: TextStyle(height: 1.45, color: Color(0xFF486581)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7FA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF176B87)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(description),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';
}
