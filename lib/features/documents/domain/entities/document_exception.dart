/// Why a warranty document could not be imported.
enum DocumentImportFailure {
  emptyFile,
  unsupportedType,
  fileTooLarge,
  permissionDenied,
  failed,
}

/// A controlled failure raised while importing a warranty document.
///
/// Presentation code maps [failure] to a localized message. [cause] is kept for
/// debugging and must not be shown to the user directly.
class DocumentImportException implements Exception {
  const DocumentImportException(this.failure, {this.fileName, this.cause});

  final DocumentImportFailure failure;
  final String? fileName;
  final Object? cause;

  @override
  String toString() {
    final name = fileName == null ? '' : ', file: $fileName';
    return 'DocumentImportException(${failure.name}$name)';
  }
}

/// Why a warranty document could not be opened.
enum DocumentOpenFailure {
  fileNotFound,
  noAppAvailable,
  permissionDenied,
  failed,
}

/// A controlled failure raised while opening a warranty document.
class DocumentOpenException implements Exception {
  const DocumentOpenException(this.failure, {this.filePath, this.cause});

  final DocumentOpenFailure failure;
  final String? filePath;
  final Object? cause;

  @override
  String toString() {
    final path = filePath == null ? '' : ', path: $filePath';
    return 'DocumentOpenException(${failure.name}$path)';
  }
}
