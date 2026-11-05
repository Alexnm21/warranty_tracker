import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/features/documents/data/services/document_file_storage.dart';

void main() {
  late Directory tempDirectory;
  late DocumentFileStorage storage;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('document_storage');
    storage = DocumentFileStorage(baseDirectory: tempDirectory);
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('stage copies the file without removing the original', () async {
    final source = await _writeFile(tempDirectory, 'source.pdf', 'content');

    final staged = await storage.stage(source, fileName: 'receipt.pdf');

    expect(await source.exists(), isTrue);
    expect(await staged.exists(), isTrue);
    expect(await staged.readAsString(), 'content');
  });

  test('persist moves the staged file and returns a relative path', () async {
    final source = await _writeFile(tempDirectory, 'source.pdf', 'content');
    final staged = await storage.stage(source, fileName: 'receipt.pdf');

    final relativePath = await storage.persist(
      12,
      staged,
      fileName: 'receipt.pdf',
    );

    expect(relativePath, startsWith('warranty_documents/12/'));
    expect(await staged.exists(), isFalse);

    final absolutePath = await storage.absolutePath(relativePath);
    expect(absolutePath, startsWith(tempDirectory.path));
    expect(await File(absolutePath).readAsString(), 'content');
  });

  test('deleteFile removes an existing file', () async {
    final source = await _writeFile(tempDirectory, 'source.pdf', 'content');
    final staged = await storage.stage(source, fileName: 'receipt.pdf');
    final relativePath = await storage.persist(
      12,
      staged,
      fileName: 'receipt.pdf',
    );
    final absolutePath = await storage.absolutePath(relativePath);

    await storage.deleteFile(absolutePath);

    expect(await File(absolutePath).exists(), isFalse);
  });

  test('deleteFile ignores files that no longer exist', () async {
    await storage.deleteFile('${tempDirectory.path}/missing.pdf');
  });

  test('deleteProductDirectory removes every file of the product', () async {
    final source = await _writeFile(tempDirectory, 'source.pdf', 'content');
    final staged = await storage.stage(source, fileName: 'receipt.pdf');
    final relativePath = await storage.persist(
      12,
      staged,
      fileName: 'receipt.pdf',
    );
    final productDirectory = Directory(
      '${tempDirectory.path}/warranty_documents/12',
    );

    expect(await productDirectory.exists(), isTrue);

    await storage.deleteProductDirectory(12);

    expect(await productDirectory.exists(), isFalse);
    expect(
      await File(await storage.absolutePath(relativePath)).exists(),
      isFalse,
    );
  });
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
