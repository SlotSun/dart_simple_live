import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';

import 'indexed_controller.dart';

class IndexedPage extends GetView<IndexedController> {
  const IndexedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        final theme = Theme.of(context);
        final semantic = context.appTheme;

        return Scaffold(
          body: Row(
            children: [
              Visibility(
                visible: isLandscape,
                replacement: const SizedBox.shrink(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: semantic.body,
                    border: Border(
                      right: BorderSide(color: semantic.border),
                    ),
                  ),
                  child: SafeArea(
                    right: false,
                    child: SizedBox(
                      width: 76,
                      child: Obx(
                        () => NavigationRail(
                          backgroundColor: Colors.transparent,
                          selectedIndex: controller.index.value,
                          onDestinationSelected: controller.setIndex,
                          minWidth: 76,
                          groupAlignment: -0.45,
                          labelType: NavigationRailLabelType.none,
                          useIndicator: true,
                          indicatorColor:
                              theme.colorScheme.primary.withAlpha(20),
                          indicatorShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDesignTokens.radius12,
                            ),
                          ),
                          destinations: controller.items
                              .map(
                                (item) => NavigationRailDestination(
                                  icon: Tooltip(
                                    message: item.title,
                                    child: Icon(item.iconData),
                                  ),
                                  selectedIcon: Tooltip(
                                    message: item.title,
                                    child: Icon(
                                      item.iconData,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  label: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppDesignTokens.space4,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Obx(
                  () => IndexedStack(
                    index: controller.index.value,
                    children: controller.pages,
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: isLandscape
              ? null
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: semantic.body,
                    border: Border(
                      top: BorderSide(color: semantic.border),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Obx(
                      () => NavigationBar(
                        backgroundColor: Colors.transparent,
                        selectedIndex: controller.index.value,
                        onDestinationSelected: controller.setIndex,
                        height: 64,
                        labelBehavior:
                            NavigationDestinationLabelBehavior.alwaysShow,
                        destinations: controller.items
                            .map(
                              (item) => NavigationDestination(
                                icon: Icon(item.iconData),
                                selectedIcon: Icon(
                                  item.iconData,
                                  color: theme.colorScheme.primary,
                                ),
                                tooltip: item.title,
                                label: item.title,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
