import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/option_selector_row.dart';
import '../../domain/entities/reminder_settings.dart';
import '../bloc/reminder_settings_state.dart';

/// Reminder preferences shown on the settings screen.
///
/// Presentational only: all state changes are delegated to the callbacks so
/// the widget stays independent of the cubit and easy to test.
class ReminderSettingsSection extends StatelessWidget {
  const ReminderSettingsSection({
    super.key,
    required this.state,
    required this.onEnabledChanged,
    required this.onLeadDaysChanged,
    required this.onOpenSystemSettings,
    required this.onRetry,
  });

  final ReminderSettingsState state;
  final Future<void> Function(bool value) onEnabledChanged;
  final Future<void> Function(int days) onLeadDaysChanged;
  final Future<void> Function() onOpenSystemSettings;
  final Future<void> Function() onRetry;

  static final List<String> _leadDayOptions = ReminderSettings.leadDaysOptions
      .toList()
      .map((days) => days.toString())
      .toList();

  @override
  Widget build(BuildContext context) {
    final settings = state.settings;
    final isSaving = state.status == ReminderSettingsStatus.saving;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('settings.reminders.title'.tr(), style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'settings.reminders.description'.tr(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'settings.reminders.enable'.tr(),
                style: AppTextStyles.label,
              ),
              value: settings?.enabled ?? false,
              onChanged: isSaving ? null : (value) => onEnabledChanged(value),
            ),
            if (state.status == ReminderSettingsStatus.permissionBlocked) ...[
              const SizedBox(height: AppSpacing.sm),
              _InlineMessage(
                icon: Icons.notifications_off_outlined,
                text: 'settings.reminders.permissionDenied'.tr(),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => onOpenSystemSettings(),
                icon: const Icon(Icons.open_in_new_outlined, size: 18),
                label: Text('settings.reminders.openSystemSettings'.tr()),
              ),
            ],
            if (settings != null &&
                state.status != ReminderSettingsStatus.permissionBlocked) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'settings.reminders.leadTime'.tr(),
                style: AppTextStyles.label,
              ),
              const SizedBox(height: AppSpacing.sm),
              OptionSelectorRow(
                options: _leadDayOptions,
                selectedOption: settings.leadDays.toString(),
                onOptionSelected: (value) {
                  final days = int.tryParse(value);
                  if (days != null) {
                    onLeadDaysChanged(days);
                  }
                },
              ),
            ],
            if (isSaving) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'settings.reminders.saving'.tr(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            if (state.status == ReminderSettingsStatus.error) ...[
              const SizedBox(height: AppSpacing.md),
              _InlineMessage(
                icon: Icons.error_outline,
                text: (state.errorKey ?? 'settings.reminders.error.save').tr(),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => onRetry(),
                child: Text('common.retry'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.error),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}
