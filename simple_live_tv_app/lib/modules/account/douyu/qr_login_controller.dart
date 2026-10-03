import 'dart:async';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:simple_live_tv_app/app/app_focus_node.dart';
import 'package:simple_live_tv_app/services/douyu_account_service.dart';

class DouyuQRLoginController extends GetxController {
  final backFocus = AppFocusNode();
  final refreshFocus = AppFocusNode();
  final logoutFocus = AppFocusNode();
  final qrUrl = ''.obs;
  final message = '正在获取斗鱼二维码…'.obs;
  final loading = false.obs;
  DouyuQrLogin? _session;
  Timer? _timer;
  bool _checking = false;

  @override
  void onInit() {
    super.onInit();
    refreshQrCode();
  }

  Future<void> refreshQrCode() async {
    _timer?.cancel();
    _session?.close();
    final session = DouyuQrLogin();
    _session = session;
    qrUrl.value = '';
    loading.value = true;
    message.value = '正在获取斗鱼二维码…';
    try {
      final url = await session.generate();
      if (isClosed || _session != session) return;
      qrUrl.value = url;
      message.value = '用另一台设备上的斗鱼 APP 扫码，然后确认登录';
      _timer =
          Timer.periodic(const Duration(seconds: 2), (_) => _poll(session));
    } catch (_) {
      if (!isClosed && _session == session) message.value = '二维码加载失败，请刷新重试';
    } finally {
      if (!isClosed && _session == session) loading.value = false;
    }
  }

  Future<void> _poll(DouyuQrLogin session) async {
    if (_checking || isClosed || _session != session) return;
    _checking = true;
    try {
      final status = await session.poll();
      if (isClosed || _session != session) return;
      switch (status) {
        case DouyuQrStatus.waiting:
          break;
        case DouyuQrStatus.scanned:
          message.value = '已扫码，请在手机上确认登录';
          break;
        case DouyuQrStatus.expired:
          _timer?.cancel();
          qrUrl.value = '';
          message.value = '二维码已过期，请刷新';
          break;
        case DouyuQrStatus.authorized:
          _timer?.cancel();
          message.value = '正在保存登录信息…';
          final success = await DouyuAccountService.instance
              .loginWithPassport(session.did, session.ltp0);
          if (isClosed || _session != session) return;
          if (success) {
            SmartDialog.showToast('斗鱼登录成功，已保存自动续期凭据');
            Get.back();
          } else {
            message.value = '登录凭据未生效，请刷新二维码重试';
          }
      }
    } catch (_) {
      if (!isClosed && _session == session) message.value = '登录确认失败，请刷新二维码重试';
    } finally {
      _checking = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    _session?.close();
    backFocus.dispose();
    refreshFocus.dispose();
    logoutFocus.dispose();
    super.onClose();
  }
}
