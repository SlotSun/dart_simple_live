import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/modules/home/home_list_controller.dart';
import 'package:simple_live_app/widgets/keep_alive_wrapper.dart';
import 'package:simple_live_app/widgets/live_room_card.dart';
import 'package:simple_live_app/widgets/page_grid_view.dart';

class HomeListView extends StatelessWidget {
  final String tag;
  const HomeListView(this.tag, {super.key});

  HomeListController get controller => Get.find<HomeListController>(tag: tag);

  @override
  Widget build(BuildContext context) {
    return KeepAliveWrapper(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const targetCardWidth = 280.0;
          const spacing = AppDesignTokens.space16;
          const maxColumnCount = 5;
          final gutter = _contentGutter(constraints.maxWidth);
          final maxViewportWidth = (targetCardWidth * maxColumnCount) +
              (spacing * (maxColumnCount - 1)) +
              (gutter * 2);
          final viewportWidth = constraints.maxWidth > maxViewportWidth
              ? maxViewportWidth
              : constraints.maxWidth;
          final availableWidth = viewportWidth - (gutter * 2);
          var columnCount =
              ((availableWidth + spacing) / (targetCardWidth + spacing))
                  .floor();
          if (columnCount < 1) columnCount = 1;
          if (columnCount > maxColumnCount) columnCount = maxColumnCount;

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: viewportWidth,
              child: PageGridView(
                pageController: controller,
                padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 24),
                firstRefresh: true,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                crossAxisCount: columnCount,
                itemBuilder: (_, i) {
                  final item = controller.list[i];
                  return LiveRoomCard(controller.site, item);
                },
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
