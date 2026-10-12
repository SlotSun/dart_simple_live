import 'dart:async';
import 'dart:convert';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/models/db/account.dart';
import 'package:simple_live_app/requests/common_request.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_app/services/local_storage_service.dart';
import 'package:simple_live_core/simple_live_core.dart';

class PlatformService extends GetxService {
  static PlatformService get instance => Get.find<PlatformService>();

  StreamSubscription<dynamic>? subscription;

  RxList<Account> accountList = RxList();

  void _initAccount() {
    accountList.value = DBService.instance.getAllAccounts();
    // 自动更新
    for (var account in accountList) {
      accountLogin(account);
    }
  }


  // 更新指定的站点账户数据
  Future<void> updateAccount(Account ac) async {
    accountList.assignAll(
      accountList.map((a) => a.id == ac.id ? ac : a).toList(),
    );
    accountList.refresh();
    await DBService.instance.addAccount(ac);
  }

  Future<void> accountLogout(Account ac) async {
    var logout = ac.copyWith(
      id: ac.id,
      userName: '',
      credential: '',
      isActive: false,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await updateAccount(logout);
  }

  Future<bool> accountLogin(Account ac) async {
    var site = Sites.allSites[ac.siteId]!;
    AccountInfo info = await site.liveSite.getAccountInfo(credential: ac.credential);
    var resAc = ac.copyWith(
      userName: info.name,
      avatar: info.avatar,
      uid: info.uid,
      credential: info.credential,
      isActive: info.isValid,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await updateAccount(resAc);
    site.liveSite.setSiteAttrs(resAc.credential);
    if(!info.isValid){
      SmartDialog.showToast('${site.name}账号失效，请重新设置');
    }
    return info.isValid;
  }

  // ==================== 抖音 ====================

  final _douyinSite = (Sites.allSites[Constant.kDouyin]!.liveSite as DouyinSite);
  void _updateDouyinAttr() {
    var douyinHlsFirst = LocalStorageService.instance.getValue(LocalStorageService.kDouyinHlsFirst, false);
    Map<String, dynamic> params = {
      'hlsFirst': douyinHlsFirst,
    };
    _douyinSite.setSiteAttrs(jsonEncode(params));
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
    subscription = EventBus.instance.listen(Constant.kUpdateAccount, (data) {
      Log.i('update Account');
      _initAccount();
    });
    _initAccount();
    _updateDouyinAttr();
    _initHuya();
    super.onInit();
  }

  @override
  void onClose(){
    subscription?.cancel();
  }
}
