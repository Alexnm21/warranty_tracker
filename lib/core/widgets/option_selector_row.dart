import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

class OptionSelectorRow extends StatefulWidget {
  final List<String> options;
  final Function(String) onOptionSelected;

  /// Optional controlled selection.
  ///
  /// When provided it takes precedence over the internal selection, so the
  /// parent decides when a tap becomes effective (e.g. to ignore a cancelled
  /// date picker).
  final String? selectedOption;

  const OptionSelectorRow({
    super.key,
    required this.options,
    required this.onOptionSelected,
    this.selectedOption,
  });

  @override
  State<OptionSelectorRow> createState() => _OptionSelectorRowState();
}

class _OptionSelectorRowState extends State<OptionSelectorRow> {
  String _selectedOption = '';

  @override
  void initState() {
    _selectedOption = widget.selectedOption ?? widget.options.first;
    super.initState();
  }

  String get _effectiveSelectedOption =>
      widget.selectedOption ?? _selectedOption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.base),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: widget.options
            .map(
              (option) => _OptionContainer(
                text: option,
                selected: option == _effectiveSelectedOption,
                onTap: () {
                  setState(() {
                    _selectedOption = option;
                  });
                  widget.onOptionSelected(option);
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

class _OptionContainer extends StatelessWidget {
  final String text;
  final bool selected;
  final Function() onTap;
  const _OptionContainer({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          margin: EdgeInsets.symmetric(horizontal: AppRadii.sm),
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? AppColors.onPrimary : null,
            borderRadius: BorderRadius.circular(AppRadii.base),
          ),
          child: Center(
            child: Text(
              text,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected
                    ? AppColors.onPrimaryContainer
                    : AppColors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
