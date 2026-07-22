import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/modules/follow_user/follow_info_setting/follow_info_controller.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_menu.dart';

class FollowInfoPage extends GetView<FollowInfoController> {
  const FollowInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final site = Sites.allSites[controller.followUser.value!.siteId]!;
    final theme = Theme.of(context);
    final semantic = context.appTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('关注信息设置'),
        actions: [
          Obx(
            () => controller.pageLoadding.value
                ? const IconButton(
                    onPressed: null,
                    tooltip: '正在刷新',
                    icon: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: controller.refreshData,
                    tooltip: '刷新用户信息',
                    icon: const Icon(Icons.refresh_rounded),
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
              SettingsCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppDesignTokens.space16),
                  child: Obx(
                    () => Row(
                      children: [
                        NetImage(
                          controller.followUser.value!.face,
                          width: 56,
                          height: 56,
                          borderRadius: 28,
                        ),
                        const SizedBox(width: AppDesignTokens.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.followUser.value!.remark?.isNotEmpty ==
                                        true
                                    ? '${controller.followUser.value!.userName} (${controller.followUser.value!.remark!})'
                                    : controller.followUser.value!.userName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: semantic.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppDesignTokens.space4),
                              Row(
                                children: [
                                  Image.asset(site.logo, width: 18, height: 18),
                                  const SizedBox(width: AppDesignTokens.space8),
                                  Expanded(
                                    child: Text(
                                      '${site.name} · 房间号 ${controller.followUser.value!.roomId}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: semantic.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const _SectionHeading(title: '基本信息', top: 24),
              SettingsCard(
                child: Column(
                  children: [
                    Obx(() {
                      final items = controller.tagOptions;
                      final selected = controller.selectedTag.value;
                      final valueMap = <String, String>{
                        for (final item in items) item.tag: item.tag,
                      };
                      return SettingsMenu<String>(
                        title: '标签设置',
                        value: selected?.tag ?? '全部',
                        valueMap: valueMap,
                        onChanged: (value) {
                          final target = items.firstWhere(
                            (item) => item.tag == value,
                            orElse: () => items.first,
                          );
                          controller.changeTag(target);
                        },
                      );
                    }),
                    AppStyle.divider,
                    Obx(
                      () => SettingsAction(
                        title: '备注设置',
                        value:
                            controller.followUser.value?.remark?.isNotEmpty == true
                                ? controller.followUser.value!.remark!
                                : '无',
                        onTap: () => _showRemarkDialog(context),
                      ),
                    ),
                  ],
                ),
              ),
              const _SectionHeading(title: '平台迁移', top: 24),
              SettingsCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppDesignTokens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Remix.link,
                            size: 20,
                            color: semantic.textSecondary,
                          ),
                          const SizedBox(width: AppDesignTokens.space8),
                          Expanded(
                            child: Text(
                              '输入主播在新平台的直播链接，解析后迁移关注信息',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: semantic.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDesignTokens.space12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final field = TextField(
                            controller: controller.migrationUrlController,
                            decoration: const InputDecoration(
                              hintText: '粘贴新平台直播间链接，如 https://...',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => controller.parseAndMigrate(),
                          );
                          final actions = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: '粘贴',
                                onPressed: controller.pasteFromClipboard,
                                icon: const Icon(Remix.clipboard_line),
                              ),
                              const SizedBox(width: AppDesignTokens.space8),
                              FilledButton.icon(
                                onPressed: controller.parseAndMigrate,
                                icon: const Icon(Remix.arrow_right_line),
                                label: const Text('迁移'),
                              ),
                            ],
                          );
                          if (constraints.maxWidth < 560) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                field,
                                const SizedBox(height: AppDesignTokens.space8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: actions,
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: field),
                              const SizedBox(width: AppDesignTokens.space8),
                              actions,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppDesignTokens.space12),
                      Text(
                        'other todo ...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: semantic.textTertiary,
                        ),
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

  void _showRemarkDialog(BuildContext context) {
    final textController = TextEditingController(
      text: controller.followUser.value?.remark,
    );
    Get.dialog(
      AlertDialog(
        title: const Text('修改备注'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '请输入备注名',
          ),
          autofocus: true,
          onSubmitted: (value) {
            controller.updateRemark(value.trim());
            Get.back();
          },
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('取消')),
          FilledButton(
            onPressed: () {
              controller.updateRemark(textController.text.trim());
              Get.back();
            },
            child: const Text('确定'),
          ),
        ],
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
