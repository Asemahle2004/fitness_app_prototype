import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'custom_training_block_store.dart';
import 'programme_activation_service.dart';
import 'programme_engine.dart';
import 'programme_library_engine.dart';

class ProgrammeLibraryScreen extends StatefulWidget {
  const ProgrammeLibraryScreen({super.key});

  @override
  State<ProgrammeLibraryScreen> createState() => _ProgrammeLibraryScreenState();
}

class _ProgrammeLibraryScreenState extends State<ProgrammeLibraryScreen> {
  bool _activating = false;

  Future<void> _activate(ProgrammeTemplate template) async {
    if (_activating) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Start ${template.title}?'),
        content: const Text(
          'This becomes your current programme starting at Week 1. Workout history is not deleted, and LeanIt may still adapt future weeks from readiness and performance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('START PROGRAMME'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _activating = true);
    try {
      await ProgrammeActivationService(Supabase.instance.client).activate(
        template.toGeneratedProgramme(),
        source: 'library:${template.id}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${template.title} is now your current programme.')),
      );
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = ProgrammeLibraryEngine.templates
        .where((item) => item.approved)
        .toList(growable: false);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Programme library'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => const CustomTrainingBlockBuilderScreen(),
          ),
        ),
        icon: const Icon(Icons.edit_calendar_rounded),
        label: const Text('BUILD YOUR OWN'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
        children: [
          const Text(
            'Reviewed training blocks',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a structured starting point. Approved evidence-rule IDs stay attached so LeanIt can explain what the block is built around.',
            style: TextStyle(height: 1.45, color: Color(0xFF627D98)),
          ),
          const SizedBox(height: 18),
          ...templates.map(
            (template) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Text(
                  template.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${template.weeks} weeks • ${template.daysPerWeek} days/week • ${template.levels.join(' / ')}',
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      template.description,
                      style: const TextStyle(height: 1.4, color: Color(0xFF486581)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...template.goals.map((item) => Chip(label: Text(item))),
                        ...template.equipment.map((item) => Chip(label: Text(item))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...template.sessions.map(
                    (session) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_note_rounded),
                      title: Text('${session.day} • ${session.title}'),
                      subtitle: Text(
                        '${session.duration} • ${session.location}\n${session.focus}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Evidence: ${template.evidenceRuleIds.join(', ')}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF829AB1)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _activating ? null : () => _activate(template),
                      child: const Text('USE THIS PROGRAMME'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomTrainingBlockBuilderScreen extends StatefulWidget {
  const CustomTrainingBlockBuilderScreen({super.key});

  @override
  State<CustomTrainingBlockBuilderScreen> createState() =>
      _CustomTrainingBlockBuilderScreenState();
}

class _CustomTrainingBlockBuilderScreenState
    extends State<CustomTrainingBlockBuilderScreen> {
  final _name = TextEditingController(text: 'My Training Block');
  final _goal = TextEditingController(text: 'General Fitness');
  int _weeks = 8;
  bool _allowAdaptation = true;
  bool _saving = false;
  final List<_SessionDraft> _sessions = <_SessionDraft>[
    _SessionDraft(day: 'Monday', title: 'Workout A'),
    _SessionDraft(day: 'Wednesday', title: 'Workout B'),
    _SessionDraft(day: 'Friday', title: 'Workout C'),
  ];

  String get _scope =>
      Supabase.instance.client.auth.currentUser?.id ?? 'guest';

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    for (final session in _sessions) {
      session.dispose();
    }
    super.dispose();
  }

  void _addSession() {
    if (_sessions.length >= 7) return;
    setState(() => _sessions.add(
          _SessionDraft(day: 'Saturday', title: 'Workout ${String.fromCharCode(65 + _sessions.length)}'),
        ));
  }

  void _removeSession(int index) {
    if (_sessions.length <= 1) return;
    final removed = _sessions.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  List<PlannedSession> _plannedSessions() {
    return _sessions.map((draft) {
      return PlannedSession(
        day: draft.day,
        title: draft.title.text.trim().isEmpty ? 'Workout' : draft.title.text.trim(),
        location: draft.location,
        duration: draft.duration,
        focus: draft.focus.text.trim().isEmpty
            ? 'Custom training focus'
            : draft.focus.text.trim(),
        intensity: draft.intensity,
        personalisationNote:
            'Custom block • LeanIt adaptation ${_allowAdaptation ? 'enabled' : 'disabled'}',
      );
    }).toList(growable: false);
  }

  Future<void> _save({required bool activate}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final store = CustomTrainingBlockStore(userScope: _scope);
      final block = await store.create(
        name: _name.text,
        weeks: _weeks,
        goal: _goal.text,
        sessions: _plannedSessions(),
        allowLeanItAdaptation: _allowAdaptation,
      );
      if (activate) {
        await ProgrammeActivationService(Supabase.instance.client).activate(
          GeneratedProgramme(
            goal: block.goal,
            structure: '${block.weeks}-week custom training block',
            explanation: block.allowLeanItAdaptation
                ? 'You built this block. LeanIt can adapt future weeks for recovery and completion while preserving your selected session structure.'
                : 'You built this block. Automatic week-level adaptation is disabled for this saved design.',
            sessions: block.sessions,
          ),
          source: 'custom:${block.id}',
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(activate
              ? '${block.name} saved and activated.'
              : '${block.name} saved to your custom blocks.'),
        ),
      );
      if (activate) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const days = <String>[
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Build training block'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Block name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goal,
            decoration: const InputDecoration(labelText: 'Main goal'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _weeks,
            decoration: const InputDecoration(labelText: 'Block length'),
            items: List.generate(9, (index) => index + 4)
                .map((value) => DropdownMenuItem(
                      value: value,
                      child: Text('$value weeks'),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _weeks = value ?? _weeks),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Allow LeanIt week adaptation'),
            subtitle: const Text(
              'Keep your block structure, but allow recovery/completion signals to reduce or consolidate future weeks.',
            ),
            value: _allowAdaptation,
            onChanged: (value) => setState(() => _allowAdaptation = value),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Weekly sessions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: _sessions.length >= 7 ? null : _addSession,
                icon: const Icon(Icons.add),
                label: const Text('ADD'),
              ),
            ],
          ),
          ..._sessions.asMap().entries.map((entry) {
            final index = entry.key;
            final draft = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: draft.day,
                            decoration: const InputDecoration(labelText: 'Day'),
                            items: days
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ))
                                .toList(),
                            onChanged: (value) => draft.day = value ?? draft.day,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove session',
                          onPressed: _sessions.length <= 1
                              ? null
                              : () => _removeSession(index),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: draft.title,
                      decoration: const InputDecoration(labelText: 'Workout title'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: draft.focus,
                      decoration: const InputDecoration(labelText: 'Focus'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: draft.location,
                            decoration: const InputDecoration(labelText: 'Location'),
                            items: const ['Flexible', 'Gym', 'Home', 'Outside']
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ))
                                .toList(),
                            onChanged: (value) => draft.location = value ?? draft.location,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: draft.duration,
                            decoration: const InputDecoration(labelText: 'Duration'),
                            items: const ['20 min', '30 min', '45 min', '60 min', '75 min']
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ))
                                .toList(),
                            onChanged: (value) => draft.duration = value ?? draft.duration,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: draft.intensity,
                      decoration: const InputDecoration(labelText: 'Intensity'),
                      items: const ['Easy', 'Easy–Moderate', 'Moderate', 'Moderate–Hard', 'Hard but controlled']
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (value) => draft.intensity = value ?? draft.intensity,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: _saving ? null : () => _save(activate: false),
            child: const Text('SAVE BLOCK'),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _saving ? null : () => _save(activate: true),
            child: Text(_saving ? 'SAVING…' : 'SAVE & USE THIS BLOCK'),
          ),
        ],
      ),
    );
  }
}

class _SessionDraft {
  String day;
  final TextEditingController title;
  final TextEditingController focus = TextEditingController();
  String location = 'Flexible';
  String duration = '45 min';
  String intensity = 'Moderate';

  _SessionDraft({required this.day, required String title})
      : title = TextEditingController(text: title);

  void dispose() {
    title.dispose();
    focus.dispose();
  }
}
