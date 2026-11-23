import '../../../../core/database/app_database.dart';
import '../../domain/entities/document_source.dart';
import '../../domain/entities/warranty_document.dart';

abstract final class DocumentMapper {
  static WarrantyDocument toEntity(
    ProductDocumentRow row, {
    required String filePath,
  }) {
    return WarrantyDocument(
      id: row.id,
      productId: row.productId,
      fileName: row.fileName,
      filePath: filePath,
      mimeType: row.mimeType,
      sizeBytes: row.sizeBytes,
      source: _sourceFromName(row.source),
      createdAt: row.createdAt,
    );
  }

  static ProductDocumentsCompanion toInsertCompanion({
    required int productId,
    required WarrantyDocument document,
    required String storagePath,
    required DateTime createdAt,
  }) {
    return ProductDocumentsCompanion.insert(
      productId: productId,
      fileName: document.fileName,
      storagePath: storagePath,
      mimeType: document.mimeType,
      sizeBytes: document.sizeBytes,
      source: document.source.name,
      createdAt: createdAt,
    );
  }

  static DocumentSource _sourceFromName(String name) {
    return DocumentSource.values.firstWhere(
      (source) => source.name == name,
      orElse: () => DocumentSource.file,
    );
  }
}
