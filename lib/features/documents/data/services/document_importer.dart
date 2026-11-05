import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_selector/file_selector.dart'
    show XFile, XTypeGroup, openFiles;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart' show ImagePicker, ImageSource;

import '../../domain/entities/document_exception.dart';
import '../../domain/entities/document_source.dart';
import '../../domain/entities/warranty_document.dart';
import 'document_file_storage.dart';

typedef DocumentScannerCallback = Future<List<String>?> Function();
typedef CameraCallback = Future<XFile?> Function();
typedef FileSelectionCallback = Future<List<XFile>> Function();

/// Imports warranty documents from the camera, the native scanner or the file
/// picker and stages them until the product is saved.
class DocumentImporter {
  DocumentImporter({
    required DocumentFileStorage storage,
    DocumentScannerCallback? scanner,
    CameraCallback? camera,
    FileSelectionCallback? fileSelector,
  }) : _storage = storage,
       _scanner = scanner ?? _scanWithPlugin,
       _camera = camera ?? _takePhotoWithPlugin,
       _fileSelector = fileSelector ?? _selectFilesWithPlugin;

  /// Maximum size of a single document.
  static const int maxFileSizeBytes = 25 * 1024 * 1024;

  static const Map<String, String> _mimeTypes = {
    'pdf': 'application/pdf',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'heic': 'image/heic',
    'webp': 'image/webp',
  };

  static const XTypeGroup _supportedTypeGroup = XTypeGroup(
    label: 'warranty_documents',
    extensions: ['pdf', 'jpg', 'jpeg', 'png', 'heic', 'webp'],
    mimeTypes: [
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/heic',
      'image/webp',
    ],
    uniformTypeIdentifiers: ['com.adobe.pdf', 'public.image'],
  );

  final DocumentFileStorage _storage;
  final DocumentScannerCallback _scanner;
  final CameraCallback _camera;
  final FileSelectionCallback _fileSelector;

  /// Scans one or more pages and compiles them into a PDF when possible.
  Future<List<WarrantyDocument>> scanDocuments() async {
    final paths = await _runScanner();
    if (paths == null || paths.isEmpty) {
      return const [];
    }

    final validated = <_ValidatedFile>[];
    for (final path in paths) {
      validated.add(await _validate(path, null));
    }

    return _stageAll(validated, DocumentSource.scan);
  }

  /// Takes a single photo with the camera.
  Future<WarrantyDocument?> takePhoto() async {
    final file = await _runCamera();
    if (file == null) {
      return null;
    }

    final validated = await _validate(file.path, file.name);
    return _stage(validated, DocumentSource.photo);
  }

  /// Lets the user choose one or more documents from the device.
  Future<List<WarrantyDocument>> pickFiles() async {
    final files = await _runFileSelector();
    if (files.isEmpty) {
      return const [];
    }

    final validated = <_ValidatedFile>[];
    for (final file in files) {
      validated.add(await _validate(file.path, file.name));
    }

    return _stageAll(validated, DocumentSource.file);
  }

  /// Deletes a staged document that will not be saved.
  Future<void> discard(WarrantyDocument document) async {
    if (document.isPersisted) {
      throw ArgumentError.value(
        document,
        'document',
        'Only staged documents can be discarded',
      );
    }

    await _storage.deleteFile(document.filePath);
  }

  Future<List<String>?> _runScanner() async {
    try {
      return await _scanner();
    } on CunningDocumentScannerException catch (error) {
      throw DocumentImportException(
        error.code == 'permission_denied'
            ? DocumentImportFailure.permissionDenied
            : DocumentImportFailure.failed,
        cause: error,
      );
    } on PlatformException catch (error) {
      throw DocumentImportException(_failureFromPlatform(error), cause: error);
    } on Exception catch (error) {
      throw DocumentImportException(DocumentImportFailure.failed, cause: error);
    }
  }

  Future<XFile?> _runCamera() async {
    try {
      return await _camera();
    } on PlatformException catch (error) {
      throw DocumentImportException(_failureFromPlatform(error), cause: error);
    } on Exception catch (error) {
      throw DocumentImportException(DocumentImportFailure.failed, cause: error);
    }
  }

  Future<List<XFile>> _runFileSelector() async {
    try {
      return await _fileSelector();
    } on PlatformException catch (error) {
      throw DocumentImportException(_failureFromPlatform(error), cause: error);
    } on Exception catch (error) {
      throw DocumentImportException(DocumentImportFailure.failed, cause: error);
    }
  }

  Future<_ValidatedFile> _validate(String path, String? providedName) async {
    final fileName = _resolveName(path, providedName);
    final mimeType = _mimeTypeFor(fileName);

    final int sizeBytes;
    try {
      sizeBytes = await File(path).length();
    } on FileSystemException catch (error) {
      throw DocumentImportException(
        DocumentImportFailure.failed,
        fileName: fileName,
        cause: error,
      );
    }

    if (sizeBytes <= 0) {
      throw DocumentImportException(
        DocumentImportFailure.emptyFile,
        fileName: fileName,
      );
    }
    if (sizeBytes > maxFileSizeBytes) {
      throw DocumentImportException(
        DocumentImportFailure.fileTooLarge,
        fileName: fileName,
      );
    }

    return _ValidatedFile(
      path: path,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
    );
  }

  Future<List<WarrantyDocument>> _stageAll(
    List<_ValidatedFile> files,
    DocumentSource source,
  ) {
    return Future.wait(files.map((file) => _stage(file, source)));
  }

  Future<WarrantyDocument> _stage(
    _ValidatedFile file,
    DocumentSource source,
  ) async {
    try {
      final staged = await _storage.stage(
        File(file.path),
        fileName: file.fileName,
      );

      return WarrantyDocument(
        fileName: file.fileName,
        filePath: staged.path,
        mimeType: file.mimeType,
        sizeBytes: file.sizeBytes,
        source: source,
      );
    } on FileSystemException catch (error) {
      throw DocumentImportException(
        DocumentImportFailure.failed,
        fileName: file.fileName,
        cause: error,
      );
    }
  }

  String _resolveName(String path, String? providedName) {
    final name = providedName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final baseName = path.split(RegExp(r'[/\\]')).last;
    return baseName.isEmpty ? 'document' : baseName;
  }

  String _mimeTypeFor(String fileName) {
    final extension = _extensionOf(fileName);
    final mimeType = extension == null ? null : _mimeTypes[extension];

    if (mimeType == null) {
      throw DocumentImportException(
        DocumentImportFailure.unsupportedType,
        fileName: fileName,
      );
    }

    return mimeType;
  }

  String? _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) {
      return null;
    }
    return fileName.substring(dot + 1).toLowerCase();
  }

  DocumentImportFailure _failureFromPlatform(PlatformException error) {
    final code = error.code.toLowerCase();
    if (code.contains('permission') ||
        code.contains('access_denied') ||
        code.contains('access-denied')) {
      return DocumentImportFailure.permissionDenied;
    }
    return DocumentImportFailure.failed;
  }

  static Future<List<String>?> _scanWithPlugin() {
    return CunningDocumentScanner.getPictures(asPdf: true);
  }

  static Future<XFile?> _takePhotoWithPlugin() {
    return ImagePicker().pickImage(
      source: ImageSource.camera,
      requestFullMetadata: false,
    );
  }

  static Future<List<XFile>> _selectFilesWithPlugin() {
    return openFiles(acceptedTypeGroups: const [_supportedTypeGroup]);
  }
}

class _ValidatedFile {
  const _ValidatedFile({
    required this.path,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String path;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
}
