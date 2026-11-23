import 'package:warranty_tracker/features/documents/domain/entities/warranty_document.dart';
import 'package:warranty_tracker/features/documents/domain/repositories/document_repository.dart';

/// In-memory [DocumentRepository] for tests.
///
/// Set any `throwOn*` flag to make that operation fail.
class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository([List<WarrantyDocument>? initial])
    : _documents = [...?initial] {
    for (final document in _documents) {
      final id = document.id;
      if (id != null && id >= _nextId) {
        _nextId = id + 1;
      }
    }
  }

  final List<WarrantyDocument> _documents;
  int _nextId = 1;

  bool throwOnGetByProduct = false;
  bool throwOnAdd = false;
  bool throwOnDelete = false;
  bool throwOnDeleteStoredFiles = false;

  List<WarrantyDocument> get documents => List.unmodifiable(_documents);

  final List<int> deletedStoredFilesForProducts = [];

  @override
  Future<List<WarrantyDocument>> getByProduct(int productId) async {
    _maybeThrow(throwOnGetByProduct);
    return _documents
        .where((document) => document.productId == productId)
        .toList();
  }

  @override
  Future<WarrantyDocument> add(int productId, WarrantyDocument document) async {
    _maybeThrow(throwOnAdd);

    final persisted = document.copyWith(
      id: _nextId++,
      productId: productId,
      filePath: '/persisted/$productId/${document.fileName}',
      createdAt: DateTime(2026),
    );
    _documents.add(persisted);
    return persisted;
  }

  @override
  Future<void> delete(WarrantyDocument document) async {
    _maybeThrow(throwOnDelete);
    _documents.removeWhere((item) => item.id == document.id);
  }

  @override
  Future<void> deleteStoredFilesForProduct(int productId) async {
    _maybeThrow(throwOnDeleteStoredFiles);
    deletedStoredFilesForProducts.add(productId);
  }

  void _maybeThrow(bool shouldThrow) {
    if (shouldThrow) {
      throw Exception('FakeDocumentRepository failure');
    }
  }
}
