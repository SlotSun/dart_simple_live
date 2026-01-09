import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_switch.dart';

class AutoExitSettingsPage extends GetView<AppSettingsController> {
  const AutoExitSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("定时关闭设置"),
      ),
      body: ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          SettingsCard(
            child: Column(
              children: [
                Obx(
                  () => SettingsSwitch(
                    value: controller.autoExitEnable.value,
                    title: "启用定时关闭",
                    onChanged: (e) {
                      controller.setAutoExitEnable(e);
                    },
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
                      title: "自动关闭时间",
                      value:
                          "${controller.autoExitDuration.value ~/ 60}小时${controller.autoExitDuration.value % 60}分钟",
                      subtitle: "从进入直播间开始倒计时",
                      onTap: () {
                        setTimer(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SettingsCard(
            child: Column(
              children: [
                Obx(
                  () => SettingsSwitch(
                    value: controller.userActivityCheckEnable.value,
                    title: "启用用户活跃检测",
                    subtitle: "长时间未操作将自动关闭程序",
                    onChanged: (e) {
                      controller.setUserActivityCheckEnable(e);
                    },
                  ),
                ),
                Obx(
                  () => Visibility(
                    visible: controller.userActivityCheckEnable.value,
                    child: AppStyle.divider,
                  ),
                ),
                Obx(
                  () => Visibility(
                    visible: controller.userActivityCheckEnable.value,
                    child: SettingsAction(
                      title: "超时时间",
                      value:
                          "${controller.userActivityTimeout.value ~/ 60}小时${controller.userActivityTimeout.value % 60}分钟",
                      onTap: () {
                        setActivityTimer(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void setTimer(BuildContext context) async {
    var value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: controller.autoExitDuration.value ~/ 60,
        minute: controller.autoExitDuration.value % 60,
      ),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      builder: (_, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );
    if (value == null || (value.hour == 0 && value.minute == 0)) {
      return;
    }
    var duration = Duration(hours: value.hour, minutes: value.minute);
    controller.setAutoExitDuration(duration.inMinutes);
  }

  void setActivityTimer(BuildContext context) async {
    var value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: controller.userActivityTimeout.value ~/ 60,
        minute: controller.userActivityTimeout.value % 60,
      ),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      builder: (_, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );
    if (value == null || (value.hour == 0 && value.minute == 0)) {
      return;
    }
    var duration = Duration(hours: value.hour, minutes: value.minute);
    controller.setUserActivityTimeout(duration.inMinutes);
  }
}
