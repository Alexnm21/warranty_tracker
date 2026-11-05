import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/price_format.dart';
import '../../../documents/data/services/document_importer.dart';
import '../../../documents/data/services/document_opener.dart';
import '../../../documents/domain/entities/document_exception.dart';
import '../../../documents/domain/entities/warranty_document.dart';
import '../../../documents/domain/repositories/document_repository.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../utils/document_error_keys.dart';
import 'product_form_state.dart';

/// Raw values entered in the form, before validation or mapping to a [Product].
class ProductFormData {
  const ProductFormData({
    required this.name,
    this.brand,
    this.model,
    this.store,
    this.purchaseDate,
    this.priceText = '',
    this.currency,
    this.serialNumber,
    this.warrantyEndDate,
    this.notes,
  });

  final String name;
  final String? brand;
  final String? model;
  final String? store;
  final DateTime? purchaseDate;
  final String priceText;
  final String? currency;
  final String? serialNumber;
  final DateTime? warrantyEndDate;
  final String? notes;
}

/// Drives the product create/edit form: loads the product and its documents
/// when editing, manages staged documents and validates + persists everything
/// on save.
///
/// Created with the target `productId` (null to create). Business validation
/// lives here so it stays out of the widgets and is unit-testable.
class ProductFormCubit extends Cubit<ProductFormState> {
  ProductFormCubit({
    required ProductRepository repository,
    required DocumentRepository documentRepository,
    required DocumentImporter documentImporter,
    required DocumentOpener documentOpener,
    int? productId,
  }) : _repository = repository,
       _documentRepository = documentRepository,
       _documentImporter = documentImporter,
       _documentOpener = documentOpener,
       _productId = productId,
       super(
         ProductFormState(
           status: productId == null
               ? ProductFormStatus.ready
               : ProductFormStatus.loading,
         ),
       );

  final ProductRepository _repository;
  final DocumentRepository _documentRepository;
  final DocumentImporter _documentImporter;
  final DocumentOpener _documentOpener;

  /// Becomes non-null after the first successful save so retries update the
  /// product instead of creating a duplicate.
  int? _productId;

  Completer<void>? _activeOperation;
  bool _isClosing = false;

  bool get _isBusy =>
      state.isImporting || state.status == ProductFormStatus.saving;

  /// Loads the product being edited and its persisted documents.
  ///
  /// No-op when creating a new product.
  Future<void> load() async {
    final productId = _productId;
    if (productId == null) {
      return;
    }

    try {
      final product = await _repository.getById(productId);
      if (product == null) {
        _emit(const ProductFormState(status: ProductFormStatus.loadError));
        return;
      }

      final documents = await _documentRepository.getByProduct(productId);
      _emit(
        ProductFormState(
          status: ProductFormStatus.ready,
          product: product,
          documents: documents,
        ),
      );
    } on Exception {
      _emit(const ProductFormState(status: ProductFormStatus.loadError));
    }
  }

  /// Validates [data] and persists the product and its documents.
  ///
  /// Emits the validation errors without touching the repository when invalid,
  /// then [ProductFormStatus.saved] or [ProductFormStatus.saveError].
  Future<void> save(ProductFormData data) {
    if (_isBusy) {
      return Future.value();
    }
    return _track(() => _save(data));
  }

  /// Scans documents and stages them in the form.
  Future<void> scanDocuments() {
    if (_isBusy) {
      return Future.value();
    }
    return _track(() => _import(_documentImporter.scanDocuments));
  }

  /// Takes a photo and stages it in the form.
  Future<void> takePhoto() {
    if (_isBusy) {
      return Future.value();
    }
    return _track(
      () => _import(() async {
        final document = await _documentImporter.takePhoto();
        return document == null ? const <WarrantyDocument>[] : [document];
      }),
    );
  }

  /// Picks one or more files and stages them in the form.
  Future<void> pickDocuments() {
    if (_isBusy) {
      return Future.value();
    }
    return _track(() => _import(_documentImporter.pickFiles));
  }

  /// Removes a document from the form.
  ///
  /// Staged files are deleted immediately. Persisted documents are only marked
  /// for deletion and removed when the product is saved.
  Future<void> removeDocument(WarrantyDocument document) async {
    if (state.status == ProductFormStatus.saving) {
      return;
    }

    if (document.isPersisted) {
      _emit(
        state.copyWith(
          documents: state.documents
              .where((item) => item.id != document.id)
              .toList(),
          removedDocuments: [...state.removedDocuments, document],
          clearDocumentError: true,
        ),
      );
      return;
    }

    var deleteFailed = false;
    try {
      await _documentImporter.discard(document);
    } on Exception {
      deleteFailed = true;
    }

    _emit(
      state.copyWith(
        documents: state.documents
            .where((item) => item.filePath != document.filePath)
            .toList(),
        documentError: deleteFailed
            ? 'products.form.documents.error.delete'
            : null,
        clearDocumentError: !deleteFailed,
      ),
    );
  }

  /// Opens a document with the system viewer.
  Future<void> openDocument(WarrantyDocument document) async {
    _emit(state.copyWith(clearDocumentError: true));

    try {
      await _documentOpener.open(document.filePath);
    } on DocumentOpenException catch (error) {
      _emit(state.copyWith(documentError: documentOpenErrorKey(error.failure)));
    } on Exception {
      _emit(
        state.copyWith(documentError: 'products.form.documents.error.open'),
      );
    }
  }

  @override
  Future<void> close() async {
    _isClosing = true;

    final active = _activeOperation;
    if (active != null) {
      await active.future;
    }

    await _discardDocuments(
      state.documents.where((document) => !document.isPersisted),
    );
    await super.close();
  }

