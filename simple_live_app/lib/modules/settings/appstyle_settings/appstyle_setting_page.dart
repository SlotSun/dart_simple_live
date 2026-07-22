import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/modules/settings/appstyle_settings/appstyle_setting_contorller.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_menu.dart';
import 'package:simple_live_app/widgets/settings/settings_switch.dart';

class AppStyleSettingPage extends GetView<AppStyleSettingController> {
  const AppStyleSettingPage({super.key});

  Widget _fontActions({required Widget primaryAction}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: controller.fontReset,
          tooltip: '重置为默认字体',
          icon: const Icon(Icons.settings_backup_restore_outlined),
        ),
        if (controller.fontState.value == DownloadState.downloaded)
          IconButton(
            onPressed: controller.fontDelete,
            tooltip: '删除字体',
            icon: const Icon(Icons.delete_outline_outlined),
          ),
        primaryAction,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('外观设置')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              const _SectionHeading(title: '显示主题'),
              SettingsCard(
                child: Obx(
                  () => RadioGroup<int>(
                    groupValue: controller.themeMode.value,
                    onChanged: (value) => controller.setTheme(value ?? 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        RadioListTile<int>(
                          title: Text('跟随系统'),
                          visualDensity: VisualDensity.compact,
                          value: 0,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        RadioListTile<int>(
                          title: Text('浅色模式'),
                          visualDensity: VisualDensity.compact,
                          value: 1,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        RadioListTile<int>(
                          title: Text('深色模式'),
                          visualDensity: VisualDensity.compact,
                          value: 2,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const _SectionHeading(title: '主题颜色', top: 24),
              SettingsCard(
                child: Obx(
                  () => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SettingsSwitch(
                        value: controller.isDynamic.value,
                        title: '动态取色',
                        subtitle: '使用系统提供的动态配色方案',
                        onChanged: (value) {
                          controller.setIsDynamic(value);
                          Get.forceAppUpdate();
                        },
                      ),
                      if (!controller.isDynamic.value) AppStyle.divider,
                      if (!controller.isDynamic.value)
                        Padding(
                          padding: const EdgeInsets.all(AppDesignTokens.space16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: AppDesignTokens.space12,
                              runSpacing: AppDesignTokens.space12,
                              children: <Color>[
                                const Color(0xffEF5350),
                                const Color(0xff3498DB),
                                AppColors.defaultSeedColor,
                                const Color(0xffF06292),
                                const Color(0xff9575CD),
                                const Color(0xff26C6DA),
                                const Color(0xff26A69A),
                                const Color(0xffFFF176),
                                const Color(0xffFF9800),
                              ].map((color) {
                                final selected =
                                    controller.styleColor.value == color.v;
                                final brightness =
                                    ThemeData.estimateBrightnessForColor(color);
                                final foreground = ColorScheme.fromSeed(
                                  seedColor: color,
                                  brightness: brightness,
                                ).onPrimary;
                                return Semantics(
                                  button: true,
                                  selected: selected,
                                  label: '选择主题颜色',
                                  child: InkWell(
                                    onTap: () {
                                      controller.setStyleColor(color.v);
                                      Get.forceAppUpdate();
                                    },
                                    borderRadius: BorderRadius.circular(
                                      AppDesignTokens.radius12,
                                    ),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 160),
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(
                                          AppDesignTokens.radius12,
                                        ),
                                        border: Border.all(
                                          color: selected
                                              ? foreground
                                              : context.appTheme.border,
                                          width: selected ? 2 : 1,
                                        ),
                                      ),
                                      child: selected
                                          ? Icon(
                                              Icons.check_rounded,
                                              color: foreground,
                                            )
                                          : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const _SectionHeading(title: '字体设置', top: 24),
              SettingsCard(
                child: Obx(
                  () => SettingsMenu(
                    title: controller.curFontModel.value!.name,
                    value: controller.curFontModel.value!,
                    valueMap: controller.fontMap,
                    onChanged: controller.onFontSelected,
                    trailing: Obx(() {
                      switch (controller.fontState.value) {
                        case DownloadState.notDownloaded:
                          return _fontActions(
                            primaryAction: IconButton(
                              tooltip: '下载字体',
                              icon: const Icon(Icons.download_outlined),
                              onPressed: controller.downloadFont,
                            ),
                          );
                        case DownloadState.downloading:
                          return _fontActions(
                            primaryAction: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                          );
                        case DownloadState.downloaded:
                          return _fontActions(
                            primaryAction: IconButton(
                              tooltip: '应用字体',
                              icon: const Icon(
                                Icons.check_circle_outline_outlined,
                              ),
                              onPressed: controller.changeFontFamily,
                            ),
                          );
                      }
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.top = 0});

  final String title;
  final double top;

  @override
  Widget build(BuildContext context) {
    final semantic = context.appTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(4, top, 4, AppDesignTokens.space8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: semantic.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

extension ColorExt on Color {
  static int _floatToInt8(double x) {
    return (x * 255.0).round() & 0xff;
  }

  int get v =>
      _floatToInt8(a) << 24 |
      _floatToInt8(r) << 16 |
      _floatToInt8(g) << 8 |
      _floatToInt8(b);
}
