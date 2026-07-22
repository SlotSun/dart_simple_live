import 'package:flutter/material.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';

class AppLoaddingWidget extends StatelessWidget {
  const AppLoaddingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.appTheme;
    final theme = Theme.of(context);

    return Center(
      child: Semantics(
        container: true,
        label: '正在加载',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: semantic.elevatedSurface,
            borderRadius: BorderRadius.circular(AppDesignTokens.radius16),
            border: Border.all(color: semantic.border),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                offset: const Offset(0, 4),
                color: semantic.shadow,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '正在加载',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: semantic.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