  Future<void> _save(ProductFormData data) async {
    final errors = _validate(data);
    if (errors.isNotEmpty) {
      _emit(state.copyWith(errors: errors));
      return;
    }

    _emit(
      state.copyWith(
        status: ProductFormStatus.saving,
        errors: const {},
        clearDocumentError: true,
      ),
    );

    try {
      final product = _toProduct(data);
      final saved = _productId == null
          ? await _repository.create(product)
          : await _repository.update(product);
      final productId = saved.id;
      if (productId == null) {
        _emit(state.copyWith(status: ProductFormStatus.saveError));
        return;
      }

      _productId = productId;
      _emit(state.copyWith(product: saved));

      await _persistDocuments(productId);
      await _deleteRemovedDocuments();

      _emit(
        state.copyWith(
          status: ProductFormStatus.saved,
          product: saved,
          removedDocuments: const [],
          clearDocumentError: true,
        ),
      );
    } on Exception {
      _emit(state.copyWith(status: ProductFormStatus.saveError));
    }
  }

  Future<void> _persistDocuments(int productId) async {
    final staged = state.documents
        .where((document) => !document.isPersisted)
        .toList();

    for (final document in staged) {
      final persisted = await _documentRepository.add(productId, document);
      _emit(
        state.copyWith(
          documents: state.documents
              .map(
                (item) => item.filePath == document.filePath ? persisted : item,
              )
              .toList(),
        ),
      );
    }
  }

  Future<void> _deleteRemovedDocuments() async {
    for (final document in List.of(state.removedDocuments)) {
      await _documentRepository.delete(document);
      _emit(
        state.copyWith(
          removedDocuments: state.removedDocuments
              .where((item) => item.id != document.id)
              .toList(),
        ),
      );
    }
  }

  Future<void> _import(
    Future<List<WarrantyDocument>> Function() importDocuments,
  ) async {
    _emit(state.copyWith(isImporting: true, clearDocumentError: true));

    try {
      final documents = await importDocuments();
      if (_isClosing) {
        await _discardDocuments(documents);
        return;
      }

      if (documents.isNotEmpty) {
        _emit(state.copyWith(documents: [...state.documents, ...documents]));
      }
    } on DocumentImportException catch (error) {
      _emit(state.copyWith(documentError: _importErrorKey(error.failure)));
    } on Exception {
      _emit(
        state.copyWith(documentError: 'products.form.documents.error.import'),
      );
    } finally {
      _emit(state.copyWith(isImporting: false));
    }
  }

  Future<void> _discardDocuments(Iterable<WarrantyDocument> documents) async {
    for (final document in documents) {
      if (document.isPersisted) {
        continue;
      }

      try {
        await _documentImporter.discard(document);
      } on Exception {
        debugPrint('ProductFormCubit: could not discard a staged document.');
      }
    }
  }

  Future<void> _track(Future<void> Function() operation) async {
    final completer = Completer<void>();
    _activeOperation = completer;

    try {
      await operation();
    } finally {
      if (identical(_activeOperation, completer)) {
        _activeOperation = null;
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  void _emit(ProductFormState next) {
    if (!_isClosing && !isClosed) {
      emit(next);
    }
  }

  Map<ProductFormField, String> _validate(ProductFormData data) {
    final errors = <ProductFormField, String>{};

    if (data.name.trim().isEmpty) {
      errors[ProductFormField.name] = 'products.form.error.nameRequired';
    }
    if (data.purchaseDate == null) {
      errors[ProductFormField.purchaseDate] =
          'products.form.error.purchaseDateRequired';
    }
    if (data.warrantyEndDate == null) {
      errors[ProductFormField.warrantyEndDate] =
          'products.form.error.warrantyEndRequired';
    } else if (data.purchaseDate != null &&
        data.warrantyEndDate!.isBefore(data.purchaseDate!)) {
      errors[ProductFormField.warrantyEndDate] =
          'products.form.error.warrantyEndBeforePurchase';
    }

    final priceText = data.priceText.trim();
    int? price;
    if (priceText.isNotEmpty) {
      price = parsePrice(priceText);
      if (price == null) {
        errors[ProductFormField.price] = 'products.form.error.priceInvalid';
      }
    }

    final currency = data.currency?.trim() ?? '';
    if (price != null && currency.isEmpty) {
      errors[ProductFormField.currency] =
          'products.form.error.currencyRequired';
    }

    return errors;
  }

  Product _toProduct(ProductFormData data) {
    final priceText = data.priceText.trim();
    final price = priceText.isEmpty ? null : parsePrice(priceText);
    final currency = _nullIfEmpty(data.currency);
    final existing = state.product;

    return Product(
      id: _productId,
      name: data.name.trim(),
      brand: _nullIfEmpty(data.brand),
      model: _nullIfEmpty(data.model),
      store: _nullIfEmpty(data.store),
      purchaseDate: data.purchaseDate,
      price: price,
      currency: price == null ? null : currency,
      serialNumber: _nullIfEmpty(data.serialNumber),
      warrantyEndDate: data.warrantyEndDate,
      notes: _nullIfEmpty(data.notes),
      createdAt: existing?.createdAt,
      updatedAt: existing?.updatedAt,
    );
  }

  static String? _nullIfEmpty(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static String _importErrorKey(DocumentImportFailure failure) {
    return switch (failure) {
      DocumentImportFailure.emptyFile =>
        'products.form.documents.error.emptyFile',
      DocumentImportFailure.unsupportedType =>
        'products.form.documents.error.unsupportedType',
      DocumentImportFailure.fileTooLarge =>
        'products.form.documents.error.fileTooLarge',
      DocumentImportFailure.permissionDenied =>
        'products.form.documents.error.permissionDenied',
      DocumentImportFailure.failed => 'products.form.documents.error.import',
    };
  }
}
