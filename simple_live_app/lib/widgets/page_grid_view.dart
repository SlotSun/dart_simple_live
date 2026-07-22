import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/widgets/desktop_refresh_button.dart';
import 'package:simple_live_app/widgets/status/app_empty_widget.dart';
import 'package:simple_live_app/widgets/status/app_error_widget.dart';
import 'package:simple_live_app/widgets/status/app_loadding_widget.dart';

class PageGridView extends StatelessWidget {
  final BasePageController pageController;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsets? padding;
  final bool firstRefresh;
  final Function()? onLoginSuccess;
  final bool showPageLoadding;
  final double crossAxisSpacing, mainAxisSpacing;
  final int crossAxisCount;
  final bool showPCRefreshButton;

  const PageGridView({
    required this.itemBuilder,
    required this.pageController,
    this.padding,
    this.firstRefresh = false,
    this.showPageLoadding = false,
    this.onLoginSuccess,
    this.crossAxisSpacing = 0.0,
    this.mainAxisSpacing = 0.0,
    this.showPCRefreshButton = true,
    required this.crossAxisCount,
    super.key,
  });

  bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  EdgeInsets? get _resolvedPadding {
    if (!_isDesktop) return padding;
    final contentPadding = padding ?? EdgeInsets.zero;
    return contentPadding.copyWith(bottom: contentPadding.bottom + 72);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final showDesktopActions = _isDesktop &&
            pageController.canLoadMore.value &&
            !pageController.pageLoadding.value &&
            !pageController.pageEmpty.value;

        return Stack(
          children: [
            EasyRefresh(
              header: MaterialHeader(
                completeDuration: const Duration(milliseconds: 400),
              ),
              footer: MaterialFooter(
                completeDuration: const Duration(milliseconds: 400),
              ),
              scrollController: pageController.scrollController,
              controller: pageController.easyRefreshController,
              firstRefresh: firstRefresh,
              onLoad: pageController.loadData,
              onRefresh: pageController.refreshData,
              child: MasonryGridView.count(
                padding: _resolvedPadding,
                itemCount: pageController.list.length,
                itemBuilder: itemBuilder,
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
              ),
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Visibility(
                visible: showDesktopActions,
                child: Center(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: pageController.loadData,
                    child: const Text('加载更多'),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Visibility(
                visible: showDesktopActions && showPCRefreshButton,
                child: DesktopRefreshButton(
                  refreshing: false,
                  onPressed: pageController.refreshData,
                ),
              ),
            ),
            Offstage(
              offstage: !pageController.pageEmpty.value,
              child: AppEmptyWidget(
                onRefresh: pageController.refreshData,
              ),
            ),
            Offstage(
              offstage:
                  !(showPageLoadding && pageController.pageLoadding.value),
              child: const AppLoaddingWidget(),
            ),
            Offstage(
              offstage: !pageController.pageError.value,
              child: AppErrorWidget(
                errorMsg: pageController.errorMsg.value,
                onRefresh: pageController.refreshData,
              ),
            ),
          ],
        );
      },
    );
  }
}
