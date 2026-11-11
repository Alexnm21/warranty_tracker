import 'dart:developer';
import 'dart:io';

import '../../domain/entities/warranty_document.dart';
import '../../domain/repositories/document_repository.dart';
import '../daos/document_dao.dart';
import '../mappers/document_mapper.dart';
import '../services/document_file_storage.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  DocumentRepositoryImpl(this._dao, this._storage);

  final DocumentDao _dao;
  final DocumentFileStorage _storage;

  @override
  Future<List<WarrantyDocument>> getByProduct(int productId) async {
    final rows = await _dao.getByProduct(productId);

    return Future.wait(
      rows.map((row) async {
        final filePath = await _storage.absolutePath(row.storagePath);
        return DocumentMapper.toEntity(row, filePath: filePath);
      }),
    );
  }

  @override
  Future<WarrantyDocument> add(int productId, WarrantyDocument document) async {
    final stagedFile = File(document.filePath);
    if (!await stagedFile.exists()) {
      throw FileSystemException(
        'The staged document does not exist',
        document.filePath,
      );
    }

    final createdAt = DateTime.now();
    final storagePath = await _storage.persist(
      productId,
      stagedFile,
      fileName: document.fileName,
    );

    try {
      final id = await _dao.insertDocument(
        DocumentMapper.toInsertCompanion(
          productId: productId,
          document: document,
          storagePath: storagePath,
          createdAt: createdAt,
        ),
      );

      return document.copyWith(
        id: id,
        productId: productId,
        filePath: await _storage.absolutePath(storagePath),
        createdAt: createdAt,
      );
    } catch (_) {
      // Do not leave an unreferenced file behind if the metadata cannot be
      // persisted.
      await _storage.deleteFile(await _storage.absolutePath(storagePath));
      rethrow;
    }
  }

  @override
  Future<void> delete(WarrantyDocument document) async {
    final id = document.id;
    if (id == null) {
      throw ArgumentError.value(
        document,
        'document',
        'A document must be persisted before it can be deleted',
      );
    }

    await _dao.deleteById(id);

    try {
      await _storage.deleteFile(document.filePath);
    } on Exception catch (error) {
      // The metadata is already gone, so the document is deleted from the
      // user's point of view. A failed file removal only leaves an orphan
      // file behind, which must not surface as a failed deletion.
      log(
        'Could not delete the file of document $id',
        name: 'DocumentRepositoryImpl',
        error: error,
      );
    }
  }

  @override
  Future<void> deleteStoredFilesForProduct(int productId) {
    return _storage.deleteProductDirectory(productId);
  }
}
