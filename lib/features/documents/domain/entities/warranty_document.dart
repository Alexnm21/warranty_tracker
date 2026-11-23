import 'document_source.dart';

/// A document associated with a product's warranty.
///
/// [id] and [productId] are `null` while the document is staged in the form and
/// has not been persisted yet. [filePath] is an absolute path during runtime;
/// only the relative path is stored in the database.
class WarrantyDocument {
  const WarrantyDocument({
    this.id,
    this.productId,
    required this.fileName,
    required this.filePath,
    required this.mimeType,
    required this.sizeBytes,
    required this.source,
    this.createdAt,
  });

  final int? id;
  final int? productId;
  final String fileName;
  final String filePath;
  final String mimeType;
  final int sizeBytes;
  final DocumentSource source;
  final DateTime? createdAt;

  bool get isPersisted => id != null;

  bool get isImage => mimeType.startsWith('image/');

  WarrantyDocument copyWith({
    int? id,
    int? productId,
    String? fileName,
    String? filePath,
    String? mimeType,
    int? sizeBytes,
    DocumentSource? source,
    DateTime? createdAt,
  }) {
    return WarrantyDocument(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
