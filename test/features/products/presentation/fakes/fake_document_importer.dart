import 'package:warranty_tracker/features/documents/data/services/document_importer.dart';
import 'package:warranty_tracker/features/documents/domain/entities/document_exception.dart';
import 'package:warranty_tracker/features/documents/domain/entities/warranty_document.dart';

/// Configurable [DocumentImporter] test double.
class FakeDocumentImporter implements DocumentImporter {
  List<WarrantyDocument> scannedDocuments = const [];
  List<WarrantyDocument> pickedDocuments = const [];
  WarrantyDocument? photo;

  bool throwOnScan = false;
  bool throwOnPhoto = false;
  bool throwOnPickFiles = false;
  bool throwOnDiscard = false;

  DocumentImportException importError = const DocumentImportException(
    DocumentImportFailure.failed,
  );

  final List<WarrantyDocument> discardedDocuments = [];

  int scanCalls = 0;
  int photoCalls = 0;
  int pickFilesCalls = 0;

  @override
  Future<List<WarrantyDocument>> scanDocuments() async {
    scanCalls++;
    if (throwOnScan) {
      throw importError;
    }
    return List.of(scannedDocuments);
  }

  @override
  Future<WarrantyDocument?> takePhoto() async {
    photoCalls++;
    if (throwOnPhoto) {
      throw importError;
    }
    return photo;
  }

  @override
  Future<List<WarrantyDocument>> pickFiles() async {
    pickFilesCalls++;
    if (throwOnPickFiles) {
      throw importError;
    }
    return List.of(pickedDocuments);
  }

  @override
  Future<void> discard(WarrantyDocument document) async {
    if (throwOnDiscard) {
      throw Exception('FakeDocumentImporter discard failure');
    }
    discardedDocuments.add(document);
  }
}
