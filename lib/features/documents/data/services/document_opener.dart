import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import '../../domain/entities/document_exception.dart';

typedef DocumentOpenCallback = Future<OpenResult> Function(String filePath);

/// Opens warranty documents with the system file viewer.
class DocumentOpener {
  DocumentOpener({DocumentOpenCallback? openFile})
    : _openFile = openFile ?? _openWithPlugin;

  final DocumentOpenCallback _openFile;

  Future<void> open(String filePath) async {
    final OpenResult result;
    try {
      result = await _openFile(filePath);
    } on PlatformException catch (error) {
      throw DocumentOpenException(
        DocumentOpenFailure.failed,
        filePath: filePath,
        cause: error,
      );
    } on Exception catch (error) {
      throw DocumentOpenException(
        DocumentOpenFailure.failed,
        filePath: filePath,
        cause: error,
      );
    }

    final failure = _failureFor(result.type);
    if (failure != null) {
      throw DocumentOpenException(failure, filePath: filePath);
    }
  }

  static DocumentOpenFailure? _failureFor(ResultType type) {
    return switch (type) {
      ResultType.done => null,
      ResultType.fileNotFound => DocumentOpenFailure.fileNotFound,
      ResultType.noAppToOpen => DocumentOpenFailure.noAppAvailable,
      ResultType.permissionDenied => DocumentOpenFailure.permissionDenied,
      ResultType.error => DocumentOpenFailure.failed,
    };
  }

  static Future<OpenResult> _openWithPlugin(String filePath) {
    return OpenFilex.open(filePath);
  }
}
