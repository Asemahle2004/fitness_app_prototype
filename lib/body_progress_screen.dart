import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'body_progress_engine.dart';
import 'body_progress_form_screen.dart';
import 'body_progress_store.dart';
import 'progress_photo_storage.dart';

class BodyProgressScreen extends StatefulWidget {
  const BodyProgressScreen({super.key});

  @override
  State<BodyProgressScreen> createState() => _BodyProgressScreenState();
}

class _BodyProgressScreenState extends State<BodyProgressScreen> {
  final BodyProgressStore _store = BodyProgressStore();
  final ImagePicker _picker = ImagePicker();
  late Future<_BodyProgressData> _future;
  BodyMetric? _selectedMetric;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BodyProgressData> _load() async {
    final entriesFuture = _store.loadEntries();
    final photosFuture = _store.loadPhotos();
    return _BodyProgressData(
      entries: await entriesFuture,
      photos: await photosFuture,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _addMeasurement() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BodyProgressFormScreen()),
    );
    if (changed == true && mounted) await _refresh();
  }

  Future<ImageSource?> _choosePhotoSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Add progress photo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Choose where the photo should come from.'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<ProgressPhotoAngle?> _choosePhotoAngle() {
    return showModalBottomSheet<ProgressPhotoAngle>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Photo angle',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Using the same angle and similar lighting makes comparisons more useful.',
              ),
            ),
            ...ProgressPhotoAngle.values.map(
              (angle) => ListTile(
                leading: const Icon(Icons.accessibility_new_outlined),
                title: Text(angle.label),
                onTap: () => Navigator.pop(context, angle),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _addPhoto() async {
    if (!progressPhotoPersistenceSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Persistent progress photos are currently available in LeanIt mobile builds. Body measurements still work here.',
          ),
        ),
      );
      return;
    }

    final source = await _choosePhotoSource();
    if (source == null || !mounted) return;
    final angle = await _choosePhotoAngle();
    if (angle == null || !mounted) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;

    final id = 'photo_${DateTime.now().microsecondsSinceEpoch}';
    final path = await persistProgressPhoto(picked, id);
    if (path == null || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('LeanIt could not save that photo.')),
      );
      return;
    }

    await _store.savePhoto(
      ProgressPhotoRecord(
        id: id,
        recordedAt: DateTime.now(),
        angle: angle,
        localPath: path,
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _deleteMeasurement(BodyProgressEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete measurement?'),
        content: const Text('This body-progress entry will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _store.deleteEntry(entry.id);
    if (mounted) await _refresh();
  }

  Future<void> _deletePhoto(ProgressPhotoRecord photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete progress photo?'),
        content: const Text(
          'The photo file and its LeanIt record will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await deleteProgressPhotoFile(photo.localPath);
    await _store.deletePhotoMetadata(photo.id);
    if (mounted) await _refresh();
  }

  String _date(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';

  String _number(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  Widget _summaryCard(String label, String value, IconData icon) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF176B87)),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Color(0xFF627D98))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Body progress'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMeasurement,
        icon: const Icon(Icons.add),
        label: const Text('MEASUREMENT'),
      ),
      body: FutureBuilder<_BodyProgressData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? const _BodyProgressData();
          final entries = data.entries;
          final photos = data.photos;
          final metrics = BodyProgressEngine.availableMetrics(entries);
          final metric = metrics.contains(_selectedMetric)
              ? _selectedMetric!
              : metrics.isEmpty
                  ? null
                  : metrics.first;
          final points = metric == null
              ? const <BodyProgressPoint>[]
              : BodyProgressEngine.seriesFor(entries, metric);

          final latestWeight = BodyProgressEngine.latestWithMetric(
            entries,
            BodyMetric.weight,
          );
          final weightPoints = BodyProgressEngine.seriesFor(
            entries,
            BodyMetric.weight,
          );
          final weightChange = BodyProgressEngine.absoluteChange(weightPoints);
          final latestWaist = BodyProgressEngine.latestWithMetric(
            entries,
            BodyMetric.waist,
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              children: [
                const Text(
                  'Track the result, not only the workout.',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Follow body weight, body fat, tape measurements and progress photos alongside your training history.',
                  style: TextStyle(color: Color(0xFF627D98), height: 1.4),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _summaryCard(
                      'Latest weight',
                      latestWeight?.weightKg == null
                          ? '—'
                          : '${_number(latestWeight!.weightKg!)} kg',
                      Icons.monitor_weight_outlined,
                    ),
                    _summaryCard(
                      'Weight change',
                      weightChange == null
                          ? '—'
                          : '${weightChange >= 0 ? '+' : ''}${_number(weightChange)} kg',
                      Icons.swap_vert_rounded,
                    ),
                    _summaryCard(
                      'Latest waist',
                      latestWaist?.waistCm == null
                          ? '—'
                          : '${_number(latestWaist!.waistCm!)} cm',
                      Icons.straighten_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Body trends',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF102A43),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _addMeasurement,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('LOG'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (metrics.isEmpty)
                  _EmptyCard(
                    text:
                        'Log your first body measurement and LeanIt will build your trend here.',
                    buttonLabel: 'LOG FIRST MEASUREMENT',
                    onPressed: _addMeasurement,
                  )
                else ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: metrics
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(item.label),
                                selected: item == metric,
                                onSelected: (_) {
                                  setState(() => _selectedMetric = item);
                                },
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _TrendCard(
                    metric: metric!,
                    points: points,
                    number: _number,
                    date: _date,
                  ),
                ],
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Progress photos',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF102A43),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _addPhoto,
                      icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                      label: const Text('ADD'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'For useful comparisons, use similar lighting, distance, posture and front/side/back angles.',
                  style: TextStyle(color: Color(0xFF627D98), height: 1.4),
                ),
                const SizedBox(height: 12),
                if (!progressPhotoPersistenceSupported)
                  const _InfoCard(
                    icon: Icons.phone_android_outlined,
                    text:
                        'Persistent progress-photo storage is currently enabled for LeanIt mobile builds. Measurement tracking remains available on web.',
                  )
                else if (photos.isEmpty)
                  _EmptyCard(
                    text:
                        'Add a front, side or back photo when you are ready. Photos stay in LeanIt app storage on this device in this version.',
                    buttonLabel: 'ADD PROGRESS PHOTO',
                    onPressed: _addPhoto,
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: photos.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return _PhotoCard(
                        photo: photo,
                        date: _date,
                        onDelete: () => _deletePhoto(photo),
                      );
                    },
                  ),
                const SizedBox(height: 14),
                const _InfoCard(
                  icon: Icons.lock_outline,
                  text:
                      'Privacy: body measurements and progress-photo records are local-first in this version. Progress photo files are not cloud-backed up by LeanIt yet. Removing app data or uninstalling the app may remove local-only progress data.',
                ),
                const SizedBox(height: 28),
                const Text(
                  'Measurement history',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 10),
                if (entries.isEmpty)
                  const _InfoCard(
                    icon: Icons.straighten_outlined,
                    text: 'Your saved body measurements will appear here.',
                  )
                else
                  ...entries.map(
                    (entry) => _MeasurementTile(
                      entry: entry,
                      date: _date,
                      number: _number,
                      onDelete: () => _deleteMeasurement(entry),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BodyProgressData {
  final List<BodyProgressEntry> entries;
  final List<ProgressPhotoRecord> photos;

  const _BodyProgressData({
    this.entries = const <BodyProgressEntry>[],
    this.photos = const <ProgressPhotoRecord>[],
  });
}

class _TrendCard extends StatelessWidget {
  final BodyMetric metric;
  final List<BodyProgressPoint> points;
  final String Function(double) number;
  final String Function(DateTime) date;

  const _TrendCard({
    required this.metric,
    required this.points,
    required this.number,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final change = BodyProgressEngine.absoluteChange(points);
    return Container(
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Text(
                  '${metric.label} trend',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
              ),
              if (change != null)
                Text(
                  '${change >= 0 ? '+' : ''}${number(change)} ${metric.unit}',
                  style: const TextStyle(
                    color: Color(0xFF176B87),
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            points.length < 2
                ? 'Add another ${metric.label.toLowerCase()} measurement to see change over time.'
                : '${points.length} logged days • ${date(points.first.date)} to ${date(points.last.date)}',
            style: const TextStyle(color: Color(0xFF627D98), fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: CustomPaint(painter: _BodyTrendPainter(points)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${number(points.first.value)} ${metric.unit}',
                style: const TextStyle(color: Color(0xFF627D98), fontSize: 12),
              ),
              Text(
                '${number(points.last.value)} ${metric.unit}',
                style: const TextStyle(
                  color: Color(0xFF176B87),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyTrendPainter extends CustomPainter {
  final List<BodyProgressPoint> points;
  const _BodyTrendPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const padding = 18.0;
    final chartWidth = math.max(1.0, size.width - padding * 2);
    final chartHeight = math.max(1.0, size.height - padding * 2);
    final values = points.map((point) => point.value).toList(growable: false);
    var minValue = values.reduce(math.min);
    var maxValue = values.reduce(math.max);
    if (minValue == maxValue) {
      minValue -= 1;
      maxValue += 1;
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE6ECF2)
      ..strokeWidth = 1;
    for (var row = 0; row <= 4; row++) {
      final y = padding + (chartHeight * row / 4);
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    Offset position(int index) {
      final x = points.length == 1
          ? size.width / 2
          : padding + (chartWidth * index / (points.length - 1));
      final ratio = (points[index].value - minValue) / (maxValue - minValue);
      final y = padding + chartHeight * (1 - ratio);
      return Offset(x, y);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF176B87)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dotPaint = Paint()
      ..color = const Color(0xFF176B87)
      ..style = PaintingStyle.fill;

    if (points.length == 1) {
      canvas.drawCircle(position(0), 5, dotPaint);
      return;
    }

    final path = Path()..moveTo(position(0).dx, position(0).dy);
    for (var index = 1; index < points.length; index++) {
      final point = position(index);
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, linePaint);
    for (var index = 0; index < points.length; index++) {
      canvas.drawCircle(position(index), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BodyTrendPainter oldDelegate) =>
      oldDelegate.points != points;
}

class _MeasurementTile extends StatelessWidget {
  final BodyProgressEntry entry;
  final String Function(DateTime) date;
  final String Function(double) number;
  final VoidCallback onDelete;

  const _MeasurementTile({
    required this.entry,
    required this.date,
    required this.number,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final values = <String>[];
    for (final metric in BodyMetric.values) {
      final value = entry.valueFor(metric);
      if (value != null) values.add('${metric.label} ${number(value)} ${metric.unit}');
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE5F4F8),
            child: Icon(Icons.straighten_outlined, color: Color(0xFF176B87)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date(entry.recordedAt),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  values.join(' • '),
                  style: const TextStyle(color: Color(0xFF486581), height: 1.35),
                ),
                if (entry.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    entry.notes,
                    style: const TextStyle(
                      color: Color(0xFF829AB1),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete measurement',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final ProgressPhotoRecord photo;
  final String Function(DateTime) date;
  final VoidCallback onDelete;

  const _PhotoCard({
    required this.photo,
    required this.date,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: FutureBuilder<Uint8List?>(
              future: loadProgressPhotoBytes(photo.localPath),
              builder: (context, snapshot) {
                final bytes = snapshot.data;
                if (bytes == null || bytes.isEmpty) {
                  return const ColoredBox(
                    color: Color(0xFFF0F4F8),
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF829AB1),
                      ),
                    ),
                  );
                }
                return Image.memory(bytes, fit: BoxFit.cover);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.angle.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF102A43),
                        ),
                      ),
                      Text(
                        date(photo.recordedAt),
                        style: const TextStyle(
                          color: Color(0xFF627D98),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete photo',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _EmptyCard({
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF627D98), height: 1.4),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF176B87)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF486581), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
