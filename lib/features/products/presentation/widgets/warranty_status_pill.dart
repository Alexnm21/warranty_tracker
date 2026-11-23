import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/warranty_status.dart';

class WarrantyStatusPill extends StatelessWidget {
  const WarrantyStatusPill({super.key, required this.status});

  final WarrantyStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon, labelKey) = switch (status) {
      WarrantyStatus.future => (
        AppColors.surfaceContainerHigh,
        AppColors.onSurfaceVariant,
        Icons.schedule,
        'products.warranty.status.future',
      ),
      WarrantyStatus.active => (
        AppColors.statusActiveBackground,
        AppColors.statusActiveText,
        Icons.check_circle,
        'products.warranty.status.active',
      ),
      WarrantyStatus.expired => (
        AppColors.statusExpiredBackground,
        AppColors.statusExpiredText,
        Icons.event_busy,
        'products.warranty.status.expired',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            labelKey.tr(),
            style: AppTextStyles.labelSmall.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
