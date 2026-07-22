import 'package:flutter/material.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';

class SettingsCard extends StatelessWidget {
  final Widget child;

  const SettingsCard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.appTheme;

    return Material(
      color: semantic.secondarySurface,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radius16),
        side: BorderSide(color: semantic.border),
      ),
      child: child,
    );
  }
}
