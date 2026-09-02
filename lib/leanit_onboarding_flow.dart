import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';

class LeanItOnboardingFlow extends StatefulWidget {
  const LeanItOnboardingFlow({super.key});

  @override
  State<LeanItOnboardingFlow> createState() => _LeanItOnboardingFlowState();
}

class _LeanItOnboardingFlowState extends State<LeanItOnboardingFlow> {
  final _formKey = GlobalKey<FormState>();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _limitationNotes = TextEditingController();

  final Set<String> _goals = <String>{};
  final Set<String> _locations = <String>{'Gym'};
  final Set<String> _homeEquipment = <String>{};
  final Set<String> _days = <String>{};
  final Set<String> _affectedAreas = <String>{};
  final Set<String> _warningSigns = <String>{};

  String _sex = 'Male';
  String _activity = 'Moderately active';
  String _experience = 'Beginner';
  String _fitness = 'Low';
  String _sessionLength = '45 min';
  String _trainingTime = 'It changes';
  String _gymAccess = 'Full gym';
  bool _hasLimitation = false;
  bool _saving = false;

  static const _goalOptions = <String>[
    'Build Muscle',
    'Lose Body Fat',
    'Improve General Fitness',
    'Start Running',
    'Improve Running Performance',
    'Gain Weight',
  ];
  static const _daysOptions = <String>[
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const _equipmentOptions = <String>[
    'Bodyweight only',
    'Dumbbells',
    'Resistance bands',
    'Pull-up bar',
    'Bench',
    'Barbell',
    'Weight plates',
    'Kettlebell',
    'Skipping rope',
  ];
  static const _areaOptions = <String>[
    'Shoulder', 'Elbow', 'Wrist / Hand', 'Back', 'Hip', 'Knee', 'Ankle / Foot', 'Neck', 'Other',
  ];
  static const _warningOptions = <String>[
    'Severe pain after an injury, I cannot put weight on the area, or it looks out of position',
    'New numbness, tingling or unusual weakness',
    'A joint is hot or swollen and I also feel feverish or generally unwell',
    'Chest pain, fainting, severe dizziness or unusual breathlessness with activity',
    'A clinician has told me not to exercise this area yet',
  ];

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _limitationNotes.dispose();
    super.dispose();
  }

  double? _number(String value) => double.tryParse(value.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_goals.isEmpty) return _message('Choose at least one goal.');
    if (_locations.isEmpty) return _message('Choose at least one training location.');
    if (_days.isEmpty) return _message('Choose at least one available training day.');
    if (_hasLimitation && _affectedAreas.isEmpty) {
      return _message('Choose the area affected by your limitation.');
    }

    final age = int.tryParse(_age.text.trim());
    final height = _number(_height.text);
    final weight = _number(_weight.text);
    if (age == null || height == null || weight == null) return;

    setState(() => _saving = true);
    try {
      final goals = _goals.toList(growable: false);
      await ProfileService(Supabase.instance.client).updateProfile(<String, dynamic>{
        'sex': _sex,
        'age': age,
        'height_cm': height,
        'weight_kg': weight,
        'main_goal': goals.first,
        'goals': goals,
        'activity_level': _activity,
        'experience': _experience,
        'fitness_level': _fitness,
        'training_locations': _locations.toList(growable: false),
        'home_equipment': _locations.contains('Home')
            ? _homeEquipment.toList(growable: false)
            : <String>[],
        'gym_access': _locations.contains('Gym') ? _gymAccess : null,
        'available_days': _days.toList(growable: false),
        'session_length': _sessionLength,
        'training_time': _trainingTime,
        'has_limitation': _hasLimitation,
        'affected_areas': _hasLimitation
            ? _affectedAreas.toList(growable: false)
            : <String>[],
        'limitation_notes': _hasLimitation ? _limitationNotes.text.trim() : '',
        'warning_signs': _hasLimitation
            ? _warningSigns.toList(growable: false)
            : <String>[],
        'onboarding_complete': true,
      });
    } on PostgrestException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('Could not save onboarding. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _toggle(Set<String> set, String value) {
    setState(() {
      if (set.contains(value)) {
        set.remove(value);
      } else {
        set.add(value);
      }
    });
  }

  Widget _section(String title, String subtitle, Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD9E2EC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(color: Color(0xFF627D98), height: 1.35)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );

