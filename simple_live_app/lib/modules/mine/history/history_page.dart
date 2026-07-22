import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/mine/history/history_controller.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_app/widgets/page_grid_view.dart';

class HistoryPage extends GetView<HistoryController> {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: AppDesignTokens.space24,
        toolbarHeight: 68,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '观看记录',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: semantic.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '最近访问的直播间',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: semantic.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: controller.clean,
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('清空'),
          ),
          const SizedBox(width: AppDesignTokens.space8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth > 1040
              ? 1040.0
              : constraints.maxWidth;
          final availableWidth = viewportWidth - 32;
          var rowCount = (availableWidth / 480).floor();
          if (rowCount < 1) rowCount = 1;
          if (rowCount > 2) rowCount = 2;

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: viewportWidth,
              child: PageGridView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                mainAxisSpacing: AppDesignTokens.space8,
                crossAxisSpacing: AppDesignTokens.space8,
                crossAxisCount: rowCount,
                pageController: controller,
                firstRefresh: true,
                itemBuilder: (_, i) {
                  final item = controller.list[i];
                  final site = Sites.allSites[item.siteId]!;
                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(
                          AppDesignTokens.radius12,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDesignTokens.space16,
                      ),
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: theme.colorScheme.onErrorContainer,
                        semanticLabel: '删除记录',
                      ),
                    ),
                    confirmDismiss: (_) => Utils.showAlertDialog(
                      '确定要删除此记录吗?',
                      title: '删除记录',
                    ),
                    onDismissed: (_) => controller.removeItem(item),
                    child: Material(
                      color: semantic.secondarySurface,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDesignTokens.radius12,
                        ),
                        side: BorderSide(color: semantic.border),
                      ),
                      child: ListTile(
                        minVerticalPadding: AppDesignTokens.space8,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDesignTokens.space12,
                          vertical: AppDesignTokens.space4,
                        ),
                        leading: NetImage(
                          item.face,
                          width: 48,
                          height: 48,
                          borderRadius: 24,
                        ),
                        title: Text(
                          item.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: semantic.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(
                            top: AppDesignTokens.space4,
                          ),
                          child: Row(
                            children: [
                              Image.asset(site.logo, width: 16, height: 16),
                              const SizedBox(width: AppDesignTokens.space4),
                              Expanded(
                                child: Text(
                                  site.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: semantic.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDesignTokens.space8),
                              Flexible(
                                child: Text(
                                  Utils.parseTime(item.updateTime),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: semantic.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: semantic.textTertiary,
                        ),
                        onTap: () {
                          AppNavigator.toLiveRoomDetail(
                            site: site,
                            roomId: item.roomId,
                          );
                        },
                        onLongPress: () async {
                          final result = await Utils.showAlertDialog(
                            '确定要删除此记录吗?',
                            title: '删除记录',
                          );
                          if (result) controller.removeItem(item);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
