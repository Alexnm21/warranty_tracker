import '../entities/warranty_document.dart';

abstract class DocumentRepository {
  Future<List<WarrantyDocument>> getByProduct(int productId);

  /// Persists a staged [document] for [productId], moving its file to the
  /// permanent documents directory.
  Future<WarrantyDocument> add(int productId, WarrantyDocument document);

  Future<void> delete(WarrantyDocument document);

  /// Removes the stored files of a deleted product.
  ///
  /// Metadata is removed by the database foreign key cascade.
  Future<void> deleteStoredFilesForProduct(int productId);
}
