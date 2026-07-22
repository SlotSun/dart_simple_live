import 'package:flutter/material.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';

class SettingsSwitch extends StatelessWidget {
  final bool value;
  final String title;
  final String? subtitle;
  final Function(bool) onChanged;

  const SettingsSwitch({
    required this.value,
    required this.title,
    this.subtitle,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.appTheme;
    final theme = Theme.of(context);

    return SwitchListTile(
      visualDensity: VisualDensity.compact,
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: semantic.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: semantic.textSecondary,
                ),
              ),
            ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
      ),
      contentPadding: const EdgeInsets.only(left: 16, right: 8),
      value: value,
      onChanged: onChanged,
    );
  }
}
