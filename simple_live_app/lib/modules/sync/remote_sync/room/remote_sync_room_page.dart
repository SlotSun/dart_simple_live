import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/sync/remote_sync/room/remote_sync_room_controller.dart';
import 'package:simple_live_app/services/signalr_service.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';

class RemoteSyncRoomPage extends GetView<RemoteSyncRoomController> {
  const RemoteSyncRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("数据同步"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: StreamBuilder<SignalRConnectionState>(
              stream: controller.signalR.stateStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                switch (snapshot.data) {
                  case SignalRConnectionState.connected:
                    return const _ConnectionStatus(
                      icon: Icons.check_circle_outline_rounded,
                      label: '已连接',
                      state: _ConnectionVisualState.connected,
                    );
                  case SignalRConnectionState.disconnected:
                    return const _ConnectionStatus(
                      icon: Icons.error_outline_rounded,
                      label: '断开连接',
                      state: _ConnectionVisualState.disconnected,
                    );
                  default:
                    return const _ConnectionStatus(
                      icon: Icons.sync_rounded,
                      label: '连接中',
                      state: _ConnectionVisualState.connecting,
                    );
                }
              },
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
          Visibility(
            visible: controller.roomId.isEmpty,
            child: SettingsCard(
              child: ListTile(
                visualDensity: VisualDensity.compact,
                leading: const Icon(Remix.timer_line),
                title: Obx(
                  () => Text(
                    "${controller.countDown.value}秒后房间将会自动关闭",
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: AppStyle.edgeInsetsA12,
            child: Text(
              "房间号",
              style: Get.textTheme.titleSmall,
            ),
          ),
          SettingsCard(
            child: Obx(
              () => ListTile(
                contentPadding: AppStyle.edgeInsetsL12,
                title: SelectableText(
                  controller.currentRoomId.value,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                trailing: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        size: 20,
                      ),
                      onPressed: () {
                        Utils.copyToClipboard(controller.currentRoomId.value);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.qr_code,
                        size: 20,
                      ),
                      onPressed: () {
                        controller.showQRInfo();
                      },
                    ),
                    AppStyle.hGap4,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: AppStyle.edgeInsetsA12.copyWith(top: 12),
            child: Text(
              "同步数据至其他设备",
              style: Get.textTheme.titleSmall,
            ),
          ),
          SettingsCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Remix.heart_line),
                  title: const Text("发送关注列表"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    controller.syncFollow();
                  },
                ),
                AppStyle.divider,
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text("发送观看记录"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    controller.syncHistory();
                  },
                ),
                AppStyle.divider,
                ListTile(
                  leading: const Icon(Remix.shield_keyhole_line),
                  title: const Text("发送弹幕屏蔽词"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    controller.syncBlockedWord();
                  },
                ),
                AppStyle.divider,
                ListTile(
                  leading: const Icon(Remix.account_circle_line),
                  title: const Text("发送哔哩哔哩账号"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    controller.syncBiliAccount();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: AppStyle.edgeInsetsA12.copyWith(top: 12),
            child: Text(
              "已连接设备",
              style: Get.textTheme.titleSmall,
            ),
          ),
          SettingsCard(
            child: Obx(
              () => ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: controller.roomUsers.length,
                shrinkWrap: true,
                separatorBuilder: (context, index) => AppStyle.divider,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  final user = controller.roomUsers[index];
                  final semantic = context.appTheme;
                  final theme = Theme.of(context);
                  return ListTile(
                    visualDensity: VisualDensity.compact,
                    leading: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: buildIcon(user.platform),
                      ),
                    ),
                    title: Text.rich(
                      TextSpan(
                        text: user.shortId,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: semantic.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        children: user.isCreator!
                            ? [
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Container(
                                    margin: AppStyle.edgeInsetsL4,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withAlpha(18),
                                      border: Border.all(
                                        color: theme.colorScheme.primary.withAlpha(54),
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppDesignTokens.radius6,
                                      ),
                                    ),
                                    child: Text(
                                      "创建者",
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ]
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      "${user.app} - v${user.version}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: semantic.textSecondary,
                      ),
                    ),
                    trailing: Visibility(
                      visible: controller.signalR.hubConnection?.connectionId ==
                          user.connectionId,
                      child: const Text(
                        "本机",
                      ),
                    ),
                  );
                },
              ),
            ),
          )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildIcon(String platform) {
    if (platform == "android") {
      return const Icon(Remix.android_line);
    } else if (platform == "ios") {
      return const Icon(Remix.apple_line);
    } else if (platform == "tv") {
      return const Icon(Remix.tv_2_line);
    } else if (platform == "windows") {
      return const Icon(Remix.microsoft_fill);
    } else if (platform == "xbox") {
      return const Icon(Remix.xbox_line);
    } else if (platform == "macos") {
      return const Icon(Remix.mac_line);
    } else if (platform == "linux") {
      return const Icon(Remix.ubuntu_line);
    } else {
      return const Icon(Remix.device_line);
    }
  }
}

enum _ConnectionVisualState { connected, disconnected, connecting }

class _ConnectionStatus extends StatelessWidget {
  const _ConnectionStatus({
    required this.icon,
    required this.label,
    required this.state,
  });

  final IconData icon;
  final String label;
  final _ConnectionVisualState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;
    final color = switch (state) {
      _ConnectionVisualState.connected => theme.colorScheme.primary,
      _ConnectionVisualState.disconnected => theme.colorScheme.error,
      _ConnectionVisualState.connecting => semantic.textSecondary,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state == _ConnectionVisualState.connecting)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        else
          Icon(icon, size: 18, color: color),
        const SizedBox(width: AppDesignTokens.space4),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
