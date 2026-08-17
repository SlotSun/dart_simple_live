import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/widgets/liquid_glass_navigation_bar.dart';

import 'indexed_controller.dart';

class IndexedPage extends GetView<IndexedController> {
  const IndexedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          // 内容延伸到底部导航栏下方，液态玻璃栏才能模糊到页面内容
          extendBody: true,
          body: Row(
            children: [
              Visibility(
                visible: orientation == Orientation.landscape,
                child: Obx(
                  () => NavigationRail(
                    selectedIndex: controller.index.value,
                    onDestinationSelected: controller.setIndex,
                    labelType: NavigationRailLabelType.none,
                    destinations: controller.items
                        .map(
                          (item) => NavigationRailDestination(
                            icon: Icon(item.iconData),
                            label: Text(item.title),
                            padding: AppStyle.edgeInsetsV8,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              Expanded(
                child: Obx(
                  () => Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: orientation == Orientation.landscape
                            ? BorderSide(
                                color: Colors.grey.withAlpha(50),
                                width: 1,
                              )
                            : BorderSide.none,
                      ),
                    ),
                    child: IndexedStack(
                      index: controller.index.value,
                      children: controller.pages,
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Visibility(
            visible: orientation == Orientation.portrait,
            child: Obx(
              () => LiquidGlassNavigationBar(
                selectedIndex: controller.index.value,
                onDestinationSelected: controller.setIndex,
                destinations: controller.items
                    .map(
                      (item) => LiquidGlassDestination(
                        icon: item.iconData,
                        label: item.title,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
