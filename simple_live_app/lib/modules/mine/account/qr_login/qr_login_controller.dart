import 'dart:async';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/models/db/account.dart';
import 'package:simple_live_app/services/platform_service.dart';
import 'package:simple_live_core/simple_live_core.dart';

class QRLoginController extends GetxController {
  Account account = Get.arguments;
  late Site site;
  @override
  void onInit() {
    site = Sites.allSites[account.siteId]!;
    loadQRCode();
    super.onInit();
  }

  Timer? timer;

  var qrcodeUrl = "".obs;
  var qrcodeKey = "";

  /// 二维码状态
  /// - [0] 加载中
  /// - [1] 未扫描
  /// - [2] 已扫描，待确认
  /// - [3] 二维码已经失效
  /// - [4] 登录失败
  Rx<QRStatus> qrStatus = QRStatus.loading.obs;

  void loadQRCode() async {
    try {
      qrStatus.value = QRStatus.loading;
      var result = await site.liveSite.getQRCode();
      qrcodeKey = result.key;
      qrcodeUrl.value = result.url;
      qrStatus.value = QRStatus.unscanned;
      startPoll();
    } catch (e) {
      Log.logPrint(e);
      SmartDialog.showToast(e.toString());
      qrStatus.value = QRStatus.failed;
    }
  }

  void startPoll() {
    timer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) {
        pollQRStatus();
      },
    );
  }

  void pollQRStatus() async {
    try {
      var result = await site.liveSite.getQRPollResult(qrcodeKey: qrcodeKey);
      qrStatus.value = result.status;
      if (result.credential.isNotEmpty) {
        await PlatformService.instance.accountLogin(account.copyWith(credential: result.credential));
        Get.back();
      }
    } catch (e) {
      Log.logPrint(e);
      SmartDialog.showToast(e.toString());
    }
  }

  @override
  void onClose() {
    timer?.cancel();
    super.onClose();
  }
}