  Widget _chips(Iterable<String> values, Set<String> selected, {void Function(String)? onTap}) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: values.map((value) => FilterChip(
          label: Text(value),
          selected: selected.contains(value),
          onSelected: (_) => onTap?.call(value) ?? _toggle(selected, value),
        )).toList(growable: false),
      );

  DropdownButtonFormField<String> _dropdown(
    String label,
    String value,
    List<String> items,
    void Function(String) changed,
  ) => DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: (item) {
          if (item != null) changed(item);
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Set up LeanIt'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            const Text(
              'Build one programme around your real goals',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select more than one goal if needed. LeanIt can combine muscle building, fat loss and running instead of forcing you to choose only one.',
              style: TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF627D98)),
            ),
            const SizedBox(height: 18),
            _section(
              '1. Goals',
              'Choose all that matter. The first selected goal is stored as your primary goal for backward compatibility; the generator uses the complete set.',
              _chips(_goalOptions, _goals),
            ),
            _section(
              '2. About you',
              'These details help LeanIt choose an appropriate starting level. They do not make the app guess an unsafe starting weight.',
              Column(
                children: [
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: _age,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Age'),
                      validator: (value) {
                        final number = int.tryParse(value?.trim() ?? '');
                        return number == null || number < 13 || number > 100 ? '13–100' : null;
                      },
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _dropdown('Sex', _sex, const ['Male', 'Female'], (v) => setState(() => _sex = v))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: _height,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Height (cm)'),
                      validator: (value) {
                        final n = _number(value ?? '');
                        return n == null || n < 100 || n > 250 ? '100–250 cm' : null;
                      },
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Weight (kg)'),
                      validator: (value) {
                        final n = _number(value ?? '');
                        return n == null || n < 25 || n > 350 ? '25–350 kg' : null;
                      },
                    )),
                  ]),
                  const SizedBox(height: 12),
                  _dropdown('Activity', _activity, const [
                    'Mostly inactive', 'Lightly active', 'Moderately active', 'Very active'
                  ], (v) => setState(() => _activity = v)),
                  const SizedBox(height: 12),
                  _dropdown('Training experience', _experience, const [
                    'Beginner', 'Intermediate', 'Advanced'
                  ], (v) => setState(() => _experience = v)),
                  const SizedBox(height: 12),
                  _dropdown('Current fitness level', _fitness, const [
                    'Low', 'Moderate', 'High'
                  ], (v) => setState(() => _fitness = v)),
                ],
              ),
            ),
            _section(
              '3. Where can you train?',
              'The exercise selector removes options that do not fit today’s environment or equipment.',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _chips(const ['Gym', 'Home', 'Outside'], _locations),
                if (_locations.contains('Gym')) ...[
                  const SizedBox(height: 12),
                  _dropdown('Gym access', _gymAccess, const ['Full gym', 'Basic gym', "I'm not sure"], (v) => setState(() => _gymAccess = v)),
                ],
                if (_locations.contains('Home')) ...[
                  const SizedBox(height: 14),
                  const Text('Home equipment', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  _chips(_equipmentOptions, _homeEquipment, onTap: (value) {
                    setState(() {
                      if (value == 'Bodyweight only') {
                        if (_homeEquipment.contains(value)) {
                          _homeEquipment.remove(value);
                        } else {
                          _homeEquipment..clear()..add(value);
                        }
                      } else {
                        _homeEquipment.remove('Bodyweight only');
                        _homeEquipment.contains(value) ? _homeEquipment.remove(value) : _homeEquipment.add(value);
                      }
                    });
                  }),
                ],
              ]),
            ),
            _section(
              '4. Schedule',
              'LeanIt uses your actual time budget, including work, rest, setup, transitions and preparation.',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _chips(_daysOptions, _days),
                const SizedBox(height: 14),
                _dropdown('Workout duration', _sessionLength, const [
                  '15 min', '30 min', '45 min', '60 min', '90+ min'
                ], (v) => setState(() => _sessionLength = v)),
                const SizedBox(height: 12),
                _dropdown('Usual training time', _trainingTime, const [
                  'Morning', 'Afternoon', 'Evening', 'It changes'
                ], (v) => setState(() => _trainingTime = v)),
              ]),
            ),
            _section(
              '5. Pain, injury or limitations',
              'LeanIt can filter obvious conflicts, but it does not diagnose or replace medical care.',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('A limitation currently affects my training'),
                  value: _hasLimitation,
                  onChanged: (value) => setState(() {
                    _hasLimitation = value;
                    if (!value) {
                      _affectedAreas.clear();
                      _warningSigns.clear();
                      _limitationNotes.clear();
                    }
                  }),
                if (_hasLimitation) ...[
                  const Text('Affected area', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  _chips(_areaOptions, _affectedAreas),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _limitationNotes,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Optional limitation note'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Warning signs', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ..._warningOptions.map((warning) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _warningSigns.contains(warning),
                    title: Text(warning, style: const TextStyle(fontSize: 13)),
                    onChanged: (_) => _toggle(_warningSigns, warning),
                  )),
                ],
              ]),
            ),
            SizedBox(
              height: 58,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.auto_awesome),
                label: Text(_saving ? 'CREATING PROGRAMME…' : 'CREATE MY PROGRAMME'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
