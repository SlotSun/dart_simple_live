import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/models/account/douyin_user_info.dart';
import 'package:simple_live_app/models/db/account.dart';
import 'package:simple_live_app/requests/common_request.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_app/services/local_storage_service.dart';
import 'package:simple_live_core/simple_live_core.dart';

class PlatformService extends GetxService {
  static PlatformService get instance => Get.find<PlatformService>();

  RxList<Account> accountList = RxList();

  void _initAccount() {
    accountList.value = DBService.instance.getAllAccounts();
  }

  // 更新指定的站点账户数据
  void updateAccount(Account ac) {
    accountList.assignAll(
      accountList.map((a) => a.id == ac.id ? ac : a).toList(),
    );
    DBService.instance.addAccount(ac);
  }

  void accountLogout(Account ac) {
    var logout = Account(
      id: ac.id,
      siteId: ac.siteId,
      credential: '',
      createdAt: ac.createdAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    updateAccount(logout);
  }

  Future<bool> accountLogin(Account ac) async {
    var site = Sites.allSites[ac.siteId]!;
    AccountInfo info = await site.liveSite.getAccountInfo(credential: ac.credential);
    if(!info.isValid){
      return false;
    }
    var resAc = ac.copyWith(
      userName: info.name,
      avatar: info.avatar,
      uid: info.uid,
      credential: info.credential,
    );
    updateAccount(resAc);
    site.liveSite.setSiteAttrs(resAc.credential);
    return true;
  }

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
    _douyinSite.setSiteAttrs(jsonEncode(params));
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
    if(cookie.isEmpty) return;
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
    _huyaSite.setSiteAttrs(jsonEncode(
      {
        'ua': ua,
      },
    ));
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


  // ==================== 生命周期 ====================

  @override
  void onInit() {
    _initAccount();
    // _initDouyin();
    // _initHuya();
    super.onInit();
  }
}
