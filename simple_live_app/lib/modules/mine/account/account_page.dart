import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/mine/account/account_controller.dart';
import 'package:simple_live_app/services/bilibili_account_service.dart';
import 'package:simple_live_app/services/platform_service.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';

class AccountPage extends GetView<AccountController> {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('账号管理')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(AppDesignTokens.space16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(14),
                  borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(36),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppDesignTokens.space12),
                    Expanded(
                      child: Text(
                        '哔哩哔哩账号需要登录才能观看高清晰度直播，其他平台暂无此限制。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: semantic.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const _SectionHeading(title: '平台账号', top: 24),
              SettingsCard(
                child: Column(
                  children: [
                    Obx(
                      () => _AccountTile(
                        logo: 'assets/images/bilibili_2.png',
                        title: '哔哩哔哩',
                        subtitle: BiliBiliAccountService.instance.name.value,
                        trailing: BiliBiliAccountService.instance.logined.value
                            ? const Icon(Icons.logout_rounded)
                            : null,
                        onTap: controller.bilibiliTap,
                      ),
                    ),
                    AppStyle.divider,
                    const _AccountTile(
                      logo: 'assets/images/douyu.png',
                      title: '斗鱼直播',
                      subtitle: '无需登录',
                      enabled: false,
                    ),
                    AppStyle.divider,
                    Obx(
                      () => _AccountTile(
                        logo: 'assets/images/huya.png',
                        title: '虎牙直播',
                        subtitle: PlatformService.instance.huyaSdkUa.value.isEmpty
                            ? '点击拉取最新配置'
                            : '已自定义 HYSDK_UA',
                        onTap: () async {
                          final result = await Utils.showAlertDialog(
                            '是否从网络拉取虎牙最新配置？',
                            title: '拉取虎牙配置',
                          );
                          if (result) {
                            await PlatformService.instance.fetchHuyaSdkUa();
                          }
                        },
                      ),
                    ),
                    AppStyle.divider,
                    Obx(
                      () => _AccountTile(
                        logo: 'assets/images/douyin.png',
                        title: '抖音直播',
                        subtitle: PlatformService.instance.douyinName.value,
                        trailing: PlatformService.instance.douyinLogined.value
                            ? const Icon(Icons.logout_rounded)
                            : null,
                        onTap: controller.douyinTap,
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
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.logo,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final String logo;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Function()? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;
    return ListTile(
      enabled: enabled,
      visualDensity: VisualDensity.compact,
      minVerticalPadding: 10,
      contentPadding: const EdgeInsets.only(left: 16, right: 12),
      leading: Image.asset(logo, width: 36, height: 36),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: enabled ? semantic.textPrimary : semantic.textDisabled,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: enabled ? semantic.textSecondary : semantic.textDisabled,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: enabled ? semantic.textTertiary : semantic.textDisabled,
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
