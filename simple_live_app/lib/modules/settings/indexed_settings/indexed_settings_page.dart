import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/modules/settings/indexed_settings/indexed_settings_controller.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';

class IndexedSettingsPage extends GetView<IndexedSettingsController> {
  const IndexedSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('主页设置')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              const _SectionHeading(
                title: '主页排序',
                subtitle: '长按拖动排序，重启后生效',
              ),
              SettingsCard(
                child: Obx(
                  () => ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: controller.updateHomeSort,
                    children: controller.homeSort.map((key) {
                      final item = Constant.allHomePages[key]!;
                      return _ReorderTile(
                        key: ValueKey(item.title),
                        title: item.title,
                        leading: Icon(item.iconData),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const _SectionHeading(
                title: '平台排序',
                subtitle: '长按拖动排序，重启后生效',
                top: 24,
              ),
              SettingsCard(
                child: Obx(
                  () => ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: controller.updateSiteSort,
                    children: controller.siteSort
                        .where((key) => Sites.allSites[key]?.name != 'Twitch')
                        .map((key) {
                      final item = Sites.allSites[key]!;
                      return _ReorderTile(
                        key: ValueKey(item.id),
                        title: item.name,
                        leading: Image.asset(
                          item.logo,
                          width: 24,
                          height: 24,
                        ),
                      );
                    }).toList(),
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

class _ReorderTile extends StatelessWidget {
  const _ReorderTile({
    required super.key,
    required this.title,
    required this.leading,
  });

  final String title;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;
    return ListTile(
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.only(left: 16, right: 12),
      leading: leading,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          color: semantic.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.drag_handle_rounded, color: semantic.textTertiary),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.top = 0,
  });

  final String title;
  final String subtitle;
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
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: semantic.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
