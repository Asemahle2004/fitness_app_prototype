import 'package:flutter/material.dart';

import 'personal_record_celebration.dart';
import 'personal_record_engine.dart';
import 'run_tracking_store.dart';
import 'unit_display.dart';

class RunLogFormScreen extends StatefulWidget {
  const RunLogFormScreen({super.key});

  @override
  State<RunLogFormScreen> createState() => _RunLogFormScreenState();
}

class _RunLogFormScreenState extends State<RunLogFormScreen> {
  final _distance = TextEditingController();
  final _durationMinutes = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _distance.dispose();
    _durationMinutes.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      );
    });
  }

  Future<void> _save() async {
    final enteredDistance =
        double.tryParse(_distance.text.trim().replaceAll(',', '.'));
    final minutes =
        double.tryParse(_durationMinutes.text.trim().replaceAll(',', '.'));
    if (enteredDistance == null ||
        enteredDistance <= 0 ||
        minutes == null ||
        minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid distance and duration.')),
      );
      return;
    }

    final distanceKm = UnitDisplay.canonicalDistanceKm(enteredDistance);
    setState(() => _saving = true);
    final record = RunRecord(
      id: 'run_${DateTime.now().microsecondsSinceEpoch}',
      startedAt: _date,
      durationSeconds: (minutes * 60).round(),
      distanceMeters: distanceKm * 1000,
      source: 'manual',
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    final previous = await RunTrackingStore.load();
    final achievements = PersonalRecordEngine.newRunRecords(
      current: record,
      previous: previous,
    );
    await RunTrackingStore.save(record);
    if (!mounted) return;
    await PersonalRecordCelebration.showDialogIfNeeded(context, achievements);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final distanceUnit = UnitDisplay.distanceUnit;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Add run'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Log a completed run',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use this for treadmill runs, races, or runs recorded on another watch/app. Distance is entered in $distanceUnit and stored canonically by LeanIt.',
            style: const TextStyle(color: Color(0xFF627D98), height: 1.4),
          ),
          const SizedBox(height: 20),
          _field(
            controller: _distance,
            label: 'Distance ($distanceUnit)',
            hint: UnitDisplay.isMetric ? '5.00' : '3.10',
            icon: Icons.route_outlined,
          ),
          const SizedBox(height: 14),
          _field(
            controller: _durationMinutes,
            label: 'Duration (minutes)',
            hint: '30',
            icon: Icons.timer_outlined,
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD9E2EC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: Color(0xFF176B87)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Date: ${_date.day}/${_date.month}/${_date.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF102A43),
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notes,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Easy run, intervals, race, treadmill...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'SAVING...' : 'SAVE RUN'),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
