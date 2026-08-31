import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'lean_eat_theme.dart';
import 'profile_service.dart';

class TrainingProfileEditScreen extends StatefulWidget {
  const TrainingProfileEditScreen({super.key});

  @override
  State<TrainingProfileEditScreen> createState() => _TrainingProfileEditScreenState();
}

class _TrainingProfileEditScreenState extends State<TrainingProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _limitationNotes = TextEditingController();

  late final SupabaseClient _client;
  late final ProfileService _profiles;
  late Future<void> _loadFuture;

  String _goal = 'Improve General Fitness';
  String _sex = 'Male';
  String _activity = 'Moderately active';
  String _experience = 'Beginner';
  String _fitnessLevel = 'Low';
  String _sessionLength = '45 min';
  String _trainingTime = 'Flexible';
  String _gymAccess = 'Standard gym';
  bool _hasLimitation = false;
  bool _saving = false;

  final Set<String> _locations = <String>{'Gym'};
  final Set<String> _homeEquipment = <String>{};
  final Set<String> _days = <String>{};
  final Set<String> _affectedAreas = <String>{};
  final Set<String> _warningSigns = <String>{};

  static const goals = [
    'Build Muscle',
    'Lose Body Fat',
    'Improve General Fitness',
    'Start Running',
    'Improve Running Performance',
    'Gain Weight',
  ];

  static const sexes = ['Male', 'Female'];

  static const activityLevels = [
    'Mostly sedentary',
    'Lightly active',
    'Moderately active',
    'Very active',
  ];

  static const experienceLevels = ['Beginner', 'Intermediate', 'Advanced'];

  static const fitnessLevels = ['Low', 'Moderate', 'High'];

  static const locations = ['Gym', 'Home', 'Outside'];

  static const homeEquipment = [
    'None / Bodyweight',
    'Resistance bands',
    'Dumbbells',
    'Kettlebell',
    'Bench',
    'Pull-up bar',
    'Barbell + plates',
    'Cardio machine',
  ];

  static const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const sessionLengths = ['20 min', '30 min', '45 min', '60 min', '75+ min'];
  static const trainingTimes = ['Morning', 'Afternoon', 'Evening', 'Flexible'];
  static const gymAccessOptions = ['Basic gym', 'Standard gym', 'Full commercial gym'];

  static const affectedAreaOptions = [
    'Shoulder',
    'Elbow',
    'Wrist / Hand',
    'Back',
    'Hip',
    'Knee',
    'Ankle / Foot',
    'Neck',
    'Other',
  ];

  static const warningSignOptions = [
    'Severe pain after an injury, I cannot put weight on the area, or it looks out of position',
    'New numbness, tingling or unusual weakness',
    'A joint is hot or swollen and I also feel feverish or generally unwell',
    'Chest pain, fainting, severe dizziness or unusual breathlessness with activity',
    'A clinician has told me not to exercise this area yet',
  ];

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _profiles = ProfileService(_client);
    _loadFuture = _load();
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _limitationNotes.dispose();
    super.dispose();
  }

  List<String> _strings(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  String _allowed(String? value, List<String> options, String fallback) {
    return value != null && options.contains(value) ? value : fallback;
  }

  Future<void> _load() async {
    final row = await _profiles.currentProfileMap();
    if (row == null) return;

    _goal = _allowed(row['main_goal']?.toString(), goals, _goal);
    _sex = _allowed(row['sex']?.toString(), sexes, _sex);
    _activity = _allowed(row['activity_level']?.toString(), activityLevels, _activity);
    _experience = _allowed(row['experience']?.toString(), experienceLevels, _experience);
    _fitnessLevel = _allowed(row['fitness_level']?.toString(), fitnessLevels, _fitnessLevel);
    _sessionLength = _allowed(row['session_length']?.toString(), sessionLengths, _sessionLength);
    _trainingTime = _allowed(row['training_time']?.toString(), trainingTimes, _trainingTime);
    _gymAccess = _allowed(row['gym_access']?.toString(), gymAccessOptions, _gymAccess);
    _hasLimitation = row['has_limitation'] == true;

    _age.text = row['age']?.toString() ?? '';
    _height.text = row['height_cm']?.toString() ?? '';
    _weight.text = row['weight_kg']?.toString() ?? '';
    _limitationNotes.text = row['limitation_notes']?.toString() ?? '';

    _locations
      ..clear()
      ..addAll(_strings(row['training_locations']).where(locations.contains));
    if (_locations.isEmpty) _locations.add('Gym');

    _homeEquipment
      ..clear()
      ..addAll(_strings(row['home_equipment']).where(homeEquipment.contains));

    _days
      ..clear()
      ..addAll(_strings(row['available_days']).where(days.contains));

    _affectedAreas
      ..clear()
      ..addAll(_strings(row['affected_areas']).where(affectedAreaOptions.contains));

    _warningSigns
      ..clear()
      ..addAll(_strings(row['warning_signs']).where(warningSignOptions.contains));
  }

  double? _number(String value) => double.tryParse(value.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_locations.isEmpty) {
      _message('Choose at least one training location.');
      return;
    }
    if (_days.isEmpty) {
      _message('Choose at least one training day.');
      return;
    }
    if (_hasLimitation && _affectedAreas.isEmpty) {
      _message('Choose the area affected by your limitation.');
      return;
    }

    final age = int.tryParse(_age.text.trim());
    final height = _number(_height.text);
    final weight = _number(_weight.text);
    if (age == null || age < 13 || age > 100 || height == null || height < 100 || height > 250 || weight == null || weight < 25 || weight > 350) {
      _message('Check age, height and weight values.');
      return;
    }

    setState(() => _saving = true);
    try {
      await _profiles.updateProfile({
        'sex': _sex,
        'age': age,
        'height_cm': height,
        'weight_kg': weight,
        'main_goal': _goal,
        'activity_level': _activity,
        'experience': _experience,
        'fitness_level': _fitnessLevel,
        'training_locations': _locations.toList(),
        'home_equipment': _locations.contains('Home') ? _homeEquipment.toList() : <String>[],
        'gym_access': _locations.contains('Gym') ? _gymAccess : null,
        'available_days': _days.toList(),
        'session_length': _sessionLength,
        'training_time': _trainingTime,
        'has_limitation': _hasLimitation,
        'affected_areas': _hasLimitation ? _affectedAreas.toList() : <String>[],
        'limitation_notes': _hasLimitation ? _limitationNotes.text.trim() : '',
        'warning_signs': _hasLimitation ? _warningSigns.toList() : <String>[],
        'onboarding_complete': true,
      });

      try {
        await _client.functions.invoke(
          'plan-analyzer',
          body: {
            'goal': _goal,
            'experience': _experience,
            'fitnessLevel': _fitnessLevel,
            'availableDays': _days.toList(),
            'locations': _locations.toList(),
            'sessionLength': _sessionLength,
            'hasLimitation': _hasLimitation,
            'affectedAreas': _affectedAreas.toList(),
          },
        );
      } on FunctionException catch (error) {
        if (mounted) {
          _message('Profile saved. Analyzer refresh failed: ${error.reasonPhrase ?? error.status}');
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on PostgrestException catch (error) {
      _message(error.message);
    } catch (error) {
      _message('Could not save the training profile. $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LeanEatColors.background,
      appBar: AppBar(title: const Text('Edit training profile')),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load your saved training profile.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => setState(() => _loadFuture = _load()),
                      child: const Text('TRY AGAIN'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
              children: [
                _hero(),
                const SizedBox(height: 16),
                _section(
                  title: 'Goal and training level',
                  child: Column(
                    children: [
                      _dropdown('Main goal', _goal, goals, (value) => setState(() => _goal = value)),
                      const SizedBox(height: 12),
                      _dropdown('Experience', _experience, experienceLevels, (value) => setState(() => _experience = value)),
                      const SizedBox(height: 12),
                      _dropdown('Current fitness level', _fitnessLevel, fitnessLevels, (value) => setState(() => _fitnessLevel = value)),
                      const SizedBox(height: 12),
                      _dropdown('Activity level', _activity, activityLevels, (value) => setState(() => _activity = value)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  title: 'About you',
                  child: Column(
                    children: [
                      _dropdown('Sex', _sex, sexes, (value) => setState(() => _sex = value)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _numberField(_age, 'Age', '22')),
                          const SizedBox(width: 10),
                          Expanded(child: _numberField(_height, 'Height (cm)', '175')),
                          const SizedBox(width: 10),
                          Expanded(child: _numberField(_weight, 'Weight (kg)', '70')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  title: 'Where you train',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _chips(locations, _locations),
                      if (_locations.contains('Gym')) ...[
                        const SizedBox(height: 14),
                        _dropdown('Gym access', _gymAccess, gymAccessOptions, (value) => setState(() => _gymAccess = value)),
                      ],
                      if (_locations.contains('Home')) ...[
                        const SizedBox(height: 18),
                        const Text('Home equipment', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        _chips(homeEquipment, _homeEquipment),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  title: 'Schedule',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Available days', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      _chips(days, _days),
                      const SizedBox(height: 16),
                      _dropdown('Typical session length', _sessionLength, sessionLengths, (value) => setState(() => _sessionLength = value)),
                      const SizedBox(height: 12),
                      _dropdown('Normal training time', _trainingTime, trainingTimes, (value) => setState(() => _trainingTime = value)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  title: 'Pain, injury or limitations',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('A limitation currently affects my exercise', style: TextStyle(fontWeight: FontWeight.w800)),
                        value: _hasLimitation,
                        onChanged: (value) => setState(() {
                          _hasLimitation = value;
                          if (!value) {
                            _affectedAreas.clear();
                            _warningSigns.clear();
                            _limitationNotes.clear();
                          }
                        }),
                      ),
                      if (_hasLimitation) ...[
                        const SizedBox(height: 10),
                        const Text('Affected area', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        _chips(affectedAreaOptions, _affectedAreas),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _limitationNotes,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Optional limitation note'),
                        ),
                        const SizedBox(height: 18),
                        const Text('Safety warning signs', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        const Text(
                          'Select only signs that apply right now. These can pause app-directed training until appropriate medical review.',
                          style: TextStyle(color: Color(0xFF66766D), height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        ...warningSignOptions.map(
                          (sign) => CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _warningSigns.contains(sign),
                            title: Text(sign, style: const TextStyle(fontSize: 14)),
                            onChanged: (_) => setState(() {
                              if (_warningSigns.contains(sign)) {
                                _warningSigns.remove(sign);
                              } else {
                                _warningSigns.add(sign);
                              }
                            }),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(_saving ? 'SAVING…' : 'SAVE & REBUILD MY PLAN'),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Changing these details updates your saved account profile and asks LeanEat Analyzer to rebuild the reasoning behind your programme.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF718078), height: 1.4),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF153B2F), Color(0xFF338A61)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.tune_rounded, color: LeanEatColors.lime, size: 34),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your plan follows this profile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text('Change it here instead of repeating onboarding.', style: TextStyle(color: Color(0xFFD8EADF), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E9E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: LeanEatColors.ink)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: options.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(growable: false),
      onChanged: (newValue) {
        if (newValue != null) onChanged(newValue);
      },
    );
  }

  Widget _numberField(TextEditingController controller, String label, String hint) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
    );
  }

  Widget _chips(List<String> options, Set<String> selected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((item) {
        final isSelected = selected.contains(item);
        return FilterChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (_) => setState(() {
            if (isSelected) {
              selected.remove(item);
            } else {
              selected.add(item);
            }
          }),
        );
      }).toList(growable: false),
    );
  }
}
