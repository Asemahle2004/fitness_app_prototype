import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_health.dart';
import 'exercise_repository.dart';
import 'leanit_preferences.dart';
import 'media_coverage_engine.dart';
import 'sync_queue.dart';
import 'training_settings.dart';
import 'training_tools_screen.dart';
import 'unit_display.dart';

class LeanItControlCenterScreen extends StatefulWidget {
  const LeanItControlCenterScreen({super.key});

  @override
  State<LeanItControlCenterScreen> createState() =>
      _LeanItControlCenterScreenState();
}

class _LeanItControlCenterScreenState
    extends State<LeanItControlCenterScreen> {
  late final SupabaseClient _client;
  late final String _scope;
  late final TrainingSettingsStore _trainingStore;
  late final LeanItPreferencesStore _preferencesStore;

  TrainingSettings _training = const TrainingSettings();
  LeanItPreferences _preferences = const LeanItPreferences();
  SecurityHealthReport? _security;
  List<AppErrorRecord> _errors = const [];
  MediaCoverageAudit? _media;
  int _pendingSync = 0;
  bool _loading = true;
  bool _saving = false;
  bool _syncing = false;
  bool _auditingMedia = false;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _scope = _client.auth.currentUser?.id ?? 'guest';
    _trainingStore = TrainingSettingsStore(userScope: _scope);
    _preferencesStore = LeanItPreferencesStore(userScope: _scope);
    _load();
  }

  Future<void> _load() async {
    final trainingFuture = _trainingStore.load();
    final preferencesFuture = _preferencesStore.load();
    final errorsFuture = AppErrorStore.load();
    final securityFuture = SecurityHealthEngine.inspect(userScope: _scope);
    final queueFuture = SyncQueueStore(userScope: _scope).load();

    final training = await trainingFuture;
    final preferences = await preferencesFuture;
    final errors = await errorsFuture;
    final security = await securityFuture;
    final queue = await queueFuture;
    UnitDisplay.setSystem(training.unitSystem);
    LeanItPreferencesCache.set(preferences);
    if (!mounted) return;
    setState(() {
      _training = training;
      _preferences = preferences;
      _errors = errors;
      _security = security;
      _pendingSync = queue.length;
      _loading = false;
    });
  }

  Future<void> _saveTraining(TrainingSettings next) async {
    setState(() {
      _training = next;
      _saving = true;
    });
    UnitDisplay.setSystem(next.unitSystem);
    await _trainingStore.save(next);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _savePreferences(LeanItPreferences next) async {
    setState(() {
      _preferences = next;
      _saving = true;
    });
    await _preferencesStore.save(next);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _pickReminderTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _preferences.reminderHour,
        minute: _preferences.reminderMinute,
      ),
    );
    if (selected == null) return;
    await _savePreferences(
      _preferences.copyWith(
        reminderHour: selected.hour,
        reminderMinute: selected.minute,
      ),
    );
  }

  Future<void> _flushSync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final result = await SyncCoordinator(
        client: _client,
        userScope: _scope,
      ).flush();
      if (!mounted) return;
      setState(() => _pendingSync = result.remaining);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.attempted == 0
                ? 'Nothing is waiting to sync.'
                : 'Synced ${result.completed}/${result.attempted}. ${result.remaining} still waiting.',
          ),
        ),
      );
    } catch (error) {
      await AppErrorStore.record('Manual sync', error);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _auditMedia() async {
    if (_auditingMedia) return;
    setState(() => _auditingMedia = true);
    try {
      final audit = await MediaCoverageEngine.audit(
        ExerciseRepository(_client),
      );
      if (mounted) setState(() => _media = audit);
    } catch (error) {
      await AppErrorStore.record('Media audit', error);
    } finally {
      if (mounted) setState(() => _auditingMedia = false);
    }
  }

  Future<void> _clearErrors() async {
    await AppErrorStore.clear();
    if (mounted) setState(() => _errors = const []);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nextReminder = WorkoutReminderPlanner.nextReminder(_preferences);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('LeanIt Control Center'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          const Text(
            'Settings, reminders & app health',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'One place for units, coaching cues, workout reminders, accessibility, data usage, offline sync, media coverage and diagnostics.',
            style: TextStyle(color: Color(0xFF627D98), height: 1.45),
          ),
          const SizedBox(height: 18),
          _card(
            title: 'Units',
            icon: Icons.straighten_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<UnitSystem>(
                  segments: const [
                    ButtonSegment(value: UnitSystem.metric, label: Text('Metric')),
                    ButtonSegment(value: UnitSystem.imperial, label: Text('Imperial')),
                  ],
                  selected: {_training.unitSystem},
                  onSelectionChanged: (value) {
                    if (value.isNotEmpty) {
                      _saveTraining(_training.copyWith(unitSystem: value.first));
                    }
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  _training.isMetric
                      ? 'kg • km • cm • min/km'
                      : 'lb • miles • inches/ft • min/mile',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF486581),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'History remains stored canonically in metric values; only input and display conversion changes.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF829AB1)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            title: 'Workout reminders',
            icon: Icons.notifications_active_outlined,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable workout reminders'),
                  subtitle: Text(
                    nextReminder == null
                        ? 'No upcoming reminder.'
                        : 'Next: ${_dateTime(nextReminder)}',
                  ),
                  value: _preferences.workoutRemindersEnabled,
                  onChanged: (value) => _savePreferences(
                    _preferences.copyWith(workoutRemindersEnabled: value),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_rounded),
                  title: const Text('Reminder time'),
                  subtitle: Text(WorkoutReminderPlanner.formatTime(_preferences)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickReminderTime,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final selected = _preferences.reminderWeekdays.contains(day);
                    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    return FilterChip(
                      label: Text(names[index]),
                      selected: selected,
                      onSelected: (value) {
                        final next = {..._preferences.reminderWeekdays};
                        value ? next.add(day) : next.remove(day);
                        if (next.isEmpty) return;
                        _savePreferences(
                          _preferences.copyWith(reminderWeekdays: next),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'LeanIt surfaces scheduled reminders inside the app and Home dashboard. Native Android notification delivery is verified during the final Android release pass.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF829AB1)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            title: 'Accessibility',
            icon: Icons.accessibility_new_rounded,
            child: Column(
              children: [
                _switch(
                  'Larger text',
                  'Increase text scale in the member shell.',
                  _preferences.largeText,
                  (value) => _savePreferences(
                    _preferences.copyWith(largeText: value),
                  ),
                ),
                _switch(
                  'Reduced motion',
                  'Prefer shorter or disabled decorative animations.',
                  _preferences.reducedMotion,
                  (value) => _savePreferences(
                    _preferences.copyWith(reducedMotion: value),
                  ),
                ),
                _switch(
                  'High contrast',
                  'Increase contrast for key navigation and status surfaces.',
                  _preferences.highContrast,
                  (value) => _savePreferences(
                    _preferences.copyWith(highContrast: value),
                  ),
                ),
                _switch(
                  'Larger tap targets',
                  'Prefer roomier controls for easier touch interaction.',
                  _preferences.largerTapTargets,
                  (value) => _savePreferences(
                    _preferences.copyWith(largerTapTargets: value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            title: 'Performance & data',
            icon: Icons.speed_rounded,
            child: Column(
              children: [
                _switch(
                  'Low-data mode',
                  'Avoid unnecessary media refreshes on limited data.',
                  _preferences.lowDataMode,
                  (value) => _savePreferences(
                    _preferences.copyWith(
                      lowDataMode: value,
                      preloadExerciseMedia:
                          value ? false : _preferences.preloadExerciseMedia,
                    ),
                  ),
                ),
                _switch(
                  'Preload exercise media',
                  'Warm likely exercise images when data mode allows it.',
                  _preferences.preloadExerciseMedia,
                  _preferences.lowDataMode
                      ? null
                      : (value) => _savePreferences(
                            _preferences.copyWith(preloadExerciseMedia: value),
                          ),
                ),
                _switch(
                  'Automatic cloud retry',
                  'Retry failed training-data writes when LeanIt is active again.',
                  _preferences.automaticSync,
                  (value) => _savePreferences(
                    _preferences.copyWith(automaticSync: value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            title: 'Offline & cloud sync',
            icon: Icons.cloud_sync_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pendingSync == 0
                      ? 'All queued training writes are synced.'
                      : '$_pendingSync training write${_pendingSync == 1 ? '' : 's'} waiting for cloud retry.',
                  style: const TextStyle(color: Color(0xFF486581)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _syncing ? null : _flushSync,
                    icon: _syncing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                    label: Text(_syncing ? 'SYNCING…' : 'SYNC NOW'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            title: 'Security review',
            icon: Icons.security_rounded,
            child: Column(
              children: [
                ...?_security?.checks.map(
                  (check) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      check.passed
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_rounded,
                      color: check.passed
                          ? const Color(0xFF0F6B4B)
                          : const Color(0xFF9A6700),
                    ),
                    title: Text(check.label),
                    subtitle: Text(check.detail),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            title: 'Exercise media coverage',
            icon: Icons.photo_library_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_media == null)
                  const Text(
                    'Run an on-demand audit to avoid loading the whole exercise catalogue every time Settings opens.',
                    style: TextStyle(color: Color(0xFF627D98)),
                  )
                else ...[
                  Text(
                    '${_media!.resolvedMovements}/${_media!.approvedMovements} programme movements resolve to media (${_media!.resolvedPercent.toStringAsFixed(0)}%).',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_media!.reviewedMovements} have production-reviewed media • ${_media!.referenceOnlyMovements.length} are reference-only • ${_media!.missingMovements.length} still need coverage.',
                    style: const TextStyle(color: Color(0xFF627D98)),
                  ),
                  if (_media!.missingMovements.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Priority: ${_media!.missingMovements.take(8).join(', ')}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF829AB1)),
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _auditingMedia ? null : _auditMedia,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(_auditingMedia ? 'AUDITING…' : 'AUDIT MEDIA COVERAGE'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            title: 'Diagnostics',
            icon: Icons.bug_report_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _errors.isEmpty
                      ? 'No recent locally captured errors.'
                      : '${_errors.length} recent diagnostic event${_errors.length == 1 ? '' : 's'} stored locally.',
                ),
                if (_errors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ..._errors.take(5).map(
                        (error) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(error.area),
                          subtitle: Text(error.message),
                          trailing: Text(
                            '${error.occurredAt.day}/${error.occurredAt.month}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                  TextButton.icon(
                    onPressed: _clearErrors,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('CLEAR DIAGNOSTICS'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            title: 'Training tools',
            icon: Icons.calculate_outlined,
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrainingToolsScreen(settings: _training),
                  ),
                ),
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('OPEN CALCULATORS'),
              ),
            ),
          ),
          if (_saving) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _switch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF176B87)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  String _dateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month} $hour:$minute';
  }
}
