import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/extensions/widget_extensions.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/dialogs/custom_date_picker_dialog.dart';
import '../../../../core/widgets/option_selector_row.dart';
import '../../../../core/widgets/svg_icon.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_form_cubit.dart';
import '../bloc/product_form_state.dart';
import '../widgets/product_documents_section.dart';

/// Days used to approximate one warranty year.
const int _daysPerYear = 365;

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
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _storeController = TextEditingController();
  final _priceController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _purchaseDate;
  DateTime? _warrantyEndDate;

  /// ISO 4217 code of the currency the price is expressed in.
  String _currency = AppCurrencies.defaultCode;

  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isEditing) {
      final now = DateTime.now();
      _purchaseDate = now;
      _warrantyEndDate = now.add(const Duration(days: _daysPerYear));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _storeController.dispose();
    _priceController.dispose();
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
    _currency = product.currency ?? AppCurrencies.defaultCode;
    _serialNumberController.text = product.serialNumber ?? '';
    _notesController.text = product.notes ?? '';
    _purchaseDate = product.purchaseDate;
    _warrantyEndDate = product.warrantyEndDate;
  }

  /// Currency codes offered in the dropdown.
  ///
  /// Keeps a stored currency that is no longer offered, so products saved
  /// before it was removed can still be edited.
  List<String> get _currencyOptions {
    if (AppCurrencies.supported.contains(_currency)) {
      return AppCurrencies.supported;
    }
    return [_currency, ...AppCurrencies.supported];
  }

  Future<void> _pickDate(
    DateTime? current,
    ValueChanged<DateTime> onPicked,
  ) async {
    final now = DateTime.now();
    final picked = await showCustomDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      title: 'products.form.purchaseDate'.tr(),
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
        currency: _currency,
        serialNumber: _serialNumberController.text,
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
        centerTitle: true,
        title: Text(
          widget.isEditing
              ? 'products.form.title.edit'.tr()
              : 'products.form.title.create'.tr(),
        ),
        actions: [
          BlocSelector<ProductFormCubit, ProductFormState, bool>(
            selector: (state) =>
                state.status == ProductFormStatus.saving || state.isImporting,
            builder: (context, isBusy) => IconButton(
              onPressed: isBusy ? null : _save,
              icon: Icon(
                Icons.save,
                color: isBusy ? AppColors.outlineVariant : AppColors.primary,
              ),
            ),
          ),
        ],
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
    final busy = saving || state.isImporting;
    final cubit = context.read<ProductFormCubit>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _FormSectionCard(
          title: 'products.form.section.purchase'.tr(),
          icon: const SvgIcon(
            iconName: 'product_outlined',
            color: AppColors.primary,
            size: 17,
          ),
          children: [
            _TextField(
              controller: _nameController,
              label: 'products.form.name'.tr(),
              error: errors[ProductFormField.name]?.tr(),
              textCapitalization: TextCapitalization.words,
              isRequired: true,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _TextField(
                    controller: _brandController,
                    label: 'products.form.brand'.tr(),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _TextField(
                    controller: _modelController,
                    label: 'products.form.model'.tr(),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            _TextField(
              controller: _serialNumberController,
              label: 'products.form.serialNumber'.tr(),
            ),
          ],
        ).withPadding(const EdgeInsets.only(bottom: AppSpacing.lg)),

        _FormSectionCard(
          title: 'products.form.section.purchase'.tr(),
          icon: const SvgIcon(
            iconName: 'ticket',
            color: AppColors.primary,
            size: 17,
          ),
          children: [
            _TextField(
              controller: _storeController,
              label: 'products.form.store'.tr(),
              textCapitalization: TextCapitalization.words,
            ),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'products.form.purchaseDate'.tr(),
                    value: _purchaseDate,
                    error: errors[ProductFormField.purchaseDate]?.tr(),
                    onTap: () => _pickDate(_purchaseDate, (date) {
                      setState(() => _purchaseDate = date);
                    }),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _TextField(
                    controller: _priceController,
                    label: 'products.form.price'.tr(),
                    error: errors[ProductFormField.price]?.tr(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefix: Text(
                      '$_currency  ',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _CurrencyDropdown(
              value: _currency,
              options: _currencyOptions,
              error: errors[ProductFormField.currency]?.tr(),
              onChanged: (currency) {
                setState(() => _currency = currency);
              },
            ),
          ],
        ).withPadding(const EdgeInsets.only(bottom: AppSpacing.lg)),

        _FormSectionCard(
          title: 'products.form.section.warranty'.tr(),
          icon: const SvgIcon(
            iconName: 'check',
            color: AppColors.primary,
            size: 17,
          ),
          children: [
            _WarrantyDurationField(
              endDate: _warrantyEndDate,
              purchaseDate: _purchaseDate,
              onEndDateChange: (date) {
                setState(() => _warrantyEndDate = date);
              },
            ),
            _TextField(
              controller: _notesController,
              label: 'products.form.notes'.tr(),
              maxLines: 3,
            ),
          ],
        ).withPadding(const EdgeInsets.only(bottom: AppSpacing.lg)),

        _FormSectionCard(
          title: 'products.form.section.documents'.tr(),
          icon: const Icon(
            Icons.attach_file,
            size: 17,
            color: AppColors.primary,
          ),
          children: [
            ProductDocumentsSection(
              documents: state.documents,
              isImporting: state.isImporting,
              isBusy: busy,
              error: state.documentError,
              onScan: cubit.scanDocuments,
              onUpload: cubit.pickDocuments,
              onTakePhoto: cubit.takePhoto,
              onOpen: cubit.openDocument,
              onRemove: cubit.removeDocument,
            ),
          ],
        ).withPadding(const EdgeInsets.only(bottom: AppSpacing.lg)),

        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: busy ? null : _save,
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

/// A card with a title that contains a list of TextFields.
class _FormSectionCard extends StatelessWidget {
  final String title;
  final Widget icon;
  final List<Widget> children;

  const _FormSectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: AppSpacing.xs),
              Text(title, style: AppTextStyles.label),
            ],
          ),
          const Divider(
            height: 1,
            color: AppColors.surfaceContainerHigh,
          ).withPadding(const EdgeInsets.only(top: AppRadii.sm)),
          ...children,
        ],
      ),
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
    this.isRequired = false,
    this.prefix,
  });

  final TextEditingController controller;
  final String label;
  final String? error;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final bool isRequired;
  final Widget? prefix;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Text(label, style: AppTextStyles.labelSmall),
              if (isRequired)
                Text(
                  ' *',
                  style: AppTextStyles.label.copyWith(color: AppColors.error),
                ),
            ],
          ),
          TextField(
            controller: controller,

            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            maxLines: maxLines,
            decoration: InputDecoration(errorText: error, prefix: prefix),
          ),
        ],
      ),
    );
  }
}

