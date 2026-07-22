import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/sync/remote_sync/webdav/remote_sync_webdav_controller.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';

class RemoteSyncWebDAVPage extends GetView<RemoteSyncWebDAVController> {
  const RemoteSyncWebDAVPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebDAV同步')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              const _SectionHeading(title: '账号与备份'),
              SettingsCard(
                child: Obx(
                  () => Column(
                    children: controller.notLogin.value
                        ? [
                            SettingsAction(
                              title: '点击登录',
                              subtitle: '登录后可以同步您的所有数据',
                              leading: const Icon(Icons.login_rounded),
                              onTap: () => Get.toNamed(
                                RoutePath.kRemoteSyncWebDavConfig,
                              ),
                            ),
                          ]
                        : [
                            _SyncActionTile(
                              title: '已登录',
                              subtitle: controller.user.value,
                              leading: const Icon(
                                Icons.cloud_circle_outlined,
                              ),
                              trailing: const Icon(Icons.logout_rounded),
                              onTap: controller.onLogout,
                            ),
                            AppStyle.divider,
                            SettingsAction(
                              title: '云端备份目录',
                              value: controller.webDavBackupDirectory.value,
                              leading: const Icon(Icons.drive_folder_upload),
                              onTap: _showEditBackupDirectory,
                            ),
                            AppStyle.divider,
                            SettingsAction(
                              title: '上传到云端',
                              subtitle:
                                  '上次上传：${controller.lastUploadTime.value}',
                              leading: const Icon(Icons.cloud_upload_outlined),
                              onTap: controller.doWebDAVUpload,
                            ),
                            AppStyle.divider,
                            _SyncActionTile(
                              title: '恢复到本地',
                              subtitle:
                                  '上次恢复：${controller.lastRecoverTime.value}',
                              leading: const Icon(Icons.cloud_download_outlined),
                              showSettings: true,
                              onSettings: showSetting,
                              onTap: controller.doWebDAVRecovery,
                              onLongPress: showSetting,
                            ),
                            AppStyle.divider,
                            _SyncActionTile(
                              title: '双向同步数据',
                              subtitle:
                                  '上次同步：${controller.lastRecoverTime.value}',
                              leading: const Icon(Icons.cloud_sync_outlined),
                              onTap: controller.doWebDAVBidirectional,
                              onLongPress: showSetting,
                            ),
                          ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showSetting() {
    Utils.showBottomSheet(
      title: '同步选项',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => CheckboxListTile(
              secondary: const Icon(Remix.heart_line),
              title: const Text('同步关注列表'),
              value: controller.isSyncFollows.value,
              controlAffinity: ListTileControlAffinity.trailing,
              onChanged: (_) => controller.changeIsSyncFollows(),
            ),
          ),
          AppStyle.divider,
          Obx(
            () => CheckboxListTile(
              secondary: const Icon(Icons.history_rounded),
              title: const Text('同步播放历史记录'),
              value: controller.isSyncHistories.value,
              controlAffinity: ListTileControlAffinity.trailing,
              onChanged: (_) => controller.changeIsSyncHistories(),
            ),
          ),
          AppStyle.divider,
          Obx(
            () => CheckboxListTile(
              secondary: const Icon(Remix.shield_keyhole_line),
              title: const Text('同步屏蔽字'),
              value: controller.isSyncBlockWord.value,
              controlAffinity: ListTileControlAffinity.trailing,
              onChanged: (_) => controller.changeIsSyncBlockWord(),
            ),
          ),
          AppStyle.divider,
          Obx(
            () => CheckboxListTile(
              secondary: const Icon(Remix.account_circle_line),
              title: const Text('同步用户平台账号'),
              value: controller.isSyncAccount.value,
              controlAffinity: ListTileControlAffinity.trailing,
              onChanged: (_) => controller.changeIsSyncAccount(),
            ),
          ),
          AppStyle.divider,
          Obx(
            () => CheckboxListTile(
              secondary: const Icon(Remix.user_settings_line),
              title: const Text('同步用户设置'),
              value: controller.isSyncSetting.value,
              controlAffinity: ListTileControlAffinity.trailing,
              onChanged: (_) => controller.changeIsSyncSetting(),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditBackupDirectory() async {
    final directory = await Utils.showEditTextDialog(
      controller.webDavBackupDirectory.value,
      title: '修改远程备份文件夹',
    );
    if (directory == null || directory.isEmpty) return;
    controller.setWebDavBackupDirectory(newDirectory: directory);
  }
}

class _SyncActionTile extends StatelessWidget {
  const _SyncActionTile({
    required this.title,
    required this.leading,
    this.subtitle,
    this.trailing,
    this.showSettings = false,
    this.onTap,
    this.onLongPress,
    this.onSettings,
  });

  final String title;
  final String? subtitle;
  final Widget leading;
  final Widget? trailing;
  final bool showSettings;
  final Function()? onTap;
  final Function()? onLongPress;
  final Function()? onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;
    return ListTile(
      visualDensity: VisualDensity.compact,
      minVerticalPadding: 10,
      contentPadding: const EdgeInsets.only(left: 16, right: 8),
      leading: leading,
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: semantic.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: semantic.textSecondary,
              ),
            ),
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSettings)
                IconButton(
                  tooltip: '同步选项',
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings_outlined),
                ),
              Icon(
                Icons.chevron_right_rounded,
                color: semantic.textTertiary,
              ),
            ],
          ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
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
