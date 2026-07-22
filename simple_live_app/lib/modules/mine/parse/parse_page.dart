import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/modules/mine/parse/parse_controller.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';

class ParsePage extends GetView<ParseController> {
  const ParsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('链接解析')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _ParseCard(
                title: '直播间跳转',
                subtitle: '解析平台分享链接并打开对应直播间',
                controller: controller.roomJumpToController,
                buttonIcon: Remix.play_circle_line,
                buttonLabel: '链接跳转',
                onSubmitted: controller.jumpToRoom,
                onPressed: () => controller.jumpToRoom(
                  controller.roomJumpToController.text,
                ),
              ),
              const SizedBox(height: AppDesignTokens.space16),
              _ParseCard(
                title: '获取直链',
                subtitle: '选择清晰度与线路后复制播放地址',
                controller: controller.getUrlController,
                buttonIcon: Remix.link,
                buttonLabel: '获取直链',
                onSubmitted: controller.getPlayUrl,
                onPressed: () => controller.getPlayUrl(
                  controller.getUrlController.text,
                ),
              ),
              const _SectionHeading(title: '支持的链接', top: 24),
              SettingsCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppDesignTokens.space16),
                  child: SelectableText(
                    '''哔哩哔哩
https://live.bilibili.com/xxxxx
https://b23.tv/xxxxx

虎牙直播
https://www.huya.com/xxxxx

斗鱼直播
https://www.douyu.com/xxxxx
https://www.douyu.com/topic/xxxx

抖音直播
https://live.douyin.com/xxxxx
https://webcast.amemv.com/douyin/webcast/reflow/xxxxx''',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: semantic.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParseCard extends StatelessWidget {
  const _ParseCard({
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.buttonIcon,
    required this.buttonLabel,
    required this.onSubmitted,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final TextEditingController controller;
  final IconData buttonIcon;
  final String buttonLabel;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final semantic = context.appTheme;
    final theme = Theme.of(context);
    return SettingsCard(
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppDesignTokens.space16,
            vertical: AppDesignTokens.space4,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: semantic.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: semantic.textSecondary,
            ),
          ),
          children: [
            TextField(
              minLines: 3,
              maxLines: 3,
              controller: controller,
              textInputAction: TextInputAction.go,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '输入或粘贴哔哩哔哩、虎牙、斗鱼或抖音直播链接',
                alignLabelWithHint: true,
              ),
              onSubmitted: onSubmitted,
            ),
            const SizedBox(height: AppDesignTokens.space12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: Icon(buttonIcon),
                label: Text(buttonLabel),
              ),
            ),
          ],
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
