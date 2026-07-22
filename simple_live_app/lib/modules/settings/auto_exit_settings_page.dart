import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_switch.dart';

class AutoExitSettingsPage extends GetView<AppSettingsController> {
  const AutoExitSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('定时关闭设置')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              const _SectionHeading(title: '自动关闭'),
              SettingsCard(
                child: Column(
                  children: [
                    Obx(
                      () => SettingsSwitch(
                        value: controller.autoExitEnable.value,
                        title: '启用定时关闭',
                        subtitle: '进入直播间后开始计时',
                        onChanged: controller.setAutoExitEnable,
                      ),
                    ),
                    Obx(
                      () => Visibility(
                        visible: controller.autoExitEnable.value,
                        child: AppStyle.divider,
                      ),
                    ),
                    Obx(
                      () => Visibility(
                        visible: controller.autoExitEnable.value,
                        child: SettingsAction(
                          title: '自动关闭时间',
                          value:
                              '${controller.autoExitDuration.value ~/ 60}小时${controller.autoExitDuration.value % 60}分钟',
                          subtitle: '从进入直播间开始倒计时',
                          onTap: () => setTimer(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void setTimer(BuildContext context) async {
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: controller.autoExitDuration.value ~/ 60,
        minute: controller.autoExitDuration.value % 60,
      ),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      builder: (_, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (value == null || (value.hour == 0 && value.minute == 0)) return;
    final duration = Duration(hours: value.hour, minutes: value.minute);
    controller.setAutoExitDuration(duration.inMinutes);
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final semantic = context.appTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, AppDesignTokens.space8),
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
