import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/widgets/settings/settings_tile.dart';

class SettingsMenu<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Map<T, String> valueMap;
  final T value;
  final Widget? trailing;
  final Function(T)? onChanged;

  const SettingsMenu({
    required this.title,
    required this.value,
    required this.valueMap,
    this.subtitle,
    this.onChanged,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: title,
      subtitle: subtitle,
      trailing: trailing ?? SettingsValueIndicator(value: valueMap[value]!.tr),
      onTap: () => openMenu(context),
    );
  }

  void openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 8),
          child: RadioGroup(
            groupValue: value,
            onChanged: (selectedValue) {
              Get.back();
              onChanged?.call(selectedValue as T);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: valueMap.keys
                  .map(
                    (menuValue) => RadioListTile(
                      value: menuValue,
                      title: Text((valueMap[menuValue]?.tr) ?? '???'),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
