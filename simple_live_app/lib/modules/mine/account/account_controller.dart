import 'dart:convert';
import 'dart:io';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/models/db/account.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/services/platform_service.dart';

class AccountController extends GetxController {
  // refactor: widget-> util.showBottomSheet()-> decide args/qr/web
  // widget_detail: onTap()->login->out / onTap()->noLogin->util.showBottomSheet()
  //
  var accountList = PlatformService.instance.accountList;
  late Account curAccount;
  late Site site;

  void tap(Account ac) async {
    curAccount = ac;
    site = Sites.allSites[curAccount.siteId]!;
    if (ac.credential.isNotEmpty) {
      var result = await Utils.showAlertDialog("确定要退出${site.name}账号吗？", title: "退出登录");
      if (result) {
        await PlatformService.instance.accountLogout(ac);
      }
    } else {
      login();
    }
  }

  void login() {
    Utils.showBottomSheet(
      title: "登录${site.name}",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Visibility(
            visible: (Platform.isAndroid || Platform.isIOS) && site.id == Constant.kBiliBili,
            child: ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text("Web登录"),
              subtitle: const Text("填写用户名密码登录"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                Get.toNamed(RoutePath.kBiliBiliWebLogin);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text("扫码登录"),
            subtitle: Text("使用${site.name}APP扫描二维码登录"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Get.back();
              AppNavigator.toQRCoreLogin(account: curAccount);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text("Cookie登录"),
            subtitle: const Text("手动输入Cookie登录"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Get.back();
              doLogin();
            },
          ),
        ],
      ),
    );
  }

  void doLogin() async {
    final params = await Utils.showEditTextsDialog(
      [
        TextEditItem(
          value: '',
          label: 'cookie',
          hintText: 'dy_did=...; acf_did=...;etc',
          key: 'cookie',
        ),
        if (site.id == Constant.kDouyu) ...[
          TextEditItem(
            value: '',
            label: 'dy_did',
            hintText: '10000000000000000000000000001501',
            key: 'dy_did',
          ),
          TextEditItem(
            value: '',
            label: 'ltp0',
            hintText: '自动更新cookie',
            obscureText: true,
            key: 'ltp0',
          ),
        ]
      ],
      title: '请输入${site.name}参数',
    );
    if (params == null || params.isEmpty) {
      return;
    }
    var res = await PlatformService.instance.accountLogin(curAccount.copyWith(credential: jsonEncode(params)));
    if (res) {
      SmartDialog.showToast('${site.name}登录成功!');
    } else {
      SmartDialog.showToast('${site.name}参数认证错误，请重新设置');
    }
  }

  // 需要用户手动复制抖音的Cookie
  void douyinTap() async {
    if (PlatformService.instance.douyinLogined.value) {
      var result = await Utils.showAlertDialog("确定要清除抖音Cookie吗？", title: "清除Cookie");
      if (result) {
        PlatformService.instance.douyinLogout();
      }
    } else {
      final cookie = await Utils.showEditTextDialog(
        "",
        title: "请输入抖音Cookie",
        hintText: "__ac_signature=...;sessionid=...;",
      );
      if (cookie == null || cookie.isEmpty) return;
      PlatformService.instance.setDouyinCookie(cookie);
      // 检查输入的cookie是否有效
      await PlatformService.instance.loadDouyinUserInfo();
    }
  }
}
