import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../documents/domain/entities/warranty_document.dart';
import 'confirm_document_removal.dart';
import 'warranty_document_tile.dart';

/// Document actions and attachment list shown in the product form.
///
/// Persisted and staged documents are displayed together; staged documents are
/// marked as pending until the product is saved.
class ProductDocumentsSection extends StatelessWidget {
  const ProductDocumentsSection({
    super.key,
    required this.documents,
    required this.isImporting,
    required this.isBusy,
    required this.error,
    required this.onScan,
    required this.onUpload,
    required this.onTakePhoto,
    required this.onOpen,
    required this.onRemove,
  });

  final List<WarrantyDocument> documents;
  final bool isImporting;
  final bool isBusy;
  final String? error;
  final Future<void> Function() onScan;
  final Future<void> Function() onUpload;
  final Future<void> Function() onTakePhoto;
  final Future<void> Function(WarrantyDocument document) onOpen;
  final Future<void> Function(WarrantyDocument document) onRemove;

  static final ButtonStyle _actionStyle = OutlinedButton.styleFrom(
    minimumSize: const Size(0, 48),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        if (isImporting) ...[
          Row(
            children: [
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'products.form.documents.importing'.tr(),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _ActionButton(
              icon: Icons.document_scanner_outlined,
              label: 'products.form.documents.actions.scan'.tr(),
              style: _actionStyle,
              onPressed: isBusy ? null : onScan,
            ),
            _ActionButton(
              icon: Icons.upload_file_outlined,
              label: 'products.form.documents.actions.upload'.tr(),
              style: _actionStyle,
              onPressed: isBusy ? null : onUpload,
            ),
            _ActionButton(
              icon: Icons.photo_camera_outlined,
              label: 'products.form.documents.actions.photo'.tr(),
              style: _actionStyle,
              onPressed: isBusy ? null : onTakePhoto,
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, size: 18, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  error!.tr(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (documents.isEmpty && !isImporting) const _EmptyDocuments(),
        if (documents.isNotEmpty)
          for (var index = 0; index < documents.length; index++) ...[
            WarrantyDocumentTile(
              document: documents[index],
              isBusy: isBusy,
              onOpen: () => onOpen(documents[index]),
              onRemove: () => _confirmRemove(context, documents[index]),
            ),
            if (index < documents.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WarrantyDocument document,
  ) async {
    final messageKey = document.isPersisted
        ? 'products.form.documents.remove.savedMessage'
        : 'products.form.documents.remove.stagedMessage';

    final confirmed = await confirmDocumentRemoval(
      context,
      fileName: document.fileName,
      messageKey: messageKey,
    );

    if (confirmed && context.mounted) {
      await onRemove(document);
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.style,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final ButtonStyle style;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed == null
          ? null
          : () async {
              await onPressed!();
            },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: style,
    );
  }
}

class _EmptyDocuments extends StatelessWidget {
  const _EmptyDocuments();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.attach_file_outlined,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'products.form.documents.empty'.tr(),
            style: AppTextStyles.label,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'products.form.documents.emptyHint'.tr(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
