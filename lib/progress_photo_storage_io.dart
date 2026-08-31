import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

bool get progressPhotoPersistenceSupported => true;

String _safeExtension(XFile source) {
  final name = source.name.toLowerCase();
  const allowed = <String>['.jpg', '.jpeg', '.png', '.webp', '.heic'];
  for (final extension in allowed) {
    if (name.endsWith(extension)) return extension;
  }
  return '.jpg';
}

Future<String?> persistProgressPhoto(XFile source, String id) async {
  try {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/leanit_progress_photos');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final destination = File('${directory.path}/$id${_safeExtension(source)}');
    final bytes = await source.readAsBytes();
    await destination.writeAsBytes(bytes, flush: true);
    return destination.path;
  } catch (_) {
    return null;
  }
}

Future<Uint8List?> loadProgressPhotoBytes(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}

Future<void> deleteProgressPhotoFile(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (_) {}
}
