import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/documents/document_rules.dart';

class PickedFile {
  const PickedFile(this.path, this.name);
  final String path;
  final String name;
}

/// Client-side checks for usability; the backend sniffs and decides.
class PickError implements Exception {
  const PickError(this.message);
  final String message;
}

const _maxBytes = DocumentRules.defaultMaxBytes;

Future<void> _checkSize(String path) async {
  if (await File(path).length() > _maxBytes) {
    throw const PickError('Ukuran file maksimal 5 MB.');
  }
}

/// Listing photo from the gallery (JPEG/PNG/GIF/WebP). Null when cancelled.
Future<PickedFile?> pickListingImage() async {
  final x = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 90,
    maxWidth: 2400,
  );
  if (x == null) return null;
  final ext = x.name.split('.').last.toLowerCase();
  if (!const ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
    throw const PickError('Format foto harus JPEG, PNG, GIF, atau WebP.');
  }
  await _checkSize(x.path);
  return PickedFile(x.path, x.name);
}

/// Ownership document (PDF/JPEG/PNG). Null when cancelled.
Future<PickedFile?> pickOwnershipDocument() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: DocumentRules.allowedExtensions,
  );
  if (files.isEmpty) return null;
  final f = files.first;
  final path = f.path;
  if (path == null) throw const PickError('File tidak dapat dibaca.');
  final ext = (f.extension ?? '').replaceAll('.', '').toLowerCase();
  if (!DocumentRules.allowedExtensions.contains(ext)) {
    throw const PickError('Format dokumen harus PDF, JPEG, atau PNG.');
  }
  await _checkSize(path);
  return PickedFile(path, f.name);
}
