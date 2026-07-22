import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/services/signalr_service.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Get.isDarkMode
          ? SystemUiOverlayStyle.light.copyWith(
              systemNavigationBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              systemNavigationBarColor: Colors.transparent,
            ),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '我的',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: semantic.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: AppDesignTokens.space16),
                SettingsCard(
                  child: InkWell(
                    onTap: () => _showAboutDialog(context),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDesignTokens.space16),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: semantic.elevatedSurface,
                              borderRadius: BorderRadius.circular(
                                AppDesignTokens.radius16,
                              ),
                              border: Border.all(color: semantic.border),
                            ),
                            child: Image.asset('assets/images/logo.png'),
                          ),
                          const SizedBox(width: AppDesignTokens.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Slive',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: semantic.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: AppDesignTokens.space4),
                                Text(
                                  '我就默默看你表演',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: semantic.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppDesignTokens.space8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(18),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Ver ${Utils.packageInfo.version}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: semantic.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const _SectionHeading(title: '内容', top: 24),
                SettingsCard(
                  child: _MineTile(
                    icon: Remix.history_line,
                    title: '观看记录',
                    subtitle: '查看最近访问的直播间',
                    onTap: () => Get.toNamed(RoutePath.kHistory),
                  ),
                ),
                const _SectionHeading(title: '账号与数据', top: 24),
                SettingsCard(
                  child: Column(
                    children: [
                      _MineTile(
                        icon: Remix.account_circle_line,
                        title: '账号管理',
                        onTap: () => Get.toNamed(RoutePath.kSettingsAccount),
                      ),
                      AppStyle.divider,
                      _MineTile(
                        icon: Icons.devices_rounded,
                        title: '数据同步',
                        onTap: () => Get.toNamed(RoutePath.kSync),
                      ),
                      AppStyle.divider,
                      _MineTile(
                        icon: Remix.link,
                        title: '链接解析',
                        onTap: () => Get.toNamed(RoutePath.kTools),
                      ),
                    ],
                  ),
                ),
                const _SectionHeading(title: '设置', top: 24),
                SettingsCard(
                  child: Column(
                    children: [
                      _MineTile(
                        icon: Remix.moon_line,
                        title: '外观设置',
                        onTap: () => Get.toNamed(RoutePath.kAppstyleSetting),
                      ),
                      AppStyle.divider,
                      _MineTile(
                        icon: Remix.home_2_line,
                        title: '主页设置',
                        onTap: () => Get.toNamed(RoutePath.kSettingsIndexed),
                      ),
                      AppStyle.divider,
                      _MineTile(
                        icon: Remix.play_circle_line,
                        title: '直播设置',
                        onTap: () => Get.toNamed(RoutePath.kSettingsPlay),
                      ),
                      AppStyle.divider,
                      _MineTile(
                        icon: Remix.text,
                        title: '弹幕设置',
                        onTap: () => Get.toNamed(RoutePath.kSettingsDanmu),
                      ),
                      AppStyle.divider,
                      _MineTile(
                        icon: Remix.timer_2_line,
                        title: '定时关闭',
                        onTap: () => Get.toNamed(RoutePath.kSettingsAutoExit),
                      ),
                      AppStyle.divider,
                      _MineTile(
                        icon: Remix.apps_line,
                        title: '其他设置',
                        onTap: () => Get.toNamed(RoutePath.kSettingsOther),
                      ),
                      if (kDebugMode) AppStyle.divider,
                      if (kDebugMode)
                        _MineTile(
                          icon: Remix.bug_line,
                          title: '测试',
                          onTap: () async {
                            final signalRService = SignalRService();
                            await signalRService.connect();
                            final room = await signalRService.createRoom();
                            Log.logPrint(room);
                          },
                        ),
                    ],
                  ),
                ),
                const _SectionHeading(title: '关于', top: 24),
                SettingsCard(
                  child: Column(
                    children: [
                      const _MineTile(
                        icon: Remix.error_warning_line,
                        title: '免责声明',
                        onTap: Utils.showStatement,
                      ),
                      AppStyle.divider,
                      _MineTile(
                        icon: Remix.github_line,
                        title: '开源主页',
                        onTap: () {
                          launchUrlString(
                            'https://github.com/slotsun/dart_simple_live',
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                      AppStyle.divider,
                      _MineTile(
                        icon: Remix.upload_2_line,
                        title: '检查更新',
                        value: 'Ver ${Utils.packageInfo.version}',
                        onTap: () => Utils.checkUpdate(showMsg: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    Get.dialog(
      AboutDialog(
        applicationIcon: Image.asset(
          'assets/images/logo.png',
          width: 48,
          height: 48,
        ),
        applicationName: 'Slive',
        applicationVersion: '我就默默看你表演',
        applicationLegalese: 'Ver ${Utils.packageInfo.version}',
      ),
    );
  }
}

class _MineTile extends StatelessWidget {
  const _MineTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.value,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;
    return ListTile(
      visualDensity: VisualDensity.compact,
      minVerticalPadding: 10,
      contentPadding: const EdgeInsets.only(left: 16, right: 12),
      leading: Icon(icon, color: semantic.textSecondary),
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: semantic.textSecondary,
                ),
              ),
            ),
          if (value != null) const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: semantic.textTertiary),
        ],
      ),
      onTap: onTap,
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
