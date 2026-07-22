import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/modules/follow_user/follow_user_controller.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/widgets/filter_button.dart';
import 'package:simple_live_app/widgets/follow_user_item.dart';
import 'package:simple_live_app/widgets/keep_alive_wrapper.dart';
import 'package:simple_live_app/widgets/live_room_card.dart';
import 'package:simple_live_app/widgets/page_grid_view.dart';
import 'package:simple_live_core/simple_live_core.dart';

class FollowUserPage extends GetView<FollowUserController> {
  const FollowUserPage({super.key});

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
              '关注用户',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: semantic.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '实时状态与分组',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: semantic.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            tooltip: '关注菜单',
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 0,
                child: _MenuItem(icon: Remix.trophy_line, label: '赛事订阅'),
              ),
              PopupMenuItem(
                value: 1,
                child: _MenuItem(icon: Remix.blender_line, label: '模式切换'),
              ),
              PopupMenuItem(
                value: 2,
                child: _MenuItem(icon: Remix.sort_asc, label: '按序排列'),
              ),
              PopupMenuItem(
                value: 4,
                child: _MenuItem(icon: Remix.heart_line, label: '关注设置'),
              ),
            ],
            onSelected: (value) {
              if (value == 4) {
                Get.toNamed(RoutePath.kSettingsFollow);
              } else if (value == 0) {
                SmartDialog.showToast('此功能暂未开放！敬请期待！');
              } else if (value == 1) {
                controller.showFollowStyleDialog();
              } else if (value == 2) {
                controller.showSortDialog();
              }
            },
          ),
          const SizedBox(width: AppDesignTokens.space8),
        ],
        leading: Obx(
          () => FollowService.instance.updating.value
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
                  tooltip: '刷新关注状态',
                  icon: const Icon(Icons.refresh_rounded),
                ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: semantic.divider)),
            ),
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: SizedBox(
                  height: 54,
                  child: Obx(
                    () => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDesignTokens.space16,
                        vertical: AppDesignTokens.space8,
                      ),
                      itemCount: controller.tagList.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppDesignTokens.space8),
                      itemBuilder: (_, index) {
                        final option = controller.tagList[index];
                        return FilterButton(
                          text: option.tag,
                          selected: controller.filterMode.value == option,
                          onTap: () => controller.setFilterMode(option),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewportWidth = constraints.maxWidth > 1280
                    ? 1280.0
                    : constraints.maxWidth;
                final availableWidth = viewportWidth - 32;
                var listColumns = (availableWidth / 460).floor();
                if (listColumns < 1) listColumns = 1;
                if (listColumns > 2) listColumns = 2;
                var cardColumns = (availableWidth / 260).floor();
                if (cardColumns < 2) cardColumns = 2;
                if (cardColumns > 5) cardColumns = 5;

                return Obx(
                  () => Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: viewportWidth,
                      child: AppSettingsController
                              .instance.followStyleNotGrid.value
                          ? PageGridView(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              mainAxisSpacing: AppDesignTokens.space8,
                              crossAxisSpacing: AppDesignTokens.space8,
                              crossAxisCount: listColumns,
                              pageController: controller,
                              firstRefresh: true,
                              showPCRefreshButton: false,
                              itemBuilder: (_, i) {
                                final item = controller.list[i];
                                final site = Sites.allSites[item.siteId]!;
                                return DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: semantic.secondarySurface,
                                    borderRadius: BorderRadius.circular(
                                      AppDesignTokens.radius12,
                                    ),
                                    border: Border.all(color: semantic.border),
                                  ),
                                  child: FollowUserItem(
                                    item: item,
                                    onRemove: () =>
                                        controller.removeFollow(item),
                                    onTap: () {
                                      AppNavigator.toLiveRoomDetail(
                                        site: site,
                                        roomId: item.roomId,
                                      );
                                    },
                                    onLongPress: () =>
                                        controller.showBottomMenu(item),
                                  ),
                                );
                              },
                            )
                          : KeepAliveWrapper(
                              child: Obx(
                                () {
                                  final hide = AppSettingsController.instance
                                      .hideRemoveFollowButton.value;
                                  return PageGridView(
                                    pageController: controller,
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      24,
                                    ),
                                    firstRefresh: true,
                                    mainAxisSpacing: AppDesignTokens.space16,
                                    crossAxisSpacing: AppDesignTokens.space16,
                                    crossAxisCount: cardColumns,
                                    itemBuilder: (_, i) {
                                      final item = controller.list[i];
                                      final liveRoomItem = LiveRoomItem(
                                        roomId: item.roomId,
                                        title: item.title.value,
                                        cover: item.cover.value,
                                        userName: item.userName,
                                        online: item.online.value,
                                      );
                                      final site = Sites.allSites[item.siteId]!;
                                      return LiveRoomCard(
                                        site,
                                        liveRoomItem,
                                        onFollowRemove: hide
                                            ? null
                                            : () => controller.removeFollow(item),
                                        onLongPress: () =>
                                            controller.showBottomMenu(item),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppDesignTokens.space12),
        Text(label),
      ],
    );
  }
}
