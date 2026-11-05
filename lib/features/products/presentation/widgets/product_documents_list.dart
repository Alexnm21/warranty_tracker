import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../documents/domain/entities/warranty_document.dart';
import 'warranty_document_tile.dart';

/// Read-only list of a product's persisted documents.
///
/// Handles the loading, empty, load-error and open-error states used by the
/// product detail screen.
class ProductDocumentsList extends StatelessWidget {
  const ProductDocumentsList({
    super.key,
    required this.documents,
    required this.isLoading,
    required this.loadError,
    required this.openError,
    required this.onOpen,
    required this.onRetry,
  });

  final List<WarrantyDocument> documents;
  final bool isLoading;

  /// Load error as a localization key.
  final String? loadError;

  /// Open error as a localization key.
  final String? openError;

  final Future<void> Function(WarrantyDocument document) onOpen;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (loadError != null) {
      return _DocumentsError(messageKey: loadError!, onRetry: onRetry);
    }

    if (documents.isEmpty) {
      return const _EmptyDocuments();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (openError != null) ...[
          _InlineError(messageKey: openError!),
          const SizedBox(height: AppSpacing.md),
        ],
        for (var index = 0; index < documents.length; index++) ...[
          WarrantyDocumentTile(
            document: documents[index],
            showPending: false,
            onOpen: () => onOpen(documents[index]),
          ),
          if (index < documents.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _EmptyDocuments extends StatelessWidget {
  const _EmptyDocuments();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.attach_file_outlined,
          color: AppColors.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'products.detail.documents.empty'.tr(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentsError extends StatelessWidget {
  const _DocumentsError({required this.messageKey, required this.onRetry});

  final String messageKey;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InlineError(messageKey: messageKey),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () async {
            await onRetry();
          },
          child: Text('products.detail.documents.retry'.tr()),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.messageKey});

  final String messageKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, size: 18, color: AppColors.error),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            messageKey.tr(),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}
