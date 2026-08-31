import 'package:flutter/material.dart';

import 'body_progress_store.dart';

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

  double? _number(TextEditingController controller) {
    final raw = controller.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  String? _validateNumber(
    String? value, {
    required double min,
    required double max,
    required String unit,
  }) {
    final raw = value?.trim().replaceAll(',', '.') ?? '';
    if (raw.isEmpty) return null;
    final parsed = double.tryParse(raw);
    if (parsed == null) return 'Enter a valid number';
    if (parsed < min || parsed > max) return 'Use $min–$max $unit';
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
      weightKg: _number(_weight),
      bodyFatPercent: _number(_bodyFat),
      chestCm: _number(_chest),
      waistCm: _number(_waist),
      hipsCm: _number(_hips),
      armCm: _number(_arm),
      thighCm: _number(_thigh),
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
            const Text(
              'LeanIt can follow body changes alongside training performance. You do not need to complete every field.',
              style: TextStyle(color: Color(0xFF627D98), height: 1.4),
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
              suffix: 'kg',
              validator: (value) => _validateNumber(
                value,
                min: 20,
                max: 500,
                unit: 'kg',
              ),
            ),
            _NumberField(
              controller: _bodyFat,
              label: 'Body fat',
              suffix: '%',
              validator: (value) => _validateNumber(
                value,
                min: 2,
                max: 80,
                unit: '%',
              ),
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
              suffix: 'cm',
              validator: (value) => _validateNumber(
                value,
                min: 20,
                max: 300,
                unit: 'cm',
              ),
            ),
            _NumberField(
              controller: _waist,
              label: 'Waist',
              suffix: 'cm',
              validator: (value) => _validateNumber(
                value,
                min: 20,
                max: 300,
                unit: 'cm',
              ),
            ),
            _NumberField(
              controller: _hips,
              label: 'Hips',
              suffix: 'cm',
              validator: (value) => _validateNumber(
                value,
                min: 20,
                max: 300,
                unit: 'cm',
              ),
            ),
            _NumberField(
              controller: _arm,
              label: 'Arm',
              suffix: 'cm',
              validator: (value) => _validateNumber(
                value,
                min: 10,
                max: 150,
                unit: 'cm',
              ),
            ),
            _NumberField(
              controller: _thigh,
              label: 'Thigh',
              suffix: 'cm',
              validator: (value) => _validateNumber(
                value,
                min: 10,
                max: 200,
                unit: 'cm',
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