/// Dropdown to select the currency the price is expressed in.
class _CurrencyDropdown extends StatelessWidget {
  const _CurrencyDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
    this.error,
  });

  /// Currently selected ISO 4217 code.
  final String value;

  /// Codes offered in the dropdown; always contains [value].
  final List<String> options;

  final ValueChanged<String> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('products.form.currency'.tr(), style: AppTextStyles.labelSmall),
          DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            items: [
              for (final code in options)
                DropdownMenuItem(value: code, child: Text(code)),
            ],
            onChanged: (code) {
              if (code != null) {
                onChanged(code);
              }
            },
            decoration: InputDecoration(errorText: error),
          ),
        ],
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
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelSmall),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: InputDecorator(
              decoration: InputDecoration(
                errorText: error,
                suffixIcon: const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              child: Text(
                value == null ? '' : formatDate(context, value!),
                style: AppTextStyles.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarrantyDurationField extends StatefulWidget {
  final DateTime? purchaseDate;
  final DateTime? endDate;
  final Function(DateTime) onEndDateChange;
  const _WarrantyDurationField({
    required this.purchaseDate,
    required this.endDate,
    required this.onEndDateChange,
  });

  @override
  State<_WarrantyDurationField> createState() => _WarrantyDurationFieldState();
}

class _WarrantyDurationFieldState extends State<_WarrantyDurationField> {
  /// Index of the "custom" option, where the end date is picked manually.
  static const int _customOptionIndex = 3;

  List<String> options = [
    'products.form.years.one'.tr(args: ['1']),
    'products.form.years.other'.tr(args: ['2']),
    'products.form.years.other'.tr(args: ['3']),
    'products.form.custom'.tr(),
  ];

  late String _selectedOption;

  @override
  void initState() {
    super.initState();
    _selectedOption = _optionForDates(widget.purchaseDate, widget.endDate);
  }

  /// Picks the duration option matching [endDate], falling back to "custom"
  /// when it does not match a whole number of years.
  String _optionForDates(DateTime? purchaseDate, DateTime? endDate) {
    if (purchaseDate == null || endDate == null) {
      return options.first;
    }

    final start = DateUtils.dateOnly(purchaseDate);
    final end = DateUtils.dateOnly(endDate);
    for (var i = 0; i < _customOptionIndex; i++) {
      final expected = start.add(Duration(days: _daysPerYear * (i + 1)));
      if (DateUtils.isSameDay(expected, end)) {
        return options[i];
      }
    }

    return options[_customOptionIndex];
  }

  /// Calculates the warranty end date from the purchase date and the selected
  /// duration. The warranty starts on the purchase date.
  void _calculateEndDate(String optionSelected) {
    final purchaseDate = widget.purchaseDate;
    if (purchaseDate == null) return;

    final index = options.indexOf(optionSelected);
    if (index < 0 || index == _customOptionIndex) {
      // The end date is chosen by hand with the date picker.
      return;
    }

    widget.onEndDateChange(
      purchaseDate.add(Duration(days: _daysPerYear * (index + 1))),
    );
  }

  Future<void> _onOptionSelected(String option) async {
    final index = options.indexOf(option);
    if (index < 0) return;

    if (index == _customOptionIndex) {
      final picked = await _pickCustomEndDate();
      if (picked != null && mounted) {
        setState(() => _selectedOption = option);
        widget.onEndDateChange(picked);
      }
      return;
    }

    setState(() => _selectedOption = option);
    _calculateEndDate(option);
  }

  Future<DateTime?> _pickCustomEndDate() async {
    final purchaseDate = widget.purchaseDate;
    final firstDate = purchaseDate == null
        ? DateTime(2000)
        : DateUtils.dateOnly(purchaseDate);
    final lastDate = DateTime(2100);
    var initialDate = DateUtils.dateOnly(
      widget.endDate ?? purchaseDate ?? DateTime.now(),
    );
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }
    if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    return showCustomDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: 'products.form.warrantyEndDate'.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('products.form.duration'.tr(), style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.smm),
        OptionSelectorRow(
          options: options,
          selectedOption: _selectedOption,
          onOptionSelected: _onOptionSelected,
        ),
        Container(
          margin: EdgeInsets.only(top: AppSpacing.md),
          padding: EdgeInsets.all(AppSpacing.smm),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            border: Border.all(color: AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.secondaryContainer,
                foregroundColor: AppColors.onSecondaryContainer,
                radius: 16,
                child: Icon(Icons.check_circle, size: 16),
              ),
              const SizedBox(width: AppSpacing.smm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'products.form.calculated_date'.tr(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (widget.endDate != null)
                    Text(
                      widget.endDate!.dateString,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    ).withPadding(EdgeInsetsGeometry.only(top: AppSpacing.md));
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
