import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'lean_eat_theme.dart';
import 'profile_service.dart';
import 'training_profile_edit_screen.dart';

class LeanEatAccountScreen extends StatefulWidget {
  const LeanEatAccountScreen({super.key});

  @override
  State<LeanEatAccountScreen> createState() => _LeanEatAccountScreenState();
}

class _LeanEatAccountScreenState extends State<LeanEatAccountScreen> {
  late final SupabaseClient _client;
  late final ProfileService _profiles;
  late Future<Map<String, dynamic>?> _profileFuture;
  final _nameController = TextEditingController();
  String _visualPreference = 'Match my profile';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _profiles = ProfileService(_client);
    _profileFuture = _loadProfile();
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final row = await _profiles.currentProfileMap();
    if (row != null) {
      _nameController.text =
          (row['display_name'] ?? row['full_name'] ?? '').toString();
      final pref = row['visual_preference'] as String?;
      _visualPreference = switch (pref) {
        'Female' => 'Female',
        'Male' => 'Male',
        'Neutral' => 'Neutral',
        _ => 'Match my profile',
      };
    }
    return row;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      _message('Enter a display name of at least 2 characters.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _profiles.updateProfile({
        'display_name': name,
        'full_name': name,
        'visual_preference': switch (_visualPreference) {
          'Female' => 'Female',
          'Male' => 'Male',
          'Neutral' => 'Neutral',
          _ => null,
        },
      });
      if (mounted) {
        _message('Profile updated.');
        setState(() => _profileFuture = _loadProfile());
      }
    } on PostgrestException catch (e) {
      _message(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _list(dynamic value) {
    if (value is List) return value.whereType<String>().join(', ');
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final user = _client.auth.currentUser;
    return Scaffold(
      backgroundColor: LeanEatColors.background,
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await _client.auth.signOut();
              if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF153B2F), Color(0xFF277A58)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    const LeanEatLogo(size: 62, showWordmark: false),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (profile?['display_name'] ?? profile?['full_name'] ?? 'LeanEat member') as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              profile?['onboarding_complete'] == true
                                  ? 'PERSONALISED PROFILE ACTIVE'
                                  : 'ONBOARDING NOT COMPLETE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _section(
                title: 'Profile',
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _visualPreference,
                      decoration: const InputDecoration(
                        labelText: 'Exercise model preference',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Match my profile', child: Text('Match my profile sex')),
                        DropdownMenuItem(value: 'Female', child: Text('Female exercise models')),
                        DropdownMenuItem(value: 'Male', child: Text('Male exercise models')),
                        DropdownMenuItem(value: 'Neutral', child: Text('No gender preference')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _visualPreference = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'SAVING…' : 'SAVE PROFILE'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (profile != null)
                _section(
                  title: 'Training profile',
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TrainingProfileEditScreen(),
                              ),
                            );
                            if (changed == true && mounted) {
                              setState(() => _profileFuture = _loadProfile());
                            }
                          },
                          icon: const Icon(Icons.tune_rounded),
                          label: const Text('EDIT TRAINING PROFILE'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      _fact(Icons.flag_outlined, 'Goal', profile['main_goal']?.toString() ?? 'Not set'),
                      _fact(Icons.person_outline, 'Sex', profile['sex']?.toString() ?? 'Not set'),
                      _fact(Icons.speed_outlined, 'Level', profile['fitness_level']?.toString() ?? 'Not set'),
                      _fact(Icons.fitness_center_outlined, 'Experience', profile['experience']?.toString() ?? 'Not set'),
                      _fact(Icons.location_on_outlined, 'Training', _list(profile['training_locations'])),
                      _fact(Icons.calendar_month_outlined, 'Days', _list(profile['available_days'])),
                      _fact(Icons.timer_outlined, 'Session', profile['session_length']?.toString() ?? 'Not set'),
                      if (profile['has_limitation'] == true)
                        _fact(
                          Icons.health_and_safety_outlined,
                          'Limitations',
                          _list(profile['affected_areas']).isEmpty
                              ? 'Reported'
                              : _list(profile['affected_areas']),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              _section(
                title: 'LeanEat Analyzer',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'See why LeanEat built your plan, which evidence sources informed it, and the latest analysis saved to your account.',
                      style: TextStyle(height: 1.45, color: Color(0xFF66766D)),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PlanAnalysisScreen()),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('WHY THIS PLAN?'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E9E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: LeanEatColors.ink),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _fact(IconData icon, String title, String value) {
    if (value.isEmpty) value = 'Not set';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: LeanEatColors.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: Text(title, style: const TextStyle(color: Color(0xFF718078), fontWeight: FontWeight.w700)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: LeanEatColors.ink))),
        ],
      ),
    );
  }
}

class PlanAnalysisScreen extends StatelessWidget {
  const PlanAnalysisScreen({super.key});

  Future<Map<String, dynamic>?> _latestAnalysis() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;
    return client
        .from('plan_analysis')
        .select('generated_at,goal,summary,evidence_source_ids,programme_json')
        .eq('user_id', user.id)
        .order('generated_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> _sources(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await Supabase.instance.client
        .from('evidence_sources')
        .select('id,title,organisation,source_type,notes')
        .inFilter('id', ids);
    return (rows as List).whereType<Map<String, dynamic>>().toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LeanEatColors.background,
      appBar: AppBar(title: const Text('Why this plan?')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _latestAnalysis(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load your plan analysis.'));
          }
          final analysis = snapshot.data;
          if (analysis == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'Complete onboarding and create a programme first. LeanEat will then save the reasoning and evidence behind your plan here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final ids = (analysis['evidence_source_ids'] as List? ?? const [])
              .whereType<String>()
              .toList(growable: false);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF153B2F), Color(0xFF4B9A68)]),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LEANEAT ANALYZER', style: TextStyle(color: Color(0xFFCBF07D), fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Text(
                      analysis['goal']?.toString() ?? 'Your programme',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      analysis['summary']?.toString() ?? 'Your plan was generated from your onboarding profile and LeanEat evidence rules.',
                      style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('Evidence used', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: LeanEatColors.ink)),
              const SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _sources(ids),
                builder: (context, sourceSnapshot) {
                  if (sourceSnapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  final sources = sourceSnapshot.data ?? const [];
                  if (sources.isEmpty) {
                    return const Text('No evidence references were attached to this analysis.');
                  }
                  return Column(
                    children: sources
                        .map(
                          (source) => Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.verified_outlined, color: LeanEatColors.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(source['organisation']?.toString() ?? 'Evidence source', style: const TextStyle(fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 4),
                                        Text(source['title']?.toString() ?? ''),
                                        if ((source['source_type']?.toString() ?? '').isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(source['source_type'].toString(), style: const TextStyle(color: Color(0xFF718078), fontSize: 12)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6DE),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'LeanEat uses this evidence to guide fitness programming and conservative exercise modification. It does not diagnose disease or replace individual medical care.',
                  style: TextStyle(height: 1.45, color: Color(0xFF735A18)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
