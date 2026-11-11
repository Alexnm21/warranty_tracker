import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../documents/domain/entities/warranty_document.dart';

/// A tappable row that represents a stored warranty document.
///
/// Used by the form to open/remove staged and persisted documents, and by the
/// detail screen to open and delete persisted documents.
class WarrantyDocumentTile extends StatelessWidget {
  const WarrantyDocumentTile({
    super.key,
    required this.document,
    required this.onOpen,
    this.onRemove,
    this.isBusy = false,
    this.showPending = true,
  });

  final WarrantyDocument document;
  final Future<void> Function() onOpen;
  final Future<void> Function()? onRemove;
  final bool isBusy;
  final bool showPending;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: isBusy
            ? null
            : () async {
                await onOpen();
              },
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.smm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.base),
                ),
                child: Icon(
                  document.isImage
                      ? Icons.image_outlined
                      : Icons.picture_as_pdf_outlined,
                  size: 20,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.smm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label,
                    ),
                    if (showPending && !document.isPersisted) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'products.form.documents.pending'.tr(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: isBusy
                    ? null
                    : () async {
                        await onOpen();
                      },
                icon: const Icon(Icons.open_in_new, size: 20),
                tooltip: 'products.form.documents.open'.tr(),
                color: AppColors.primary,
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: isBusy
                      ? null
                      : () async {
                          await onRemove!();
                        },
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'documents.remove.action'.tr(),
                  color: AppColors.error,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
