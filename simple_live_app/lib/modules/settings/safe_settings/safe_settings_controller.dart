import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/app/utils/encrypt/aes_util.dart';
import 'package:simple_live_app/services/safe_service.dart';
import 'package:simple_live_app/services/secure_store_service.dart';

class SafeSettingsController extends GetxController {
  static SafeSettingsController get instance => Get.find<SafeSettingsController>();

  Future<void> setStoreKey() async {
    TextEditingController textEditingController = TextEditingController();
    String? res = await Utils.showEditTextDialog('',
        title: '密钥',
        hintText: '请输入正确的密钥',
        textController: textEditingController,
        actions: [
          TextButton(
            onPressed: () async {
              var secret = await AesUtils.generateKey();
              textEditingController.text = secret;
            },
            child: const Text("生成密钥"),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: textEditingController.text));
              SmartDialog.showToast('复制成功');
            },
            child: const Text("复制"),
          ),
        ]);
    if (res != null) {
      if (!await validateAesKey(res)) {
        SmartDialog.showToast('密钥错误，请重新设置');
        Log.i('密钥错误，请重新设置');
        AppSettingsController.instance.appStoreKey.value = false;
        return;
      } else {
        await SecureStoreService.instance.setAppSecretKey(secretKey: res);
        AppSettingsController.instance.appStoreKey.value = true;
      }
    }
  }

  Future<void> removeStoreKey() async {
    if (AppSettingsController.instance.appSafeEnable.value) {
      SmartDialog.showToast('请先关闭加密数据功能!');
      return;
    }
    await SecureStoreService.instance.removeAppSecretKey();
    AppSettingsController.instance.appStoreKey.value = false;
  }

  Future<bool> validateAesKey(String key) async {
    if (key.isEmpty) {
      return false;
    }
    final Uint8List bytes;
    try {
      bytes = base64Decode(key);
      if (bytes.length != 32) {
        Log.i('密钥error: length_error!');
        return false;
      }
    } on FormatException {
      Log.i('密钥error: format_error!');
      return false;
    }
    // check decode
    if (AppSettingsController.instance.appSafeEnable.value) {
      try {
        String plain = await AesUtils.decrypt(AppSettingsController.instance.appAuthorName, key);
        return plain == 'AoZora';
      } catch (e) {
        Log.i('密钥error，checkDecode');
        return false;
      }
    }
    return true;
  }

  Future<void> decodeData() async {
    await SafeService.instance.decodeData();
  }

  Future<void> encodeData() async {
    await SafeService.instance.encodeData();
  }

  Future<void> reset() async {
    var res = await Utils.showAlertDialog(
      '确定重置敏感数据？会移除cookies/webdav/密钥！',
      title: '安全提醒',
    );
    if (res) {
      await SafeService.instance.reset();
    }
  }
}
