import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/models/account/douyin_user_info.dart';
import 'package:simple_live_app/requests/common_request.dart';
import 'package:simple_live_app/services/local_storage_service.dart';
import 'package:simple_live_core/simple_live_core.dart';

class PlatformService extends GetxService {
  static PlatformService get instance => Get.find<PlatformService>();

  // ==================== 抖音 ====================

  final _douyinSite = (Sites.allSites[Constant.kDouyin]!.liveSite as DouyinSite);

  var douyinLogined = false.obs;
  var douyinCookie = "";
  var douyinName = "未登录".obs;
  var douyinHlsFirst = false;

  void _initDouyin() {
    douyinHlsFirst = LocalStorageService.instance.getValue(LocalStorageService.kDouyinHlsFirst, false);
    _setDouyinHlsFirst();
    douyinCookie = LocalStorageService.instance.getValue(LocalStorageService.kDouyinCookie, "");
    douyinLogined.value = douyinCookie.isNotEmpty;
    loadDouyinUserInfo();
  }

  void _setDouyinHlsFirst() {
    _douyinSite.hlsFirst = douyinHlsFirst;
  }

  Future loadDouyinUserInfo() async {
    if (douyinCookie.isEmpty) return;
    try {
      final data = await _douyinSite.getUserInfoByCookie(douyinCookie);
      if (data.isEmpty) {
        SmartDialog.showToast("抖音登录已失效，请重新登录");
        douyinLogout();
        return;
      }
      var info = DouyinUserInfoModel.fromJson(data);
      douyinName.value = info.nickname!;
      douyinLogined.value = true;
      _setDouyinSiteCookie();
    } catch (e) {
      SmartDialog.showToast("获取抖音登录用户信息失败，可前往账号管理重试");
    }
  }

  void _setDouyinSiteCookie() {
    if (douyinCookie.isEmpty) {
      _douyinSite.headers.remove("cookie");
    } else {
      _douyinSite.headers["cookie"] = douyinCookie;
    }
  }

  void setDouyinCookie(String cookie) {
    douyinCookie = cookie;
    LocalStorageService.instance.setValue(LocalStorageService.kDouyinCookie, cookie);
  }

  void douyinLogout() async {
    douyinCookie = "";
    LocalStorageService.instance.setValue(LocalStorageService.kDouyinCookie, "");
    douyinLogined.value = false;
    douyinName.value = "未登录";
    _setDouyinSiteCookie();
    if (Platform.isAndroid || Platform.isIOS) {
      CookieManager cookieManager = CookieManager.instance();
      await cookieManager.deleteAllCookies();
    }
  }

  // ==================== 虎牙 ====================

  static const String defaultHuyaSdkUa = "HYSDK(Windows,30000002)_APP(pc_exe&7090000&official)_SDK(trans&2.35.0.5996)";

  var huyaSdkUa = "".obs;

  void _initHuya() {
    huyaSdkUa.value = LocalStorageService.instance.getValue(LocalStorageService.kHuyaSdkUa, "");
    _applyHuyaSdkUa();
  }

  void _applyHuyaSdkUa() {
    var ua = huyaSdkUa.value.isNotEmpty ? huyaSdkUa.value : defaultHuyaSdkUa;
    HuyaSite.HYSDK_UA = ua;
    Log.i("HuyaSite.HYSDK_UA 已设置: $ua");
  }

  Future<void> fetchHuyaSdkUa() async {
    try {
      SmartDialog.showLoading(msg: "正在拉取配置...");
      var request = CommonRequest();
      var config = await request.fetchHuyaConfig();
      var ua = config['hysdk_ua'] as String? ?? "";
      if (ua.isEmpty) {
        SmartDialog.dismiss();
        SmartDialog.showToast("配置中未找到 hysdk_ua");
        return;
      }
      huyaSdkUa.value = ua;
      await LocalStorageService.instance.setValue(LocalStorageService.kHuyaSdkUa, ua);
      HuyaSite.HYSDK_UA = ua;
      SmartDialog.dismiss();
      SmartDialog.showToast("虎牙配置已更新");
      Log.i("HuyaSite.HYSDK_UA 已更新: $ua");
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast("拉取配置失败: $e");
      Log.e("拉取虎牙配置失败: $e", StackTrace.current);
    }
  }

  // ==================== 生命周期 ====================

  @override
  void onInit() {
    _initDouyin();
    _initHuya();
    super.onInit();
  }
}
