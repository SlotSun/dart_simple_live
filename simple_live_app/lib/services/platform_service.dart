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
    _updateDouyinAttr();
    douyinCookie = LocalStorageService.instance.getValue(LocalStorageService.kDouyinCookie, "");
    douyinLogined.value = douyinCookie.isNotEmpty;
    loadDouyinUserInfo();
  }

  void _updateDouyinAttr() {
    Map<String, dynamic> params = {
      'hlsFirst': douyinHlsFirst,
      'cookie': douyinCookie,
    };
    _douyinSite.setSiteAttrs(params);
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
      _updateDouyinAttr();
    } catch (e) {
      SmartDialog.showToast("获取抖音登录用户信息失败，可前往账号管理重试");
    }
  }

  void setDouyinCookie(String cookie) {
    if (cookie.isEmpty) return;
    douyinCookie = cookie;
    LocalStorageService.instance.setValue(LocalStorageService.kDouyinCookie, cookie);
    _updateDouyinAttr();
  }

  void douyinLogout() async {
    douyinCookie = "";
    LocalStorageService.instance.setValue(LocalStorageService.kDouyinCookie, "");
    douyinLogined.value = false;
    douyinName.value = "未登录";
    _updateDouyinAttr();
    if (Platform.isAndroid || Platform.isIOS) {
      CookieManager cookieManager = CookieManager.instance();
      await cookieManager.deleteAllCookies();
    }
  }

  // ==================== 虎牙 ====================

  static const String defaultHuyaSdkUa = "HYSDK(Windows,30000002)_APP(pc_exe&7090000&official)_SDK(trans&2.35.0.5996)";
  final _huyaSite = (Sites.allSites[Constant.kHuya]!.liveSite as HuyaSite);
  var huyaSdkUa = "".obs;

  void _initHuya() {
    huyaSdkUa.value = LocalStorageService.instance.getValue(LocalStorageService.kHuyaSdkUa, "");
    _updateHuyaAttr();
  }

  void _updateHuyaAttr() {
    var ua = huyaSdkUa.value.isNotEmpty ? huyaSdkUa.value : defaultHuyaSdkUa;
    _huyaSite.setSiteAttrs(
      {
        'ua': ua,
      },
    );
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
      _updateHuyaAttr();
      SmartDialog.dismiss();
      SmartDialog.showToast("虎牙配置已更新");
      Log.i("HuyaSite.HYSDK_UA 已更新: $ua");
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast("拉取配置失败: $e");
      Log.e("拉取虎牙配置失败: $e", StackTrace.current);
    }
  }

  // ==================== 斗鱼 ====================

  var douyuCookie = ''.obs;
  var dyLtp0 = '';
  var dy_did = '';
  final _douyuSite = (Sites.allSites[Constant.kDouyu]!.liveSite as DouyuSite);

  void _initDouyu() {
    douyuCookie.value = LocalStorageService.instance.getValue(LocalStorageService.kDouyuCookie, "");
    dy_did = LocalStorageService.instance.getValue(LocalStorageService.kDouyuDyDid, "");
    dyLtp0 = LocalStorageService.instance.getValue(LocalStorageService.kDouyuLTP0, "");
    // set and refresh
    _douyuSite.onCookieRefreshed = (cookie) async {
      douyuCookie.value = cookie;
      await LocalStorageService.instance.setValue(LocalStorageService.kDouyuCookie, cookie);
    };
    _updateDouyuAttr();
    _refreshDouyuCookie().catchError((_) {});
  }

  // 本地存储-> update Core-Site attrs
  void setDouyuCookie(String cookie) {
    if (cookie.isNotEmpty) {
      douyuCookie.value = cookie;
      LocalStorageService.instance.setValue(LocalStorageService.kDouyuCookie, douyuCookie.value);
      _updateDouyuAttr();
    }
  }

  // for douyu cookie
  Future<void> setDouyuDidAndLtp0(String did, String newLtp0) async {
    if (did.isNotEmpty) {
      dy_did = did;
      await LocalStorageService.instance.setValue(LocalStorageService.kDouyuDyDid, dy_did);
    }
    if (newLtp0.isNotEmpty) {
      dyLtp0 = newLtp0;
      await LocalStorageService.instance.setValue(LocalStorageService.kDouyuLTP0, dyLtp0);
    }
    // set and refresh
    _updateDouyuAttr();
    await _refreshDouyuCookie();
  }

  // 无论如何 都应检查cookie有效性后再保存
  // logic: 有效则不变，无效且配置did&ltp0并保存
  Future<void> _refreshDouyuCookie() async {
    final did = dy_did;
    final ltp = dyLtp0;
    var cookie = await _douyuSite.refreshCookie(did, ltp);
    if (did != dy_did || ltp != dyLtp0) return;
    if (did.isNotEmpty && ltp.isNotEmpty && cookie.isEmpty) {
      Log.w('斗鱼登录已失效，请重新登录');
    }
    setDouyuCookie(cookie);
  }

  /// Complete a passport login only after it produces a usable playback cookie.
  Future<bool> loginDouyuWithPassport(String did, String passportLtp0) async {
    final cookie = await _douyuSite.refreshCookie(did, passportLtp0, force: true);
    if (!cookie.split(';').any((part) => part.trim().startsWith('acf_jwt_token='))) {
      return false;
    }
    dy_did = did;
    dyLtp0 = passportLtp0;
    douyuCookie.value = cookie;
    await LocalStorageService.instance.setValue(LocalStorageService.kDouyuDyDid, did);
    await LocalStorageService.instance.setValue(LocalStorageService.kDouyuLTP0, passportLtp0);
    await LocalStorageService.instance.setValue(LocalStorageService.kDouyuCookie, cookie);
    _updateDouyuAttr();
    return true;
  }

  Future<void> douyuLogout() async {
    douyuCookie.value = "";
    dy_did = "";
    dyLtp0 = "";
    _updateDouyuAttr();
    await LocalStorageService.instance.setValue(LocalStorageService.kDouyuCookie, "");
    await LocalStorageService.instance.setValue(LocalStorageService.kDouyuDyDid, "");
    await LocalStorageService.instance.setValue(LocalStorageService.kDouyuLTP0, "");
    if (Platform.isAndroid || Platform.isIOS) {
      CookieManager cookieManager = CookieManager.instance();
      await cookieManager.deleteAllCookies();
    }
  }

  void _updateDouyuAttr() {
    Map<String, String> params = {
      'cookie': douyuCookie.value,
      'dy_did': dy_did,
      'ltp0': dyLtp0,
    };
    _douyuSite.setSiteAttrs(params);
  }

  // ==================== 生命周期 ====================

  @override
  void onInit() {
    _initDouyin();
    _initHuya();
    _initDouyu();
    super.onInit();
  }
}
