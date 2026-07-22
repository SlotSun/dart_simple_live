import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';

class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据同步'),
        actions: [
          Visibility(
            visible: GetPlatform.isAndroid || GetPlatform.isIOS,
            child: TextButton.icon(
              onPressed: () async {
                final result = await Get.toNamed(RoutePath.kSyncScan);
                if (result == null || result.isEmpty) return;
                if (result.length == 5) {
                  Get.toNamed(RoutePath.kRemoteSyncRoom, arguments: result);
                } else {
                  Get.toNamed(RoutePath.kLocalSync, arguments: result);
                }
              },
              icon: const Icon(Remix.qr_scan_line),
              label: const Text('扫一扫'),
            ),
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
              const _SectionHeading(title: '远程同步'),
              SettingsCard(
                child: SettingsAction(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: 'WebDAV',
                  subtitle: '通过 WebDAV 在不同设备间备份和恢复数据',
                  onTap: () => Get.toNamed(RoutePath.kRemoteSyncWebDav),
                ),
              ),
              const _SectionHeading(title: '局域网同步', top: 24),
              SettingsCard(
                child: SettingsAction(
                  leading: const Icon(Remix.device_line),
                  title: '局域网同步',
                  subtitle: '发现同一局域网内的 Slive 设备并发送数据',
                  onTap: () => Get.toNamed(RoutePath.kLocalSync),
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
