import 'dart:async';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:simple_live_tv_app/app/sites.dart';
import 'package:simple_live_tv_app/models/db/account.dart';
import 'package:simple_live_tv_app/services/db_service.dart';

class PlatformService extends GetxService {
  static PlatformService get instance => Get.find<PlatformService>();

  RxList<Account> accountList = RxList();

  void initAccount() {
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

  @override
  void onInit() {
    initAccount();
    super.onInit();
  }
}
