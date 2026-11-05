import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_filex/open_filex.dart';
import 'package:warranty_tracker/features/documents/data/services/document_opener.dart';
import 'package:warranty_tracker/features/documents/domain/entities/document_exception.dart';

void main() {
  test('open completes when the platform reports success', () async {
    final opener = DocumentOpener(openFile: (_) async => OpenResult());

    await expectLater(opener.open('/tmp/document.pdf'), completes);
  });

  const failures = <ResultType, DocumentOpenFailure>{
    ResultType.fileNotFound: DocumentOpenFailure.fileNotFound,
    ResultType.noAppToOpen: DocumentOpenFailure.noAppAvailable,
    ResultType.permissionDenied: DocumentOpenFailure.permissionDenied,
    ResultType.error: DocumentOpenFailure.failed,
  };

  for (final entry in failures.entries) {
    test('maps ${entry.key.name} to ${entry.value.name}', () async {
      final opener = DocumentOpener(
        openFile: (_) async => OpenResult(type: entry.key, message: 'failure'),
      );

      await expectLater(
        opener.open('/tmp/document.pdf'),
        throwsA(_openFailure(entry.value)),
      );
    });
  }

  test('maps platform exceptions', () async {
    final opener = DocumentOpener(
      openFile: (_) async => throw PlatformException(code: 'error'),
    );

    await expectLater(
      opener.open('/tmp/document.pdf'),
      throwsA(_openFailure(DocumentOpenFailure.failed)),
    );
  });
}

Matcher _openFailure(DocumentOpenFailure failure) {
  return isA<DocumentOpenException>().having(
    (error) => error.failure,
    'failure',
    failure,
  );
}
