import 'package:flutter/material.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.appTheme;
    final theme = Theme.of(context);

    return ListTile(
      visualDensity: VisualDensity.compact,
      minVerticalPadding: 10,
      leading: leading,
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
      trailing: trailing,
      contentPadding: const EdgeInsets.only(left: 16, right: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
      ),
      onTap: onTap,
    );
  }
}

class SettingsValueIndicator extends StatelessWidget {
  const SettingsValueIndicator({
    this.value,
    this.showChevron = true,
    super.key,
  });

  final String? value;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final semantic = context.appTheme;
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              value!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: semantic.textSecondary,
              ),
            ),
          ),
        if (value != null && showChevron) const SizedBox(width: 4),
        if (showChevron)
          Icon(
            Icons.chevron_right_rounded,
            color: semantic.textTertiary,
          ),
      ],
    );
  }
}
