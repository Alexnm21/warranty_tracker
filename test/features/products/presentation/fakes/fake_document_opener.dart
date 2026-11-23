import 'package:warranty_tracker/features/documents/data/services/document_opener.dart';
import 'package:warranty_tracker/features/documents/domain/entities/document_exception.dart';

/// Configurable [DocumentOpener] test double.
class FakeDocumentOpener implements DocumentOpener {
  final List<String> openedPaths = [];
  DocumentOpenException? openError;

  @override
  Future<void> open(String filePath) async {
    openedPaths.add(filePath);
    final error = openError;
    if (error != null) {
      throw error;
    }
  }
}
