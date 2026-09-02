import 'package:flutter/material.dart';

import 'body_progress_store.dart';
import 'unit_display.dart';

class BodyProgressFormScreen extends StatefulWidget {
  const BodyProgressFormScreen({super.key});

  @override
  State<BodyProgressFormScreen> createState() => _BodyProgressFormScreenState();
}

class _BodyProgressFormScreenState extends State<BodyProgressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _bodyFat = TextEditingController();
  final _chest = TextEditingController();
  final _waist = TextEditingController();
  final _hips = TextEditingController();
  final _arm = TextEditingController();
  final _thigh = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _weight.dispose();
    _bodyFat.dispose();
    _chest.dispose();
    _waist.dispose();
    _hips.dispose();
    _arm.dispose();
    _thigh.dispose();
    _notes.dispose();
    super.dispose();
  }

  double? _entered(TextEditingController controller) {
    final raw = controller.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  double? _weightKg(TextEditingController controller) {
    final value = _entered(controller);
    return value == null ? null : UnitDisplay.canonicalWeight(value);
  }

  double? _lengthCm(TextEditingController controller) {
    final value = _entered(controller);
    return value == null ? null : UnitDisplay.canonicalLengthCm(value);
  }

  String? _validateCanonical(
    String? value, {
    required double minCanonical,
    required double maxCanonical,
    required bool weight,
  }) {
    final raw = value?.trim().replaceAll(',', '.') ?? '';
    if (raw.isEmpty) return null;
    final entered = double.tryParse(raw);
    if (entered == null) return 'Enter a valid number';
    final canonical = weight
        ? UnitDisplay.canonicalWeight(entered)
        : UnitDisplay.canonicalLengthCm(entered);
    if (canonical < minCanonical || canonical > maxCanonical) {
      final minDisplay = weight
          ? UnitDisplay.displayWeightValue(minCanonical)
          : UnitDisplay.displayLengthValue(minCanonical);
      final maxDisplay = weight
          ? UnitDisplay.displayWeightValue(maxCanonical)
          : UnitDisplay.displayLengthValue(maxCanonical);
      final unit = weight ? UnitDisplay.weightUnit : UnitDisplay.lengthUnit;
      return 'Use ${minDisplay.toStringAsFixed(0)}–${maxDisplay.toStringAsFixed(0)} $unit';
    }
    return null;
  }

  String? _validatePercent(String? value) {
    final raw = value?.trim().replaceAll(',', '.') ?? '';
    if (raw.isEmpty) return null;
    final parsed = double.tryParse(raw);
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 2 || parsed > 80) return 'Use 2–80 %';
    return null;
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final entry = BodyProgressEntry.create(
      recordedAt: DateTime(
        _date.year,
        _date.month,
        _date.day,
        DateTime.now().hour,
        DateTime.now().minute,
      ),
      weightKg: _weightKg(_weight),
      bodyFatPercent: _entered(_bodyFat),
      chestCm: _lengthCm(_chest),
      waistCm: _lengthCm(_waist),
      hipsCm: _lengthCm(_hips),
      armCm: _lengthCm(_arm),
      thighCm: _lengthCm(_thigh),
      notes: _notes.text,
    );
    if (!entry.hasMeasurements) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one body measurement.')),
      );
      return;
    }

    setState(() => _saving = true);
    await BodyProgressStore().saveEntry(entry);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  String _dateLabel() => '${_date.day}/${_date.month}/${_date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Log body progress'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            const Text(
              'Record only what you want to track.',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF102A43),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'LeanIt displays measurements in your selected units and stores them canonically so changing units later never changes your history.',
              style: const TextStyle(color: Color(0xFF627D98), height: 1.4),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFD9E2EC)),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF176B87),
                ),
                title: const Text('Measurement date'),
                subtitle: Text(_dateLabel()),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 18),
            _NumberField(
              controller: _weight,
              label: 'Body weight',
              suffix: UnitDisplay.weightUnit,
              validator: (value) => _validateCanonical(
                value,
                minCanonical: 20,
                maxCanonical: 500,
                weight: true,
              ),
            ),
            _NumberField(
              controller: _bodyFat,
              label: 'Body fat',
              suffix: '%',
              validator: _validatePercent,
            ),
            const SizedBox(height: 10),
            const Text(
              'Tape measurements',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102A43),
              ),
            ),
            const SizedBox(height: 10),
            _NumberField(
              controller: _chest,
              label: 'Chest',
              suffix: UnitDisplay.lengthUnit,
              validator: (value) => _validateCanonical(
                value,
                minCanonical: 20,
                maxCanonical: 300,
                weight: false,
              ),
            ),
            _NumberField(
              controller: _waist,
              label: 'Waist',
              suffix: UnitDisplay.lengthUnit,
              validator: (value) => _validateCanonical(
                value,
                minCanonical: 20,
                maxCanonical: 300,
                weight: false,
              ),
            ),
            _NumberField(
              controller: _hips,
              label: 'Hips',
              suffix: UnitDisplay.lengthUnit,
              validator: (value) => _validateCanonical(
                value,
                minCanonical: 20,
                maxCanonical: 300,
                weight: false,
              ),
            ),
            _NumberField(
              controller: _arm,
              label: 'Arm',
              suffix: UnitDisplay.lengthUnit,
              validator: (value) => _validateCanonical(
                value,
                minCanonical: 10,
                maxCanonical: 150,
                weight: false,
              ),
            ),
            _NumberField(
              controller: _thigh,
              label: 'Thigh',
              suffix: UnitDisplay.lengthUnit,
              validator: (value) => _validateCanonical(
                value,
                minCanonical: 10,
                maxCanonical: 200,
                weight: false,
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Example: morning measurement before breakfast',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('SAVE MEASUREMENT'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final String? Function(String?) validator;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
