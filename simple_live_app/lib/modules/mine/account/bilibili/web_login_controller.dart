import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/models/db/account.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/services/platform_service.dart';

class BiliBiliWebLoginController extends BaseController {
  Account account = Get.arguments;
  InAppWebViewController? webViewController;
  final CookieManager cookieManager = CookieManager.instance();
  void onWebViewCreated(InAppWebViewController controller) {
    webViewController = controller;
    webViewController!.loadUrl(
      urlRequest: URLRequest(
        url: WebUri("https://passport.bilibili.com/login"),
      ),
    );
  }

  void toQRLogin() async {
    await Get.toNamed(RoutePath.kAccountQRLogin, arguments: account);
    Get.back();
  }

  void onLoadStop(InAppWebViewController controller, Uri? uri) async {
    if (uri == null) {
      return;
    }
    if (uri.host == "m.bilibili.com") {
      logined();
    }
  }

  Future<bool> logined() async {
    try {
      var cookies = await cookieManager.getCookies(url: WebUri("https://bilibili.com"));
      if (cookies.isEmpty) {
        return false;
      }
      var cookieStr = cookies.map((e) => "${e.name}=${e.value}").join(";");
      Log.i(cookieStr);
      var credential = jsonEncode({'cookie': cookieStr});

      var res = await PlatformService.instance.accountLogin(
        account.copyWith(
          credential: credential,
        ),
      );
      if (res == false) {
        SmartDialog.showToast('登录错误请重新登录！');
      }
      Get.back();
      return true;
    } catch (e) {
      return false;
    }
  }
}
