import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/modules/search/search_list_controller.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/widgets/keep_alive_wrapper.dart';
import 'package:simple_live_app/widgets/live_room_card.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_app/widgets/page_grid_view.dart';
import 'package:simple_live_app/widgets/shadow_card.dart';
import 'package:simple_live_core/simple_live_core.dart';

class SearchListView extends StatelessWidget {
  final String tag;
  const SearchListView(this.tag, {super.key});

  SearchListController get controller =>
      Get.find<SearchListController>(tag: tag);

  @override
  Widget build(BuildContext context) {
    return KeepAliveWrapper(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const roomTargetWidth = 280.0;
          const roomSpacing = AppDesignTokens.space16;
          const maxRoomColumns = 5;
          const anchorTargetWidth = 360.0;
          const anchorSpacing = AppDesignTokens.space12;
          const maxAnchorColumns = 3;
          final gutter = _contentGutter(constraints.maxWidth);

          final maxRoomViewportWidth = (roomTargetWidth * maxRoomColumns) +
              (roomSpacing * (maxRoomColumns - 1)) +
              (gutter * 2);
          final roomViewportWidth = constraints.maxWidth > maxRoomViewportWidth
              ? maxRoomViewportWidth
              : constraints.maxWidth;
          final roomAvailableWidth = roomViewportWidth - (gutter * 2);
          var roomColumnCount = ((roomAvailableWidth + roomSpacing) /
                  (roomTargetWidth + roomSpacing))
              .floor();
          if (roomColumnCount < 1) roomColumnCount = 1;
          if (roomColumnCount > maxRoomColumns) {
            roomColumnCount = maxRoomColumns;
          }

          final maxAnchorViewportWidth =
              (anchorTargetWidth * maxAnchorColumns) +
                  (anchorSpacing * (maxAnchorColumns - 1)) +
                  (gutter * 2);
          final anchorViewportWidth =
              constraints.maxWidth > maxAnchorViewportWidth
                  ? maxAnchorViewportWidth
                  : constraints.maxWidth;
          final anchorAvailableWidth = anchorViewportWidth - (gutter * 2);
          var anchorColumnCount = ((anchorAvailableWidth + anchorSpacing) /
                  (anchorTargetWidth + anchorSpacing))
              .floor();
          if (anchorColumnCount < 1) anchorColumnCount = 1;
          if (anchorColumnCount > maxAnchorColumns) {
            anchorColumnCount = maxAnchorColumns;
          }

          return Obx(
            () => controller.searchMode.value == 0
                ? Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: roomViewportWidth,
                      child: PageGridView(
                        pageController: controller,
                        padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 24),
                        firstRefresh: false,
                        mainAxisSpacing: roomSpacing,
                        crossAxisSpacing: roomSpacing,
                        crossAxisCount: roomColumnCount,
                        showPageLoadding: true,
                        itemBuilder: (_, i) {
                          final item = controller.list[i] as LiveRoomItem;
                          return LiveRoomCard(controller.site, item);
                        },
                      ),
                    ),
                  )
                : Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: anchorViewportWidth,
                      child: PageGridView(
                        pageController: controller,
                        padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 24),
                        firstRefresh: true,
                        mainAxisSpacing: anchorSpacing,
                        crossAxisSpacing: anchorSpacing,
                        crossAxisCount: anchorColumnCount,
                        itemBuilder: (_, i) {
                          final item = controller.list[i] as LiveAnchorItem;
                          return _AnchorResultCard(
                            item: item,
                            onTap: () {
                              AppNavigator.toLiveRoomDetail(
                                site: controller.site,
                                roomId: item.roomId,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  double _contentGutter(double width) {
    if (width >= 1200) return 32;
    if (width >= 720) return 24;
    return 12;
  }
}

class _AnchorResultCard extends StatelessWidget {
  const _AnchorResultCard({
    required this.item,
    required this.onTap,
  });

  final LiveAnchorItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;
    final statusColor =
        item.liveStatus ? theme.colorScheme.tertiary : semantic.textDisabled;

    return ShadowCard(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 82),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDesignTokens.space12,
            vertical: AppDesignTokens.space8,
          ),
          leading: NetImage(
            item.avatar,
            width: 52,
            height: 52,
            borderRadius: 26,
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
            padding: const EdgeInsets.only(top: AppDesignTokens.space4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppDesignTokens.space8),
                Flexible(
                  child: Text(
                    item.liveStatus ? '直播中' : '未开播',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: item.liveStatus
                          ? semantic.textSecondary
                          : semantic.textTertiary,
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
        ),
      ),
    );
  }
}
