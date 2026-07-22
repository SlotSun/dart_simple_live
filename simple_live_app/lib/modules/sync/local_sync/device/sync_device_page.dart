import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/modules/sync/local_sync/device/sync_device_controller.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';

class SyncDevicePage extends GetView<SyncDeviceController> {
  const SyncDevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('同步')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              SettingsCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppDesignTokens.space16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(18),
                          borderRadius: BorderRadius.circular(
                            AppDesignTokens.radius12,
                          ),
                        ),
                        child: IconTheme(
                          data: IconThemeData(
                            color: theme.colorScheme.primary,
                            size: 26,
                          ),
                          child: buildIcon(),
                        ),
                      ),
                      const SizedBox(width: AppDesignTokens.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.info.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: semantic.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppDesignTokens.space4),
                            Text(
                              '${controller.info.type.toUpperCase()} · ${controller.info.address}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: semantic.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const _SectionHeading(title: '发送到此设备', top: 24),
              SettingsCard(
                child: Column(
                  children: [
                    SettingsAction(
                      leading: const Icon(Remix.heart_line),
                      title: '同步关注列表',
                      onTap: controller.syncFollowAndTag,
                    ),
                    AppStyle.divider,
                    SettingsAction(
                      leading: const Icon(Icons.history_rounded),
                      title: '同步观看记录',
                      onTap: controller.syncHistory,
                    ),
                    AppStyle.divider,
                    SettingsAction(
                      leading: const Icon(Remix.shield_keyhole_line),
                      title: '同步弹幕屏蔽词',
                      onTap: controller.syncBlockedWord,
                    ),
                    AppStyle.divider,
                    SettingsAction(
                      leading: const Icon(Remix.account_circle_line),
                      title: '同步哔哩哔哩账号',
                      onTap: controller.syncBiliAccount,
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

  Widget buildIcon() {
    final icon = controller.info.type.toLowerCase();
    if (icon == 'android') return const Icon(Remix.android_line);
    if (icon == 'ios') return const Icon(Remix.apple_line);
    if (icon == 'tv') return const Icon(Remix.tv_2_line);
    if (icon == 'windows') return const Icon(Remix.microsoft_fill);
    if (icon == 'macos') return const Icon(Remix.mac_line);
    if (icon == 'linux') return const Icon(Remix.ubuntu_line);
    return const Icon(Remix.device_line);
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
