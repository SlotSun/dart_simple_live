import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/widgets/settings/settings_tile.dart';

class SettingsNumber extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String unit;
  final int value;
  final int step;
  final int min;
  final int max;
  final String? displayValue;
  final Function(int)? onChanged;

  const SettingsNumber({
    required this.title,
    required this.value,
    required this.max,
    this.subtitle,
    this.onChanged,
    this.step = 1,
    this.min = 0,
    this.unit = '',
    this.displayValue,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.appTheme;
    final theme = Theme.of(context);

    return SettingsTile(
      title: title,
      subtitle: subtitle,
      trailing: Container(
        height: 44,
        decoration: BoxDecoration(
          color: semantic.elevatedSurface,
          borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
          border: Border.all(color: semantic.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              padding: EdgeInsets.zero,
              tooltip: '减少',
              onPressed: () {
                var newValue = value - step;
                if (newValue < min) {
                  newValue = min;
                }
                onChanged?.call(newValue);
              },
              icon: Icon(
                Icons.remove_rounded,
                size: 18,
                color: semantic.textSecondary,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, maxWidth: 88),
              child: Text(
                displayValue ?? '$value$unit',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: semantic.textPrimary,
                ),
              ),
            ),
            IconButton(
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              padding: EdgeInsets.zero,
              tooltip: '增加',
              onPressed: () {
                var newValue = value + step;
                if (newValue > max) {
                  newValue = max;
                }
                onChanged?.call(newValue);
              },
              icon: Icon(
                Icons.add_rounded,
                size: 18,
                color: semantic.textSecondary,
              ),
            ),
          ],
        ),
      ),
      onTap: () => openSilder(context),
    );
  }

  void openSilder(BuildContext context) {
    final newValue = value.obs;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Obx(
                    () => Text(
                      '${newValue.value}$unit',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Obx(
                () => Slider(
                  value: newValue.value.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  onChanged: (sliderValue) {
                    newValue.value = sliderValue.toInt();
                  },
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  onChanged?.call(newValue.value);
                  Get.back();
                },
                child: const Text('确定'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
