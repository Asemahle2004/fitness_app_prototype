import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';
import 'training_settings.dart';
import 'training_tools_engine.dart';
import 'unit_display.dart';

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
  final _notes = TextEditingController();

  final Set<String> _goals = {};
  final Set<String> _locations = {'Gym'};
  final Set<String> _equipment = {};
  final Set<String> _days = {};
  final Set<String> _areas = {};
  final Set<String> _warnings = {};

  UnitSystem _units = UnitSystem.metric;
  String _sex = 'Male';
  String _activity = 'Moderately active';
  String _experience = 'Beginner';
  String _fitness = 'Low';
  String _duration = '45 min';
  String _time = 'It changes';
  String _gym = 'Full gym';
  bool _limited = false;
  bool _saving = false;

  static const goals = [
    'Build Muscle',
    'Lose Body Fat',
    'Improve General Fitness',
    'Start Running',
    'Improve Running Performance',
    'Gain Weight',
  ];
  static const days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const equipment = [
    'Bodyweight only', 'Dumbbells', 'Resistance bands', 'Pull-up bar', 'Bench',
    'Barbell', 'Weight plates', 'Kettlebell', 'Skipping rope'
  ];
  static const areas = [
    'Shoulder', 'Elbow', 'Wrist / Hand', 'Back', 'Hip', 'Knee', 'Ankle / Foot', 'Neck', 'Other'
  ];
  static const warnings = [
    'Severe pain after an injury, I cannot put weight on the area, or it looks out of position',
    'New numbness, tingling or unusual weakness',
    'A joint is hot or swollen and I also feel feverish or generally unwell',
    'Chest pain, fainting, severe dizziness or unusual breathlessness with activity',
    'A clinician has told me not to exercise this area yet',
  ];

  bool get _metric => _units == UnitSystem.metric;
  String get _heightUnit => _metric ? 'cm' : 'in';
  String get _weightUnit => _metric ? 'kg' : 'lb';

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _notes.dispose();
    super.dispose();
  }

  double? _number(String value) => double.tryParse(value.trim().replaceAll(',', '.'));

  double? _canonicalHeight(String value) {
    final entered = _number(value);
    if (entered == null) return null;
    return _metric ? entered : TrainingToolsEngine.inchesToCm(entered);
  }

  double? _canonicalWeight(String value) {
    final entered = _number(value);
    if (entered == null) return null;
    return TrainingToolsEngine.toCanonicalWeight(entered, _units);
  }

  void _toggle(Set<String> values, String value) {
    setState(() {
      if (values.contains(value)) {
        values.remove(value);
      } else {
        values.add(value);
      }
    });
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_goals.isEmpty) {
      _message('Choose at least one goal.');
      return;
    }
    if (_locations.isEmpty) {
      _message('Choose at least one training location.');
      return;
    }
    if (_days.isEmpty) {
      _message('Choose at least one available training day.');
      return;
    }
    if (_limited && _areas.isEmpty) {
      _message('Choose the area affected by your limitation.');
      return;
    }

    final age = int.tryParse(_age.text.trim());
    final heightCm = _canonicalHeight(_height.text);
    final weightKg = _canonicalWeight(_weight.text);
    if (age == null || heightCm == null || weightKg == null) return;

    setState(() => _saving = true);
    try {
      final selectedGoals = _goals.toList(growable: false);
      await ProfileService(Supabase.instance.client).updateProfile({
        'sex': _sex,
        'age': age,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'main_goal': selectedGoals.first,
        'goals': selectedGoals,
        'activity_level': _activity,
        'experience': _experience,
        'fitness_level': _fitness,
        'training_locations': _locations.toList(growable: false),
        'home_equipment': _locations.contains('Home')
            ? _equipment.toList(growable: false)
            : <String>[],
        'gym_access': _locations.contains('Gym') ? _gym : null,
        'available_days': _days.toList(growable: false),
        'session_length': _duration,
        'training_time': _time,
        'has_limitation': _limited,
        'affected_areas': _limited ? _areas.toList(growable: false) : <String>[],
        'limitation_notes': _limited ? _notes.text.trim() : '',
        'warning_signs': _limited ? _warnings.toList(growable: false) : <String>[],
        'onboarding_complete': true,
      });

      final scope = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      final store = TrainingSettingsStore(userScope: scope);
      final current = await store.load();
      await store.save(current.copyWith(unitSystem: _units));
      UnitDisplay.setSystem(_units);
    } on PostgrestException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('Could not save onboarding. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _section(String title, String subtitle, Widget body) => Container(
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
            body,
          ],
        ),
      );

  Widget _chips(
    Iterable<String> values,
    Set<String> selected, {
    void Function(String)? customToggle,
  }) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: values.map((value) => FilterChip(
          label: Text(value),
          selected: selected.contains(value),
          onSelected: (_) {
            if (customToggle != null) {
              customToggle(value);
            } else {
              _toggle(selected, value);
            }
          },
        )).toList(growable: false),
      );

  Widget _dropdown(String label, String value, List<String> values, void Function(String) changed) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: values.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(growable: false),
        onChanged: (item) {
          if (item != null) changed(item);
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Set up LeanIt')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            const Text('Build one programme around your real goals',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              'Choose more than one goal when needed. LeanIt can combine muscle building, fat loss and running instead of forcing one objective.',
              style: TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF627D98)),
            ),
            const SizedBox(height: 18),
            _section(
              '1. Goals',
              'Choose all that matter. LeanIt uses the complete set when generating your concurrent programme.',
              _chips(goals, _goals),
            ),
            _section(
              '2. About you',
              'Choose your units now. LeanIt stores canonical values internally, so you can switch units later without changing your history.',
              Column(children: [
                SegmentedButton<UnitSystem>(
                  segments: const [
                    ButtonSegment(value: UnitSystem.metric, label: Text('Metric')),
                    ButtonSegment(value: UnitSystem.imperial, label: Text('Imperial')),
                  ],
                  selected: {_units},
                  onSelectionChanged: (value) => setState(() => _units = value.first),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(
                    controller: _age,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age'),
                    validator: (value) {
                      final n = int.tryParse(value?.trim() ?? '');
                      return n == null || n < 13 || n > 100 ? '13–100' : null;
                    },
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _dropdown('Sex', _sex, const ['Male', 'Female'],
                      (value) => setState(() => _sex = value))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(
                    controller: _height,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Height ($_heightUnit)'),
                    validator: (value) {
                      final cm = _canonicalHeight(value ?? '');
                      return cm == null || cm < 100 || cm > 250
                          ? 'Enter a valid height'
                          : null;
                    },
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Weight ($_weightUnit)'),
                    validator: (value) {
                      final kg = _canonicalWeight(value ?? '');
                      return kg == null || kg < 25 || kg > 350
                          ? 'Enter a valid weight'
                          : null;
                    },
                  )),
                ]),
                const SizedBox(height: 12),
                _dropdown('Activity', _activity,
                    const ['Mostly inactive', 'Lightly active', 'Moderately active', 'Very active'],
                    (value) => setState(() => _activity = value)),
                const SizedBox(height: 12),
                _dropdown('Training experience', _experience,
                    const ['Beginner', 'Intermediate', 'Advanced'],
                    (value) => setState(() => _experience = value)),
                const SizedBox(height: 12),
                _dropdown('Current fitness level', _fitness,
                    const ['Low', 'Moderate', 'High'],
                    (value) => setState(() => _fitness = value)),
              ]),
            ),
            _section(
              '3. Where can you train?',
              'The generator removes exercises that do not fit your environment or available equipment.',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _chips(const ['Gym', 'Home', 'Outside'], _locations),
                if (_locations.contains('Gym')) ...[
                  const SizedBox(height: 12),
                  _dropdown('Gym access', _gym, const ['Full gym', 'Basic gym', "I'm not sure"],
                      (value) => setState(() => _gym = value)),
                ],
                if (_locations.contains('Home')) ...[
                  const SizedBox(height: 14),
                  const Text('Home equipment', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  _chips(equipment, _equipment, customToggle: (value) {
                    setState(() {
                      if (value == 'Bodyweight only') {
                        if (_equipment.contains(value)) {
                          _equipment.remove(value);
                        } else {
                          _equipment..clear()..add(value);
                        }
                      } else {
                        _equipment.remove('Bodyweight only');
                        if (_equipment.contains(value)) {
                          _equipment.remove(value);
                        } else {
                          _equipment.add(value);
                        }
                      }
                    });
                  }),
                ],
              ]),
            ),
            _section(
              '4. Schedule',
              'Workout duration includes estimated work, rest, setup, transitions, warm-up and cooldown.',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _chips(days, _days),
                const SizedBox(height: 14),
                _dropdown('Workout duration', _duration,
                    const ['15 min', '30 min', '45 min', '60 min', '90+ min'],
                    (value) => setState(() => _duration = value)),
                const SizedBox(height: 12),
                _dropdown('Usual training time', _time,
                    const ['Morning', 'Afternoon', 'Evening', 'It changes'],
                    (value) => setState(() => _time = value)),
              ]),
            ),
            _section(
              '5. Pain, injury or limitations',
              'LeanIt can filter obvious conflicts, but it does not diagnose or replace medical care.',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('A limitation currently affects my training'),
                  value: _limited,
                  onChanged: (value) => setState(() {
                    _limited = value;
                    if (!value) {
                      _areas.clear();
                      _warnings.clear();
                      _notes.clear();
                    }
                  }),
                ),
                if (_limited) ...[
                  const Text('Affected area', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  _chips(areas, _areas),
                  const SizedBox(height: 12),
                  TextField(controller: _notes, maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Optional limitation note')),
                  const SizedBox(height: 12),
                  const Text('Warning signs', style: TextStyle(fontWeight: FontWeight.w800)),
                  ...warnings.map((warning) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _warnings.contains(warning),
                    title: Text(warning, style: const TextStyle(fontSize: 13)),
                    onChanged: (_) => _toggle(_warnings, warning),
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
