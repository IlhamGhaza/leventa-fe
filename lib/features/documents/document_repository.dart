import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/network/api_client.dart';
import 'document_rules.dart';

/// Ownership documents (D-029). Never cached; downloads go to an app-private
/// folder (not the cache or shared storage) and are deleted after use.
class DocumentRepository {
  DocumentRepository(this._api, {Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? getApplicationSupportDirectory;

  final ApiClient _api;
  final Future<Directory> Function() _baseDir;

  Future<List<OwnershipDocument>> list(String propertyId) async {
    final res = await _api.get('/properties/$propertyId/documents');
    return res.dataList.map(OwnershipDocument.fromJson).toList();
  }

  /// Primary only. Re-uploading the same type replaces the document.
  Future<void> upload(
    String propertyId, {
    required String docType,
    required String filePath,
    required String fileName,
  }) async {
    final form = FormData.fromMap({
      'doc_type': docType,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    await _api.upload('/properties/$propertyId/documents', form);
  }

  Future<void> delete(String propertyId, String docId) =>
      _api.delete('/properties/$propertyId/documents/$docId');

  /// Downloads with the bearer header into a private temp file.
  /// The caller must call [discard] after viewing/sharing.
  Future<File> download(String propertyId, OwnershipDocument doc) async {
    final bytes = await _api.download(
      '/properties/$propertyId/documents/${doc.id}/download',
    );
    final dir = await _privateDir();
    final sub = Directory('${dir.path}${Platform.pathSeparator}${_randomId()}');
    await sub.create(recursive: true);
    final file = File('${sub.path}${Platform.pathSeparator}${_safeName(doc)}');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> discard(File file) async {
    try {
      final parent = file.parent;
      if (await parent.exists()) await parent.delete(recursive: true);
    } catch (_) {}
  }

  /// Logout / account switch / role change: delete every downloaded document.
  Future<void> purgeAll() async {
    try {
      final dir = await _privateDir();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  Future<Directory> _privateDir() async {
    final base = await _baseDir();
    return Directory('${base.path}${Platform.pathSeparator}private_docs');
  }

  static String _randomId() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(16).toRadixString(16)).join();
  }

  static String _safeName(OwnershipDocument doc) {
    final cleaned = doc.originalName.replaceAll(RegExp(r'[^\w.\- ]'), '_');
    if (cleaned.trim().isNotEmpty) return cleaned;
    final ext = switch (doc.mimeType) {
      'application/pdf' => 'pdf',
      'image/png' => 'png',
      _ => 'jpg',
    };
    return '${DocumentRules.label(doc.docType)}.$ext';
  }
}
