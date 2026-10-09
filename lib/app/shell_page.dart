import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/scale_on_press.dart';
import '../core/widgets/svg_icon.dart';
import 'theme/app_colors.dart';

class ShellPage extends StatelessWidget {
  const ShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          _ShellNavigationDestination(
            iconName: 'home_outlined',
            selectedIconName: 'home',
            label: 'shell.home'.tr(),
          ),
          _ShellNavigationDestination(
            iconName: 'product_outlined',
            selectedIconName: 'product',
            label: 'shell.products'.tr(),
          ),
          _ShellNavigationDestination(
            iconName: 'settings',
            selectedIconName: 'settings',
            label: 'shell.settings'.tr(),
          ),
        ],
      ),
    );
  }
}

class _ShellNavigationDestination extends StatelessWidget {
  final String iconName;
  final String selectedIconName;
  final String label;

  const _ShellNavigationDestination({
    required this.iconName,
    required this.selectedIconName,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnPress(
      child: NavigationDestination(
        icon: SvgIcon(iconName: iconName, color: AppColors.onSurfaceVariant),
        selectedIcon: SvgIcon(
          iconName: selectedIconName,
          color: AppColors.primary,
        ),
        label: label,
      ),
    );
  }
}
