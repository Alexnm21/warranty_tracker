import '../../../documents/domain/entities/document_exception.dart';

/// Maps a document open failure to its localization key.
String documentOpenErrorKey(DocumentOpenFailure failure) {
  return switch (failure) {
    DocumentOpenFailure.fileNotFound =>
      'products.form.documents.error.fileNotFound',
    DocumentOpenFailure.noAppAvailable => 'products.form.documents.error.noApp',
    DocumentOpenFailure.permissionDenied =>
      'products.form.documents.error.permissionDenied',
    DocumentOpenFailure.failed => 'products.form.documents.error.open',
  };
}
