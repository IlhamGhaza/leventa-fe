import '../../core/utils/json.dart';
import '../properties/data/property_models.dart';

/// Ownership document rules (D-029), mirroring the backend.
class DocumentRules {
  const DocumentRules._();

  static const _allowed = {
    PropertyType.house: ['shm', 'hgb', 'imb', 'pbb', 'girik', 'other'],
    PropertyType.apartment: ['shmsrs', 'hgb', 'imb', 'pbb', 'slf', 'other'],
    PropertyType.shopHouse: ['shm', 'hgb', 'imb', 'pbb', 'slf', 'other'],
    PropertyType.factory: ['shm', 'hgb', 'hgu', 'imb', 'pbb', 'slf', 'other'],
  };

  static const allowedMimeTypes = [
    'application/pdf',
    'image/jpeg',
    'image/png',
  ];
  static const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
  static const defaultMaxBytes = 5 * 1024 * 1024;

  static List<String> typesFor(String propertyType) =>
      _allowed[propertyType] ?? const [];

  static bool applies(String propertyType, String docType) =>
      typesFor(propertyType).contains(docType);

  /// Upload is possible only for an applicable type whose cert flag is on.
  static bool canUpload(PublicProperty p, String docType) =>
      applies(p.type, docType) && p.details.cert(docType);

  static String label(String docType) => switch (docType) {
    'shm' => 'SHM',
    'hgb' => 'HGB',
    'hgu' => 'HGU',
    'shmsrs' => 'SHMSRS',
    'imb' => 'IMB / PBG',
    'pbb' => 'PBB',
    'girik' => 'Girik',
    'slf' => 'SLF',
    'other' => 'Lainnya',
    _ => docType.toUpperCase(),
  };
}

class OwnershipDocument {
  const OwnershipDocument({
    required this.id,
    required this.docType,
    required this.originalName,
    required this.mimeType,
    required this.sizeBytes,
    this.createdAt,
  });
  final String id;
  final String docType;
  final String originalName;
  final String mimeType;
  final int sizeBytes;
  final DateTime? createdAt;

  factory OwnershipDocument.fromJson(Map<String, dynamic> j) =>
      OwnershipDocument(
        id: strOr(j['id']),
        docType: strOr(j['doc_type']),
        originalName: strOr(j['original_name']),
        mimeType: strOr(j['mime_type']),
        sizeBytes: intOr(j['size_bytes']),
        createdAt: date(j['created_at']),
      );
}
