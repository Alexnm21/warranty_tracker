import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/core/database/app_database.dart';
import 'package:warranty_tracker/features/documents/data/mappers/document_mapper.dart';
import 'package:warranty_tracker/features/documents/domain/entities/document_source.dart';
import 'package:warranty_tracker/features/documents/domain/entities/warranty_document.dart';

void main() {
  test('toEntity maps every column and resolves the file path', () {
    final row = ProductDocumentRow(
      id: 7,
      productId: 3,
      fileName: 'receipt.pdf',
      storagePath: 'warranty_documents/3/stored_receipt.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 2048,
      source: 'scan',
      createdAt: DateTime(2025, 1, 1),
    );

    final entity = DocumentMapper.toEntity(
      row,
      filePath: '/app/documents/warranty_documents/3/stored_receipt.pdf',
    );

    expect(entity.id, 7);
    expect(entity.productId, 3);
    expect(entity.fileName, 'receipt.pdf');
    expect(
      entity.filePath,
      '/app/documents/warranty_documents/3/stored_receipt.pdf',
    );
    expect(entity.mimeType, 'application/pdf');
    expect(entity.sizeBytes, 2048);
    expect(entity.source, DocumentSource.scan);
    expect(entity.createdAt, DateTime(2025, 1, 1));
  });

  test('toEntity falls back to file for unknown sources', () {
    final row = ProductDocumentRow(
      id: 1,
      productId: 1,
      fileName: 'document.pdf',
      storagePath: 'warranty_documents/1/document.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 1,
      source: 'unknown',
      createdAt: DateTime(2025, 1, 1),
    );

    expect(
      DocumentMapper.toEntity(row, filePath: '/tmp/document.pdf').source,
      DocumentSource.file,
    );
  });

  test('toInsertCompanion maps the entity and storage path', () {
    final document = WarrantyDocument(
      fileName: 'photo.jpg',
      filePath: '/tmp/photo.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 512,
      source: DocumentSource.photo,
    );
    final createdAt = DateTime(2025, 2, 1);

    final companion = DocumentMapper.toInsertCompanion(
      productId: 4,
      document: document,
      storagePath: 'warranty_documents/4/stored_photo.jpg',
      createdAt: createdAt,
    );

    expect(companion.productId.value, 4);
    expect(companion.fileName.value, 'photo.jpg');
    expect(
      companion.storagePath.value,
      'warranty_documents/4/stored_photo.jpg',
    );
    expect(companion.mimeType.value, 'image/jpeg');
    expect(companion.sizeBytes.value, 512);
    expect(companion.source.value, 'photo');
    expect(companion.createdAt.value, createdAt);
  });
}
