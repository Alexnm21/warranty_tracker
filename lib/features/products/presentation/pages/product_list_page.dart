import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_list_cubit.dart';
import '../bloc/product_list_state.dart';
import '../widgets/empty_products.dart';
import '../widgets/product_card.dart';

/// Products list screen.
///
/// Owns a [ProductListCubit] provided from the app's DI container and loads
/// the products on creation. Shows search, loading/error/empty states and the
/// list itself, with navigation to create, detail and delete actions.
class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductListCubit>()..load(),
      child: const _ProductListContent(),
    );
  }
}

/// Stateful body of the list, needed to own and dispose the search controller.
class _ProductListContent extends StatefulWidget {
  const _ProductListContent();

  @override
  State<_ProductListContent> createState() => _ProductListContentState();
}

class _ProductListContentState extends State<_ProductListContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Navigates to the create form.
  void _openCreate() => context.goNamed(RouteNames.productNew);

  /// Navigates to the detail page of the product with [id].
  void _openDetail(int id) => context.goNamed(
    RouteNames.productDetail,
    pathParameters: {'id': id.toString()},
  );

  /// Deletes the product with [id] and shows a snackbar if it fails.
  Future<void> _delete(ProductListCubit cubit, int id) async {
    final success = await cubit.delete(id);
    if (!success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('products.error.delete'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('products.title'.tr())),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _SearchField(controller: _searchController),
          ),
          Expanded(
            child: BlocBuilder<ProductListCubit, ProductListState>(
              builder: (context, state) {
                switch (state.status) {
                  case ProductListStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case ProductListStatus.error:
                    return _ErrorState(
                      onRetry: context.read<ProductListCubit>().load,
                    );
                  case ProductListStatus.loaded:
                    if (state.products.isEmpty) {
                      if (state.query.trim().isNotEmpty) {
                        return const _NoResults();
                      }
                      return EmptyProducts(onAdd: _openCreate);
                    }
                    return _ProductList(
                      products: state.products,
                      onOpen: _openDetail,
                      onDelete: _delete,
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Search input for the list.
///
/// Pushes each change to the cubit and toggles a clear button. Uses
/// [ValueListenableBuilder] so only this field rebuilds as the text changes,
/// instead of the whole page.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onChanged: context.read<ProductListCubit>().search,
          decoration: InputDecoration(
            hintText: 'products.search'.tr(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      context.read<ProductListCubit>().search('');
                    },
                  ),
          ),
        );
      },
    );
  }
}

/// Scrollable list of products.
///
/// Each item can be tapped to open its detail page or swiped end-to-start to
/// delete it (with a confirmation dialog first).
class _ProductList extends StatelessWidget {
  const _ProductList({
    required this.products,
    required this.onOpen,
    required this.onDelete,
  });

  final List<Product> products;
  final void Function(int id) onOpen;
  final Future<void> Function(ProductListCubit cubit, int id) onDelete;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductListCubit>();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final product = products[index];
        return Dismissible(
          key: ValueKey(product.id),
          direction: DismissDirection.endToStart,
          background: const _DismissBackground(),
          confirmDismiss: (_) async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text('products.delete.title'.tr()),
                content: Text(
                  'products.delete.message'.tr(
                    namedArgs: {'name': product.name},
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text('common.cancel'.tr()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: Text('common.delete'.tr()),
                  ),
                ],
              ),
            );
            return confirmed ?? false;
          },
          onDismissed: (_) => onDelete(cubit, product.id!),
          child: ProductCard(
            product: product,
            onTap: () => onOpen(product.id!),
          ),
        );
      },
    );
  }
}

/// Error state shown when loading the list fails, with a retry action.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

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

/// Shown when a search yields no matches (as opposed to the full empty state).
class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'products.noResults'.tr(),
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Red background revealed behind an item while swiping to delete.
class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: const Icon(Icons.delete_outline, color: AppColors.onError),
    );
  }
}
