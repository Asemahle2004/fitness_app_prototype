import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

bool get progressPhotoPersistenceSupported => false;

Future<String?> persistProgressPhoto(XFile source, String id) async => null;

Future<Uint8List?> loadProgressPhotoBytes(String path) async => null;

Future<void> deleteProgressPhotoFile(String path) async {}
