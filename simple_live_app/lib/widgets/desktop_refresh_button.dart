import 'package:flutter/material.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';

class DesktopRefreshButton extends StatelessWidget {
  final bool refreshing;
  final Function()? onPressed;

  const DesktopRefreshButton({
    required this.refreshing,
    this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.appTheme;
    final theme = Theme.of(context);

    return Material(
      color: semantic.elevatedSurface,
      elevation: 0,
      shadowColor: semantic.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        side: BorderSide(color: semantic.border),
      ),
      child: SizedBox.square(
        dimension: 44,
        child: refreshing
            ? Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                    semanticsLabel: '正在刷新',
                  ),
                ),
              )
            : IconButton(
                onPressed: onPressed,
                tooltip: '刷新',
                icon: const Icon(Icons.refresh_rounded),
              ),
      ),
    );
  }
}
