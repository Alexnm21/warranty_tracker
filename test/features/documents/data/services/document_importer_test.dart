import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_selector/file_selector.dart' show XFile;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/features/documents/data/services/document_file_storage.dart';
import 'package:warranty_tracker/features/documents/data/services/document_importer.dart';
import 'package:warranty_tracker/features/documents/domain/entities/document_exception.dart';
import 'package:warranty_tracker/features/documents/domain/entities/document_source.dart';
import 'package:warranty_tracker/features/documents/domain/entities/warranty_document.dart';

void main() {
  late Directory tempDirectory;
  late DocumentFileStorage storage;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('document_importer');
    storage = DocumentFileStorage(baseDirectory: tempDirectory);
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('scanDocuments stages the scanned PDF', () async {
    final source = await _writeFile(tempDirectory, 'scan.pdf', 'pdf');
    final importer = DocumentImporter(
      storage: storage,
      scanner: () async => [source.path],
    );

    final documents = await importer.scanDocuments();

    expect(documents, hasLength(1));
    final document = documents.single;
    expect(document.fileName, 'scan.pdf');
    expect(document.mimeType, 'application/pdf');
    expect(document.sizeBytes, 3);
    expect(document.source, DocumentSource.scan);
    expect(document.id, isNull);
    expect(document.productId, isNull);
    expect(document.filePath, isNot(source.path));
    expect(await File(document.filePath).readAsString(), 'pdf');
  });

  test('scanDocuments returns an empty list when the user cancels', () async {
    final importer = DocumentImporter(
      storage: storage,
      scanner: () async => null,
    );

    expect(await importer.scanDocuments(), isEmpty);
  });

  test('scanDocuments maps a denied permission', () async {
    final importer = DocumentImporter(
      storage: storage,
      scanner: () async =>
          throw const CunningDocumentScannerException.permissionDenied(),
    );

    await expectLater(
      importer.scanDocuments(),
      throwsA(_importFailure(DocumentImportFailure.permissionDenied)),
    );
  });

  test('scanDocuments maps other scanner errors', () async {
    final importer = DocumentImporter(
      storage: storage,
      scanner: () async =>
          throw const CunningDocumentScannerException('scan failed'),
    );

    await expectLater(
      importer.scanDocuments(),
      throwsA(_importFailure(DocumentImportFailure.failed)),
    );
  });

  test('scanDocuments rejects unsupported types before staging', () async {
    final source = await _writeFile(tempDirectory, 'scan.txt', 'text');
    final importer = DocumentImporter(
      storage: storage,
      scanner: () async => [source.path],
    );

    await expectLater(
      importer.scanDocuments(),
      throwsA(_importFailure(DocumentImportFailure.unsupportedType)),
    );
    expect(await _stagingDirectory(tempDirectory).exists(), isFalse);
  });

  test('takePhoto stages the camera image', () async {
    final source = await _writeFile(tempDirectory, 'photo.jpg', 'image');
    final importer = DocumentImporter(
      storage: storage,
      camera: () async => XFile(source.path),
    );

    final document = await importer.takePhoto();

    expect(document, isNotNull);
    expect(document!.fileName, 'photo.jpg');
    expect(document.mimeType, 'image/jpeg');
    expect(document.source, DocumentSource.photo);
    expect(await File(document.filePath).readAsString(), 'image');
  });

  test('takePhoto returns null when the user cancels', () async {
    final importer = DocumentImporter(
      storage: storage,
      camera: () async => null,
    );

    expect(await importer.takePhoto(), isNull);
  });

  test('takePhoto maps a denied camera permission', () async {
    final importer = DocumentImporter(
      storage: storage,
      camera: () async => throw PlatformException(code: 'camera_access_denied'),
    );

    await expectLater(
      importer.takePhoto(),
      throwsA(_importFailure(DocumentImportFailure.permissionDenied)),
    );
  });

  test('pickFiles stages every selected document', () async {
    final first = await _writeFile(tempDirectory, 'receipt.pdf', 'pdf');
    final second = await _writeFile(tempDirectory, 'invoice.PNG', 'png');
    final importer = DocumentImporter(
      storage: storage,
      fileSelector: () async => [XFile(first.path), XFile(second.path)],
    );

    final documents = await importer.pickFiles();

    expect(documents.map((document) => document.fileName), [
      'receipt.pdf',
      'invoice.PNG',
    ]);
    expect(documents.map((document) => document.mimeType), [
      'application/pdf',
      'image/png',
    ]);
    expect(
      documents.every((document) => document.source == DocumentSource.file),
      isTrue,
    );
  });

  test('pickFiles returns an empty list when the user cancels', () async {
    final importer = DocumentImporter(
      storage: storage,
      fileSelector: () async => const [],
    );

    expect(await importer.pickFiles(), isEmpty);
  });

  test('pickFiles validates every file before staging any', () async {
    final valid = await _writeFile(tempDirectory, 'receipt.pdf', 'pdf');
    final invalid = await _writeFile(tempDirectory, 'notes.txt', 'text');
    final importer = DocumentImporter(
      storage: storage,
      fileSelector: () async => [XFile(valid.path), XFile(invalid.path)],
    );

    await expectLater(
      importer.pickFiles(),
      throwsA(_importFailure(DocumentImportFailure.unsupportedType)),
    );
    expect(await _stagingDirectory(tempDirectory).exists(), isFalse);
  });

  test('pickFiles maps platform errors', () async {
    final importer = DocumentImporter(
      storage: storage,
      fileSelector: () async => throw PlatformException(code: 'unknown'),
    );

    await expectLater(
      importer.pickFiles(),
      throwsA(_importFailure(DocumentImportFailure.failed)),
    );
  });

  test('discard removes a staged document', () async {
    final source = await _writeFile(tempDirectory, 'receipt.pdf', 'pdf');
    final importer = DocumentImporter(
      storage: storage,
      fileSelector: () async => [XFile(source.path)],
    );
    final document = (await importer.pickFiles()).single;

    await importer.discard(document);

    expect(await File(document.filePath).exists(), isFalse);
  });

  test('discard rejects persisted documents', () async {
    final importer = DocumentImporter(storage: storage);
    const document = WarrantyDocument(
      id: 1,
      productId: 1,
      fileName: 'receipt.pdf',
      filePath: '/documents/1/receipt.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 10,
      source: DocumentSource.file,
    );

    await expectLater(importer.discard(document), throwsArgumentError);
  });

  test('rejects empty files', () async {
    final source = await _writeFile(tempDirectory, 'empty.pdf', '');
    final importer = DocumentImporter(
      storage: storage,
      fileSelector: () async => [XFile(source.path)],
    );

    await expectLater(
      importer.pickFiles(),
      throwsA(_importFailure(DocumentImportFailure.emptyFile)),
    );
  });

  test('rejects files larger than the limit', () async {
    final source = await _createSizedFile(
      tempDirectory,
      'large.pdf',
      DocumentImporter.maxFileSizeBytes + 1,
    );
    final importer = DocumentImporter(
      storage: storage,
      fileSelector: () async => [XFile(source.path)],
    );

    await expectLater(
      importer.pickFiles(),
      throwsA(_importFailure(DocumentImportFailure.fileTooLarge)),
    );
  });
}

Matcher _importFailure(DocumentImportFailure failure) {
  return isA<DocumentImportException>().having(
    (error) => error.failure,
    'failure',
    failure,
  );
}

Future<File> _writeFile(
  Directory directory,
  String name,
  String content,
) async {
  final file = File('${directory.path}/$name');
  await file.writeAsString(content);
  return file;
}

Future<File> _createSizedFile(
  Directory directory,
  String name,
  int sizeBytes,
) async {
  final file = File('${directory.path}/$name');
  final randomAccess = await file.open(mode: FileMode.write);
  await randomAccess.truncate(sizeBytes);
  await randomAccess.close();
  return file;
}

Directory _stagingDirectory(Directory baseDirectory) {
  return Directory('${baseDirectory.path}/warranty_documents/.staging');
}
