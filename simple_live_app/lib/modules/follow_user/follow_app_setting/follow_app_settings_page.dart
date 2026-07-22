import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/modules/follow_user/follow_app_setting/follow_app_settings_controller.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_menu_check.dart';
import 'package:simple_live_app/widgets/settings/settings_number.dart';
import 'package:simple_live_app/widgets/settings/settings_switch.dart';

class FollowSettingsPage extends GetView<FollowAppSettingsController> {
  const FollowSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关注设置')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              const _SectionHeading(title: '标签管理'),
              SettingsCard(
                child: SettingsAction(
                  title: '标签管理',
                  subtitle: '添加、重命名或调整自定义标签顺序',
                  onTap: controller.showTagsManager,
                ),
              ),
              const _SectionHeading(title: '关注清理功能', top: 24),
              SettingsCard(
                child: SettingsMenuCheck<FollowUser>(
                  title: '选择要清理的用户',
                  subtitle: '默认条件为：观看时长低于30分钟，历史观看底部15',
                  confirmText: '清理',
                  itemToString: (user) => user.userName,
                  itemsProvider: () async => controller.buildAutoCleanPool(),
                  onConfirm: controller.cleanFollow,
                ),
              ),
              const _SectionHeading(title: '其他设置', top: 24),
              SettingsCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(
                      () => SettingsSwitch(
                        value: controller.appC.hideOfflineFollow.value,
                        title: '隐藏离线关注',
                        onChanged: controller.setFollowSetting,
                      ),
                    ),
                    AppStyle.divider,
                    Obx(
                      () => SettingsSwitch(
                        value: controller.appC.hideRemoveFollowButton.value,
                        title: '隐藏快速取关按钮',
                        onChanged: controller.setRemoveFollowButton,
                      ),
                    ),
                    AppStyle.divider,
                    Obx(
                      () => SettingsSwitch(
                        value: controller.appC.followSnapshotEnable.value,
                        title: '直播状态快照',
                        subtitle: '恢复短时间内直播状态，降低风控风险',
                        onChanged: controller.appC.setFollowSnapshotEnable,
                      ),
                    ),
                  ],
                ),
              ),
              const _SectionHeading(title: '自动更新设置', top: 24),
              SettingsCard(
                child: Column(
                  children: [
                    Obx(
                      () => SettingsSwitch(
                        value: controller.appC.autoUpdateFollowEnable.value,
                        title: '自动更新关注直播状态',
                        onChanged: (value) {
                          controller.appC.setAutoUpdateFollowEnable(value);
                          FollowService.instance.initTimer();
                        },
                      ),
                    ),
                    Obx(
                      () => Visibility(
                        visible: controller.appC.autoUpdateFollowEnable.value,
                        child: AppStyle.divider,
                      ),
                    ),
                    Obx(
                      () => Visibility(
                        visible: controller.appC.autoUpdateFollowEnable.value,
                        child: SettingsAction(
                          title: '自动更新间隔',
                          value:
                              '${controller.appC.autoUpdateFollowDuration.value ~/ 60}小时${controller.appC.autoUpdateFollowDuration.value % 60}分钟',
                          onTap: () => setTimer(context),
                        ),
                      ),
                    ),
                    AppStyle.divider,
                    Obx(
                      () => SettingsNumber(
                        value: controller.appC.updateFollowThreadCount.value,
                        title: '更新线程数',
                        subtitle: '多线程可以更快完成加载，但请求过于频繁可能导致状态读取失败',
                        min: 1,
                        max: 12,
                        onChanged: controller.appC.setUpdateFollowThreadCount,
                      ),
                    ),
                  ],
                ),
              ),
              const _SectionHeading(title: '关注导入导出', top: 24),
              _fileImportAndExportBuild(),
              const _SectionHeading(title: '数据校准', top: 24),
              SettingsCard(
                child: SettingsAction(
                  title: '数据校准',
                  subtitle: '关注以及标签数据错乱时可进行校准，请勿重复点击',
                  onTap: controller.followDataCheck,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fileImportAndExportBuild() {
    return SettingsCard(
      child: Column(
        children: [
          SettingsAction(
            leading: const Icon(Remix.save_2_line),
            title: '导出文件',
            onTap: FollowService.instance.exportFile,
          ),
          AppStyle.divider,
          SettingsAction(
            leading: const Icon(Remix.folder_open_line),
            title: '导入文件',
            onTap: FollowService.instance.inputFile,
          ),
          AppStyle.divider,
          SettingsAction(
            leading: const Icon(Remix.text),
            title: '导出文本',
            onTap: FollowService.instance.exportText,
          ),
          AppStyle.divider,
          SettingsAction(
            leading: const Icon(Remix.file_text_line),
            title: '导入文本',
            onTap: FollowService.instance.inputText,
          ),
        ],
      ),
    );
  }

  void setTimer(BuildContext context) async {
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: controller.appC.autoUpdateFollowDuration.value ~/ 60,
        minute: controller.appC.autoUpdateFollowDuration.value % 60,
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
    controller.appC.setAutoUpdateFollowDuration(duration.inMinutes);
    FollowService.instance.initTimer();
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
