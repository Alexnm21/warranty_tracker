import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../reminders/presentation/bloc/reminder_settings_cubit.dart';
import '../../../reminders/presentation/bloc/reminder_settings_state.dart';
import '../../../reminders/presentation/widgets/reminder_settings_section.dart';

/// Application settings screen, currently hosting the reminder preferences.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReminderSettingsCubit>()..load(),
      child: const _SettingsContent(),
    );
  }
}

class _SettingsContent extends StatefulWidget {
  const _SettingsContent();

  @override
  State<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContent> {
  /// Whether this route was current at the last dependency change.
  ///
  /// Starts as `true` because the cubit is loaded by `BlocProvider` on the
  /// first build, so only later re-entries need a permission refresh.
  bool _wasCurrent = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isCurrent = ModalRoute.isCurrentOf(context) ?? true;
    if (!isCurrent) {
      _wasCurrent = false;
    } else if (!_wasCurrent) {
      _wasCurrent = true;
      context.read<ReminderSettingsCubit>().refreshPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReminderSettingsCubit, ReminderSettingsState>(
      builder: (context, state) {
        final cubit = context.read<ReminderSettingsCubit>();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('settings.title'.tr(), style: AppTextStyles.headline),
              const SizedBox(height: AppSpacing.lg),
              ReminderSettingsSection(
                state: state,
                onEnabledChanged: cubit.setEnabled,
                onLeadDaysChanged: cubit.setLeadDays,
                onOpenSystemSettings: cubit.openSystemSettings,
                onRetry: cubit.load,
                onDebugPrintPending: cubit.debugPrintPendingReminders,
              ),
            ],
          ),
        );
      },
    );
  }
}
