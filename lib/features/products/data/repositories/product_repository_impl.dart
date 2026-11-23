import 'dart:developer';

import '../../../documents/domain/repositories/document_repository.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../daos/product_dao.dart';
import '../mappers/product_mapper.dart';

typedef ReminderSyncCallback = Future<void> Function();

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(
    this._dao,
    this._documents, {
    ReminderSyncCallback? reminderSync,
  }) : _reminderSync = reminderSync;

  final ProductDao _dao;
  final DocumentRepository _documents;
  final ReminderSyncCallback? _reminderSync;

  @override
  Future<List<Product>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(ProductMapper.toEntity).toList();
  }

  @override
  Future<Product?> getById(int id) async {
    final row = await _dao.getById(id);
    return row == null ? null : ProductMapper.toEntity(row);
  }

  @override
  Future<Product> create(Product product) async {
    final now = DateTime.now();
    final prepared = product.copyWith(
      createdAt: product.createdAt ?? now,
      updatedAt: product.updatedAt ?? now,
    );

    final id = await _dao.insertProduct(
      ProductMapper.toInsertCompanion(prepared),
    );
    await _syncReminders();
    return prepared.copyWith(id: id);
  }

  @override
  Future<Product> update(Product product) async {
    final updated = product.copyWith(updatedAt: DateTime.now());
    await _dao.updateProduct(ProductMapper.toRow(updated));
    await _syncReminders();
    return updated;
  }

  @override
  Future<void> delete(int id) async {
    await _dao.deleteById(id);

    try {
      await _documents.deleteStoredFilesForProduct(id);
    } on Exception catch (error) {
      // The product row is already gone, so a failed cleanup must not turn a
      // completed deletion into a user-visible error. The orphaned folder can
      // be cleaned up later.
      log(
        'Could not delete the stored documents of product $id',
        name: 'ProductRepositoryImpl',
        error: error,
      );
    }
    await _syncReminders();
  }

  Future<void> _syncReminders() async {
    if (_reminderSync == null) {
      return;
    }
    try {
      await _reminderSync();
    } on Exception catch (error) {
      // The product mutation is already committed; notification failures must
      // not turn it into a user-visible error.
      log(
        'Could not reschedule warranty reminders',
        name: 'ProductRepositoryImpl',
        error: error,
      );
    }
  }

  @override
  Future<List<Product>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return getAll();
    }

    final rows = await _dao.search(trimmed);
    return rows.map(ProductMapper.toEntity).toList();
  }
}
