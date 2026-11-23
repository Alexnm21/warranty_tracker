import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Stores warranty document files outside the database.
///
/// Files are copied to a staging folder while the product form is being edited
/// and moved to `<app documents>/warranty_documents/<productId>/` when the
/// product is saved. Only the relative path returned by [persist] is persisted.
class DocumentFileStorage {
  DocumentFileStorage({Directory? baseDirectory})
    : _baseDirectory = baseDirectory;

  /// Overrides the application documents directory. Used by tests.
  final Directory? _baseDirectory;

  static const String _rootFolder = 'warranty_documents';
  static const String _stagingFolder = '.staging';

  int _sequence = 0;

  /// Copies [source] into the staging area and returns the staged file.
  Future<File> stage(File source, {required String fileName}) async {
    final stagingDirectory = Directory(
      _join((await _root()).path, _stagingFolder),
    );
    await stagingDirectory.create(recursive: true);

    final target = File(_join(stagingDirectory.path, _storageName(fileName)));
    return source.copy(target.path);
  }

  /// Moves a staged file to the permanent directory of [productId].
  ///
  /// Returns the path relative to the application documents directory.
  Future<String> persist(
    int productId,
    File stagedFile, {
    required String fileName,
  }) async {
    final directory = Directory(_join((await _root()).path, '$productId'));
    await directory.create(recursive: true);

    final target = File(_join(directory.path, _storageName(fileName)));
    await _move(stagedFile, target);

    return '$_rootFolder/$productId/${_fileName(target.path)}';
  }

  /// Resolves a stored relative path to an absolute path.
  Future<String> absolutePath(String relativePath) async {
    return _join((await _base()).path, relativePath);
  }

  Future<void> deleteFile(String absolutePath) async {
    final file = File(absolutePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Deletes every stored file of a product.
  Future<void> deleteProductDirectory(int productId) async {
    final directory = Directory(_join((await _root()).path, '$productId'));
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<Directory> _base() async {
    return _baseDirectory ?? await getApplicationDocumentsDirectory();
  }

  Future<Directory> _root() async {
    final root = Directory(_join((await _base()).path, _rootFolder));
    await root.create(recursive: true);
    return root;
  }

  Future<void> _move(File source, File target) async {
    try {
      await source.rename(target.path);
    } on FileSystemException {
      // Rename can fail when the source and destination are on different
      // filesystems; fall back to copying and removing the staged file.
      await source.copy(target.path);
      await source.delete();
    }
  }

  String _storageName(String fileName) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return '${timestamp}_${_sequence++}_${_sanitize(fileName)}';
  }

  String _sanitize(String fileName) {
    final baseName = fileName.split(RegExp(r'[/\\]')).last.trim();
    final sanitized = baseName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return sanitized.isEmpty ? 'document' : sanitized;
  }

  String _fileName(String path) => path.split('/').last;

  String _join(String base, String child) {
    final normalized = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    return '$normalized/$child';
  }
}
