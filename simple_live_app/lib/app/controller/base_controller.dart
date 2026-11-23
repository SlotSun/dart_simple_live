import 'dart:async';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class BaseController extends GetxController {
  /// 加载中，更新页面
  var pageLoadding = false.obs;

  /// 加载中,不会更新页面
  var loadding = false;

  /// 空白页面
  var pageEmpty = false.obs;

  /// 页面错误
  var pageError = false.obs;

  /// 未登录
  var notLogin = false.obs;

  /// 错误信息
  var errorMsg = "".obs;

  /// 显示错误
  /// * [msg] 错误信息
  /// * [showPageError] 显示页面错误
  /// * 只在第一页加载错误时showPageError=true，后续页加载错误时使用Toast弹出通知
  void handleError(Object exception, {bool showPageError = false}) {
    Log.e(exception.toString(), StackTrace.current);
    var msg = exceptionToString(exception);

    if (showPageError) {
      pageError.value = true;
      errorMsg.value = msg;
    } else {
      SmartDialog.showToast(exceptionToString(msg));
    }
  }

  String exceptionToString(Object exception) {
    return exception.toString().replaceAll("Exception:", "");
  }

  void onLogin() {}
  void onLogout() {}
}

class BasePageController<T> extends BaseController {
  final ScrollController scrollController = ScrollController();
  final EasyRefreshController easyRefreshController = EasyRefreshController();
  int currentPage = 1;
  int count = 0;
  int maxPage = 0;
  int pageSize = 24;
  var canLoadMore = false.obs;
  var list = <T>[].obs;

  /// 距底部多少像素内触发自动加载
  static const double loadMoreThreshold = 400;

  /// 内容不足一屏时最多连续补加载的页数，
  /// 避免接口不分页（每页都返回相同数据）时死循环。
  static const int maxAutoFillPages = 5;
  int _autoFillPages = 0;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    super.onClose();
  }

  /// 桌面端鼠标滚轮走的是 [ScrollPosition.pointerScroll]，
  /// 位置会被钳制在可滚动范围内，不会产生 overscroll，
  /// 因此 EasyRefresh 的 Footer 永远触发不了 onLoad。
  /// 这里直接监听滚动位置，接近底部时主动加载下一页。
  void _onScroll() {
    if (loadding || !canLoadMore.value) {
      return;
    }
    for (final position in scrollController.positions) {
      if (!_shouldLoadMore(position)) {
        continue;
      }
      loadData();
      return;
    }
  }

  /// 距离底部足够近，可以加载下一页
  bool _shouldLoadMore(ScrollMetrics position) {
    return position.hasContentDimensions &&
        position.extentAfter <= loadMoreThreshold;
  }

  /// 每页加载完成后检查一次：如果内容还不足一屏（无法滚动），
  /// 继续加载下一页，直到能滚动或没有更多数据。
  void _scheduleFillViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (loadding || !canLoadMore.value) {
        return;
      }
      if (_autoFillPages >= maxAutoFillPages) {
        return;
      }
      for (final position in scrollController.positions) {
        if (!_shouldLoadMore(position)) {
          continue;
        }
        _autoFillPages++;
        loadData();
        return;
      }
    });
  }

  Future refreshData() async {
    currentPage = 1;
    _autoFillPages = 0;
    list.value = [];
    await loadData();
  }

  Future loadData() async {
    try {
      if (loadding) return;
      loadding = true;
      pageError.value = false;
      pageEmpty.value = false;
      notLogin.value = false;
      pageLoadding.value = currentPage == 1;

      var result = await getData(currentPage, pageSize);
      //是否可以加载更多
      if (result.isNotEmpty) {
        currentPage++;
        canLoadMore.value = true;
        pageEmpty.value = false;
      } else {
        canLoadMore.value = false;
        if (currentPage == 1) {
          pageEmpty.value = true;
        }
      }
      // 赋值数据
      if (currentPage == 1) {
        list.value = result;
      } else {
        list.addAll(result);
      }
    } catch (e) {
      handleError(e, showPageError: currentPage == 1);
    } finally {
      loadding = false;
      pageLoadding.value = false;
      // 内容不足一屏时继续加载，保证首屏是满的
      _scheduleFillViewport();
    }
  }

  Future<List<T>> getData(int page, int pageSize) async {
    return [];
  }

  void scrollToTopOrRefresh() {
    if (scrollController.offset > 0) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      );
    } else {
      easyRefreshController.callRefresh();
    }
  }
}
