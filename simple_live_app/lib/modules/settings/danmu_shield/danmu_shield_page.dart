import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/modules/settings/danmu_shield/danmu_shield_controller.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';

class DanmuShieldPage extends GetView<DanmuShieldController> {
  const DanmuShieldPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('弹幕屏蔽')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              const _SectionHeading(title: '添加屏蔽规则'),
              SettingsCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppDesignTokens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: controller.textEditingController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '请输入关键词或正则表达式',
                          prefixIcon: Icon(Icons.block_rounded),
                        ),
                        onSubmitted: (_) => controller.add(),
                      ),
                      const SizedBox(height: AppDesignTokens.space12),
                      FilledButton.icon(
                        onPressed: controller.add,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('添加规则'),
                      ),
                      const SizedBox(height: AppDesignTokens.space8),
                      Text(
                        '以“/”开头和结尾将视作正则表达式，例如“/\\d+/”表示屏蔽所有数字。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: semantic.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Obx(
                () => _SectionHeading(
                  title:
                      '已添加 ${controller.settingsController.shieldList.length} 个规则',
                  subtitle: '点击删除图标移除规则',
                  top: 24,
                ),
              ),
              SettingsCard(
                child: Obx(
                  () => Padding(
                    padding: const EdgeInsets.all(AppDesignTokens.space16),
                    child: controller.settingsController.shieldList.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              '暂无屏蔽规则',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: semantic.textTertiary,
                              ),
                            ),
                          )
                        : Wrap(
                            runSpacing: AppDesignTokens.space8,
                            spacing: AppDesignTokens.space8,
                            children: controller.settingsController.shieldList
                                .map(
                                  (item) => ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 680,
                                    ),
                                    child: InputChip(
                                      label: Text(
                                        item,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      deleteButtonTooltipMessage: '移除 $item',
                                      onDeleted: () => controller.remove(item),
                                    ),
                                  ),
                                )
                                .toList(),
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.subtitle,
    this.top = 0,
  });

  final String title;
  final String? subtitle;
  final double top;

  @override
  Widget build(BuildContext context) {
    final semantic = context.appTheme;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(4, top, 4, AppDesignTokens.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: semantic.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: semantic.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
