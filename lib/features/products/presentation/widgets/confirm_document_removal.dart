import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Shows a confirmation dialog before deleting a warranty document.
///
/// Shared by the product form (removal applied on save) and the product detail
/// screen (immediate removal). Returns `true` only when the user confirms.
Future<bool> confirmDocumentRemoval(
  BuildContext context, {
  required String fileName,
  required String messageKey,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('documents.remove.title'.tr()),
      content: Text(messageKey.tr(namedArgs: {'name': fileName})),
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

  return confirmed == true;
}
