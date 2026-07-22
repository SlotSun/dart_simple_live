import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/modules/sync/local_sync/local_sync_controller.dart';
import 'package:simple_live_app/services/sync_service.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';

class LocalSyncPage extends GetView<LocalSyncController> {
  const LocalSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('局域网数据同步'),
        actions: [
          TextButton.icon(
            onPressed: controller.showInfo,
            icon: const Icon(Icons.qr_code_rounded),
            label: const Text('本机信息'),
          ),
          const SizedBox(width: AppDesignTokens.space8),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              const _SectionHeading(title: '手动连接'),
              SettingsCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppDesignTokens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: controller.addressController,
                        onSubmitted: (_) => controller.connect(),
                        decoration: InputDecoration(
                          labelText: '客户端地址',
                          hintText: '请输入地址或扫码自动填写',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lan_outlined),
                          suffixIcon: Visibility(
                            visible: Platform.isAndroid || Platform.isIOS,
                            child: IconButton(
                              onPressed: controller.toScanQr,
                              tooltip: '扫一扫',
                              icon: const Icon(Remix.qr_scan_line),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDesignTokens.space12),
                      FilledButton.icon(
                        onPressed: controller.connect,
                        icon: const Icon(Icons.link_rounded),
                        label: const Text('连接'),
                      ),
                    ],
                  ),
                ),
              ),
              Obx(
                () => _SectionHeading(
                  title: '已发现设备 (${SyncService.instance.scanClients.length})',
                  top: 24,
                  trailing: IconButton(
                    onPressed: SyncService.instance.refreshClients,
                    tooltip: '重新扫描',
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
              ),
              SettingsCard(
                child: Obx(
                  () => SyncService.instance.scanClients.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.devices_other_outlined,
                                color: semantic.textTertiary,
                              ),
                              const SizedBox(height: AppDesignTokens.space8),
                              Text(
                                '暂未发现设备',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: semantic.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (_, __) => AppStyle.divider,
                          itemCount: SyncService.instance.scanClients.length,
                          itemBuilder: (_, index) {
                            final client =
                                SyncService.instance.scanClients[index];
                            return ListTile(
                              visualDensity: VisualDensity.compact,
                              contentPadding: const EdgeInsets.only(
                                left: 16,
                                right: 12,
                              ),
                              leading: Icon(
                                Icons.devices_rounded,
                                color: semantic.textSecondary,
                              ),
                              title: Text(
                                client.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: semantic.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                client.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: semantic.textSecondary,
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: semantic.textTertiary,
                              ),
                              onTap: () => controller.connectClient(client),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: AppDesignTokens.space12),
              Text(
                '如果无法扫描到设备，请手动输入地址。',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: semantic.textTertiary,
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
  const _SectionHeading({
    required this.title,
    this.top = 0,
    this.trailing,
  });

  final String title;
  final double top;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final semantic = context.appTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(4, top, 4, AppDesignTokens.space8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: semantic.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
