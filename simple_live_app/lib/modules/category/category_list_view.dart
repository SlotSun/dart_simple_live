import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/modules/category/category_list_controller.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/widgets/keep_alive_wrapper.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:sticky_headers/sticky_headers.dart';

class CategoryListView extends StatelessWidget {
  final String tag;
  const CategoryListView(this.tag, {super.key});

  CategoryListController get controller =>
      Get.find<CategoryListController>(tag: tag);

  @override
  Widget build(BuildContext context) {
    return KeepAliveWrapper(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const targetCellWidth = 104.0;
          const spacing = AppDesignTokens.space8;
          const maxColumnCount = 10;
          final semantic = context.appTheme;
          final gutter = _contentGutter(constraints.maxWidth);
          final maxViewportWidth = (targetCellWidth * maxColumnCount) +
              (spacing * (maxColumnCount - 1)) +
              (gutter * 2);
          final viewportWidth = constraints.maxWidth > maxViewportWidth
              ? maxViewportWidth
              : constraints.maxWidth;
          final availableWidth = viewportWidth - (gutter * 2);
          var columnCount =
              ((availableWidth + spacing) / (targetCellWidth + spacing))
                  .floor();
          if (columnCount < 1) columnCount = 1;
          if (columnCount > maxColumnCount) columnCount = maxColumnCount;

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: viewportWidth,
              child: Obx(
                () => EasyRefresh(
                  firstRefresh: true,
                  controller: controller.easyRefreshController,
                  onRefresh: controller.refreshData,
                  header: MaterialHeader(
                    completeDuration: const Duration(milliseconds: 400),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 24),
                    itemCount: controller.list.length,
                    controller: controller.scrollController,
                    itemBuilder: (_, i) {
                      final item = controller.list[i];
                      return StickyHeader(
                        header: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
                          decoration: BoxDecoration(
                            color: semantic.body,
                            border: Border(
                              bottom: BorderSide(color: semantic.divider),
                            ),
                          ),
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: semantic.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ),
                        content: Obx(
                          () {
                            final showAll = item.showAll.value;
                            final children =
                                showAll ? item.children : item.take15;
                            final itemCount =
                                children.length + (showAll ? 0 : 1);

                            return GridView.builder(
                              shrinkWrap: true,
                              padding:
                                  const EdgeInsets.only(top: 12, bottom: 24),
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: itemCount,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columnCount,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                                mainAxisExtent: 96,
                              ),
                              itemBuilder: (context, index) {
                                if (index == children.length) {
                                  return _ShowAllCategoryCell(
                                    onTap: () => item.showAll.value = true,
                                  );
                                }
                                return _SubCategoryCell(
                                  item: children[index],
                                  onTap: () {
                                    AppNavigator.toCategoryDetail(
                                      site: controller.site,
                                      category: children[index],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
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

class _SubCategoryCell extends StatelessWidget {
  const _SubCategoryCell({
    required this.item,
    required this.onTap,
  });

  final LiveSubCategory item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.appTheme;
    final radius = BorderRadius.circular(AppDesignTokens.radius10);

    return Material(
      color: semantic.secondarySurface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: semantic.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(AppDesignTokens.space8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NetImage(
                item.pic ?? '',
                width: 40,
                height: 40,
                borderRadius: AppDesignTokens.radius8,
              ),
              const SizedBox(height: AppDesignTokens.space8),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: semantic.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShowAllCategoryCell extends StatelessWidget {
  const _ShowAllCategoryCell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.appTheme;
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppDesignTokens.radius10);

    return Material(
      color: semantic.secondarySurface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: semantic.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppDesignTokens.space4),
            Text(
              '显示全部',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
