import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_form_cubit.dart';
import '../bloc/product_form_state.dart';

/// Product create/edit form.
///
/// Loads the product when editing and validates + saves it through
/// [ProductFormCubit]. Validation lives in the cubit; the page only renders
/// fields and forwards the entered values on save.
class ProductFormPage extends StatelessWidget {
  const ProductFormPage({super.key, this.productId});

  /// Id of the product being edited, or `null` to create a new product.
  final int? productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductFormCubit>(param1: productId)..load(),
      child: _ProductFormView(isEditing: productId != null),
    );
  }
}

class _ProductFormView extends StatefulWidget {
  const _ProductFormView({required this.isEditing});

  final bool isEditing;

  @override
  State<_ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<_ProductFormView> {
  // Default currency for new products (FIELD_REQUIREMENTS.md §11).
  static const String _defaultCurrency = 'EUR';

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _storeController = TextEditingController();
  final _priceController = TextEditingController();
  final _currencyController = TextEditingController(text: _defaultCurrency);
  final _serialNumberController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _purchaseDate;
  DateTime? _warrantyStartDate;
  DateTime? _warrantyEndDate;

  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isEditing) {
      _currencyController.text = _defaultCurrency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _storeController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    _serialNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Fills the fields with the loaded product (edit mode), once.
  void _prefill(Product product) {
    _nameController.text = product.name;
    _brandController.text = product.brand ?? '';
    _modelController.text = product.model ?? '';
    _storeController.text = product.store ?? '';
    _priceController.text = product.price == null
        ? ''
        : (product.price! / 100).toStringAsFixed(2);
    _currencyController.text = product.currency ?? _defaultCurrency;
    _serialNumberController.text = product.serialNumber ?? '';
    _notesController.text = product.notes ?? '';
    _purchaseDate = product.purchaseDate;
    _warrantyStartDate = product.warrantyStartDate;
    _warrantyEndDate = product.warrantyEndDate;
  }

  Future<void> _pickDate(
    DateTime? current,
    ValueChanged<DateTime> onPicked,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  void _save() {
    context.read<ProductFormCubit>().save(
      ProductFormData(
        name: _nameController.text,
        brand: _brandController.text,
        model: _modelController.text,
        store: _storeController.text,
        purchaseDate: _purchaseDate,
        priceText: _priceController.text,
        currency: _currencyController.text,
        serialNumber: _serialNumberController.text,
        warrantyStartDate: _warrantyStartDate,
        warrantyEndDate: _warrantyEndDate,
        notes: _notesController.text,
      ),
    );
  }

  void _onState(BuildContext context, ProductFormState state) {
    if (state.product != null && !_prefilled && widget.isEditing) {
      _prefill(state.product!);
      _prefilled = true;
    }

    if (state.status == ProductFormStatus.saved) {
      context.goNamed(RouteNames.productList);
    } else if (state.status == ProductFormStatus.saveError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('products.error.save'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'products.form.title.edit'.tr()
              : 'products.form.title.create'.tr(),
        ),
      ),
      body: BlocConsumer<ProductFormCubit, ProductFormState>(
        listener: _onState,
        builder: (context, state) {
          if (state.status == ProductFormStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == ProductFormStatus.loadError) {
            return _FormErrorState(
              onRetry: context.read<ProductFormCubit>().load,
            );
          }
          return _buildForm(context, state);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, ProductFormState state) {
    final errors = state.errors;
    final saving = state.status == ProductFormStatus.saving;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _TextField(
          controller: _nameController,
          label: 'products.form.name'.tr(),
          error: errors[ProductFormField.name]?.tr(),
          textCapitalization: TextCapitalization.words,
        ),
        _TextField(
          controller: _brandController,
          label: 'products.form.brand'.tr(),
          textCapitalization: TextCapitalization.words,
        ),
        _TextField(
          controller: _modelController,
          label: 'products.form.model'.tr(),
        ),
        _TextField(
          controller: _storeController,
          label: 'products.form.store'.tr(),
          textCapitalization: TextCapitalization.words,
        ),
        _DateField(
          label: 'products.form.purchaseDate'.tr(),
          value: _purchaseDate,
          error: errors[ProductFormField.purchaseDate]?.tr(),
          onTap: () => _pickDate(_purchaseDate, (date) {
            setState(() => _purchaseDate = date);
          }),
        ),
        _DateField(
          label: 'products.form.warrantyStartDate'.tr(),
          value: _warrantyStartDate,
          error: errors[ProductFormField.warrantyStartDate]?.tr(),
          onTap: () => _pickDate(_warrantyStartDate, (date) {
            setState(() => _warrantyStartDate = date);
          }),
        ),
        _DateField(
          label: 'products.form.warrantyEndDate'.tr(),
          value: _warrantyEndDate,
          error: errors[ProductFormField.warrantyEndDate]?.tr(),
          onTap: () => _pickDate(_warrantyEndDate, (date) {
            setState(() => _warrantyEndDate = date);
          }),
        ),
        _TextField(
          controller: _priceController,
          label: 'products.form.price'.tr(),
          error: errors[ProductFormField.price]?.tr(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        _TextField(
          controller: _currencyController,
          label: 'products.form.currency'.tr(),
          error: errors[ProductFormField.currency]?.tr(),
          textCapitalization: TextCapitalization.characters,
        ),
        _TextField(
          controller: _serialNumberController,
          label: 'products.form.serialNumber'.tr(),
        ),
        _TextField(
          controller: _notesController,
          label: 'products.form.notes'.tr(),
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: saving ? null : _save,
          child: saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('products.form.save'.tr()),
        ),
      ],
    );
  }
}

/// Labeled text input with a consistent look and an optional error message.
class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.error,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? error;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, errorText: error),
      ),
    );
  }
}

/// Tappable read-only field that opens a date picker.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.error,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: error,
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
          ),
          child: Text(
            value == null ? '' : formatDate(context, value!),
            style: AppTextStyles.body,
          ),
        ),
      ),
    );
  }
}

/// Error state shown when the product to edit cannot be loaded.
class _FormErrorState extends StatelessWidget {
  const _FormErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'products.error.load'.tr(),
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onRetry,
              child: Text('common.confirm'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
