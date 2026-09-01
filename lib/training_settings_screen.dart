import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'training_settings.dart';
import 'training_tools_screen.dart';

class TrainingSettingsScreen extends StatefulWidget {
  const TrainingSettingsScreen({super.key});

  @override
  State<TrainingSettingsScreen> createState() => _TrainingSettingsScreenState();
}

class _TrainingSettingsScreenState extends State<TrainingSettingsScreen> {
  late final TrainingSettingsStore _store;
  late Future<TrainingSettings> _future;
  TrainingSettings _settings = const TrainingSettings();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _store = TrainingSettingsStore(
      userScope: Supabase.instance.client.auth.currentUser?.id ?? 'guest',
    );
    _future = _load();
  }

  Future<TrainingSettings> _load() async {
    final settings = await _store.load();
    _settings = settings;
    return settings;
  }

  Future<void> _save(TrainingSettings next) async {
    setState(() {
      _settings = next;
      _saving = true;
    });
    await _store.save(next);
    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Training settings'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: FutureBuilder<TrainingSettings>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              const Text(
                'Units & coaching',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF102A43),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'These choices change how LeanIt displays and coaches your training. Stored workout values remain canonical so switching units never rewrites history.',
                style: TextStyle(color: Color(0xFF627D98), height: 1.45),
              ),
              const SizedBox(height: 20),
              _card(
                title: 'Measurement system',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<UnitSystem>(
                      segments: const [
                        ButtonSegment(
                          value: UnitSystem.metric,
                          icon: Icon(Icons.straighten_rounded),
                          label: Text('Metric'),
                        ),
                        ButtonSegment(
                          value: UnitSystem.imperial,
                          icon: Icon(Icons.square_foot_rounded),
                          label: Text('Imperial'),
                        ),
                      ],
                      selected: <UnitSystem>{_settings.unitSystem},
                      onSelectionChanged: (selection) {
                        if (selection.isEmpty) return;
                        _save(_settings.copyWith(unitSystem: selection.first));
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _settings.isMetric
                          ? 'Weight: kg • Distance: km • Height: cm • Pace: min/km'
                          : 'Weight: lb • Distance: miles • Height: ft/in • Pace: min/mile',
                      style: const TextStyle(
                        color: Color(0xFF486581),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _card(
                title: 'Guided workout cues',
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sound cues'),
                      subtitle: const Text('Play a cue when a guided interval changes.'),
                      value: _settings.soundCues,
                      onChanged: (value) =>
                          _save(_settings.copyWith(soundCues: value)),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Vibration cues'),
                      subtitle: const Text('Use haptic feedback for interval changes and countdowns.'),
                      value: _settings.hapticCues,
                      onChanged: (value) =>
                          _save(_settings.copyWith(hapticCues: value)),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('3-second countdown cues'),
                      subtitle: const Text('Cue 3–2–1 before the current guided phase ends.'),
                      value: _settings.countdownCues,
                      onChanged: (value) =>
                          _save(_settings.copyWith(countdownCues: value)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _card(
                title: 'Training tools',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calculate estimated 1RM, working-weight percentages, running pace and barbell plate loading using your selected units.',
                      style: TextStyle(color: Color(0xFF627D98), height: 1.45),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrainingToolsScreen(settings: _settings),
                            ),
                          );
                        },
                        icon: const Icon(Icons.calculate_outlined),
                        label: const Text('OPEN TRAINING TOOLS'),
                      ),
                    ),
                  ],
                ),
              ),
              if (_saving) ...[
                const SizedBox(height: 14),
                const LinearProgressIndicator(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
