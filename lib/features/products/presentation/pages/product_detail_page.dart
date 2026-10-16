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
import '../../../../core/utils/price_format.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_detail_cubit.dart';
import '../bloc/product_detail_state.dart';
import '../widgets/warranty_status_pill.dart';

/// Product detail screen.
///
/// Prioritizes the warranty (status, dates) followed by purchase and product
/// information, per `DESIGN.md`. Owns a [ProductDetailCubit] created from DI
/// with the [productId] taken from the route.
class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.productId});

  /// Id of the product to display, taken from the route path parameters.
  final int productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductDetailCubit>(param1: productId)..load(),
      child: const _ProductDetailView(),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView();

  /// Navigates to the edit form of [id].
  void _openEdit(BuildContext context, int id) => context.goNamed(
    RouteNames.productEdit,
    pathParameters: {'id': id.toString()},
  );

  /// Confirms and performs deletion, returning to the list when it succeeds.
  Future<void> _delete(BuildContext context, Product product) async {
    final cubit = context.read<ProductDetailCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('products.delete.title'.tr()),
        content: Text(
          'products.delete.message'.tr(namedArgs: {'name': product.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final success = await cubit.delete();
    if (!context.mounted) {
      return;
    }

    if (success) {
      context.goNamed(RouteNames.productList);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('products.error.delete'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailCubit, ProductDetailState>(
      builder: (context, state) {
        final product = state.product;

        return Scaffold(
          appBar: AppBar(
            title: Text(product?.name ?? ''),
            actions: product == null
                ? null
                : [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'common.edit'.tr(),
                      onPressed: () => _openEdit(context, product.id!),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'common.delete'.tr(),
                      onPressed: () => _delete(context, product),
                    ),
                  ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProductDetailState state) {
    switch (state.status) {
      case ProductDetailStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ProductDetailStatus.notFound:
        return _MessageState(
          icon: Icons.search_off,
          message: 'products.detail.notFound'.tr(),
        );
      case ProductDetailStatus.error:
        return _MessageState(
          icon: Icons.error_outline,
          message: 'products.error.load'.tr(),
          onRetry: context.read<ProductDetailCubit>().load,
        );
      case ProductDetailStatus.loaded:
        return _ProductDetails(product: state.product!);
    }
  }
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      product.brand,
      product.model,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(product.name, style: AppTextStyles.headline),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: WarrantyStatusPill(status: product.warrantyStatus),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          title: 'products.detail.warranty'.tr(),
          rows: [
            if (product.warrantyStartDate != null)
              MapEntry(
                'products.detail.warrantyStartDate'.tr(),
                formatDate(context, product.warrantyStartDate!),
              ),
            if (product.warrantyEndDate != null)
              MapEntry(
                'products.detail.warrantyEndDate'.tr(),
                formatDate(context, product.warrantyEndDate!),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _Section(
          rows: [
            if (_hasValue(product.brand))
              MapEntry('products.detail.brand'.tr(), product.brand!),
            if (_hasValue(product.model))
              MapEntry('products.detail.model'.tr(), product.model!),
            if (_hasValue(product.serialNumber))
              MapEntry(
                'products.detail.serialNumber'.tr(),
                product.serialNumber!,
              ),
            if (_hasValue(product.store))
              MapEntry('products.detail.store'.tr(), product.store!),
            if (product.purchaseDate != null)
              MapEntry(
                'products.detail.purchaseDate'.tr(),
                formatDate(context, product.purchaseDate!),
              ),
            if (product.price != null)
              MapEntry(
                'products.detail.price'.tr(),
                formatPrice(context, product.price!, product.currency),
              ),
          ],
        ),
        if (_hasValue(product.notes)) ...[
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'products.detail.notes'.tr(),
            children: [Text(product.notes!, style: AppTextStyles.body)],
          ),
        ],
      ],
    );
  }

  static bool _hasValue(String? value) =>
      value != null && value.trim().isNotEmpty;
}

/// A card grouping labeled rows; renders nothing when empty.
class _Section extends StatelessWidget {
  const _Section({this.title, this.rows = const [], this.children = const []});

  final String? title;
  final List<MapEntry<String, String>> rows;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty && children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.sm),
            ],
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _DetailRow(label: row.key, value: row.value),
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A single label/value row.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTextStyles.body),
      ],
    );
  }
}

/// Centered icon + optional message + optional retry action.
class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, this.message, this.onRetry});

  final IconData icon;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.onSurfaceVariant),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: onRetry,
                child: Text('common.confirm'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
