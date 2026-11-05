// lib/core/widgets/dialogs/custom_date_picker_dialog.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../svg_icon.dart';

Future<DateTime?> showCustomDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
  bool barrierDismissible = true,
}) {
  DateTime selectedDate = initialDate;
  final first = firstDate ?? DateTime(1900);
  final last = lastDate ?? DateTime(2100);

  return showDialog<DateTime>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        SvgIcon(iconName: 'calendar', size: 24),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          title ?? 'products.form.purchaseDate'.tr(),
                          style: AppTextStyles.title,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  CalendarDatePicker(
                    initialDate: selectedDate,
                    firstDate: first,
                    lastDate: last,

                    onDateChanged: (date) {
                      setState(() {
                        selectedDate = date;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text('common.cancel'.tr()),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () =>
                            Navigator.pop(dialogContext, selectedDate),
                        label: Text('common.confirm'.tr()),
                        icon: Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppColors.onPrimary,
                        ),
                        iconAlignment: IconAlignment.end,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
