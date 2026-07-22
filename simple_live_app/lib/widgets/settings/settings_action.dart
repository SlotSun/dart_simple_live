import 'package:flutter/material.dart';
import 'package:simple_live_app/widgets/settings/settings_tile.dart';

class SettingsAction extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Function()? onTap;
  final String? value;
  final Widget? leading;

  const SettingsAction({
    required this.title,
    this.value,
    this.onTap,
    this.subtitle,
    this.leading,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: SettingsValueIndicator(value: value),
      onTap: onTap,
    );
  }
}
