import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils/encrypt/aes_util.dart';
import 'package:simple_live_app/models/db/account.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_app/services/local_storage_service.dart';
import 'package:simple_live_app/services/secure_store_service.dart';

class SafeService extends GetxService {
  static SafeService get instance => Get.find<SafeService>();

  // 统一管理需要加密的数据源

  /// 获取所有的解密账号
  Future<List<Account>> getDecodeAccounts() async {
    List<Account> list = DBService.instance.getAllAccounts();
    if (AppSettingsController.instance.appSafeEnable.value) {
      for (int i = 0; i < list.length; i++) {
        Account account = list[i];
        if (AppSettingsController.instance.appStoreKey.value) {
          var key = await SecureStoreService.instance.getAppSecureKey();
          try {
            account.credential = await AesUtils.decrypt(account.credential, key!);
          } catch (e, s) {
            Log.e('decode_account_credential: $e', s);
          }
        } else {
          list[i] = account.copyWith(
            id: account.id,
            userName: '',
            credential: '',
            isActive: false,
          );
        }
      }
    }
    return list;
  }

  /// 加密指定账号
  Future<void> encodeAccount(Account ac) async {
    var plainCredential = ac.credential;
    // 加密模式, 尝试写入, 无key直接重置所有数据
    if (AppSettingsController.instance.appSafeEnable.value) {
      if (AppSettingsController.instance.appStoreKey.value) {
        var key = await SecureStoreService.instance.getAppSecureKey();
        plainCredential = await AesUtils.encrypt(plainCredential, key!);
      } else {
        await reset();
      }
    }
    var dbAc = DBService.instance.getAccount(ac.id);
    // credential 更新入库
    if (dbAc.credential != plainCredential) {
      var itemAc = ac.copyWith(credential: plainCredential);
      await DBService.instance.addAccount(itemAc);
    }
  }

  /// webdavPassword
  Future<String> getDecodeWPassword() async {
    var wPassword = LocalStorageService.instance.getValue(LocalStorageService.kWebDAVPassword, '');
    if (wPassword.isNotEmpty && AppSettingsController.instance.appSafeEnable.value) {
      if (AppSettingsController.instance.appStoreKey.value) {
        var secretKey = await SecureStoreService.instance.getAppSecureKey();
        try {
          wPassword = await AesUtils.decrypt(wPassword, secretKey!);
        } catch (e) {
          wPassword = '';
        }
      } else {
        wPassword = '';
      }
    }
    return wPassword;
  }

  Future<void> encodeWPassword(String wPassword) async {
    if (wPassword.isNotEmpty) {
      // 逻辑同 encodeAccount
      if (AppSettingsController.instance.appSafeEnable.value) {
        if (AppSettingsController.instance.appStoreKey.value) {
          var secretKey = await SecureStoreService.instance.getAppSecureKey();
          wPassword = await AesUtils.encrypt(wPassword, secretKey!);
        } else {
          await reset();
        }
      }
    }
    LocalStorageService.instance.setValue(LocalStorageService.kWebDAVPassword, wPassword);
  }

  Future<void> decodeData() async {
    // check secretKey right-> decode
    var secretKey = await SecureStoreService.instance.getAppSecureKey();
    if (secretKey != null && secretKey.isNotEmpty) {
      // decode account.credential
      List<Account> accounts = DBService.instance.getAllAccounts();
      for (final account in accounts) {
        if (account.credential.isEmpty) {
          continue;
        }
        try {
          String plain = await AesUtils.decrypt(account.credential, secretKey);
          Account upgradeAc = account.copyWith(credential: plain);
          await DBService.instance.addAccount(upgradeAc);
        } catch (e) {
          // error ( secretKey wrong/ data bad / plain )
          debugPrint('decode error id=${account.id}: $e');
        }
      }
      // decode webdev.password
      String wPassword = LocalStorageService.instance.getValue(LocalStorageService.kWebDAVPassword, "");
      if (wPassword.isNotEmpty) {
        try {
          String plain = await AesUtils.decrypt(wPassword, secretKey);
          LocalStorageService.instance.setValue(LocalStorageService.kWebDAVPassword, plain);
        } catch (e, s) {
          Log.e('decode_webdav_password: $e', s);
        }
      }

      AppSettingsController.instance.setAppAuthorName('AoZora');
      AppSettingsController.instance.setAppSafeEnable(false);
      SmartDialog.showToast('已解密敏感数据');
    }
  }

  Future<void> encodeData() async {
    var secretKey = await SecureStoreService.instance.getAppSecureKey();
    if (secretKey != null && secretKey.isNotEmpty) {
      List<Account> accounts = DBService.instance.getAllAccounts();
      for (final account in accounts) {
        if (account.credential.isEmpty) {
          continue;
        }
        try {
          String plain = await AesUtils.encrypt(account.credential, secretKey);
          Account upgradeAc = account.copyWith(credential: plain);
          await DBService.instance.addAccount(upgradeAc);
        } catch (e) {
          // error ( secretKey wrong/ data bad / plain )
          debugPrint('encode error id=${account.id}: $e');
        }
      }
      // encode webdev.password
      String wPassword = LocalStorageService.instance.getValue(LocalStorageService.kWebDAVPassword, "");
      if (wPassword.isNotEmpty) {
        String plain = await AesUtils.encrypt(wPassword, secretKey);
        LocalStorageService.instance.setValue(LocalStorageService.kWebDAVPassword, plain);
      }

      String authorName = await AesUtils.encrypt(AppSettingsController.instance.appAuthorName, secretKey);
      AppSettingsController.instance.setAppAuthorName(authorName);
      AppSettingsController.instance.setAppSafeEnable(true);
      SmartDialog.showToast('已加密敏感数据');
    } else {
      SmartDialog.showToast('key无效');
    }
  }

  /// 检查数据和key关联性
  Future<void> checkKeyValid() async {
    var res = false;
    var secretKey = await SecureStoreService.instance.getAppSecureKey();
    if (secretKey != null && secretKey.isNotEmpty) {
      // check decode
      if (AppSettingsController.instance.appSafeEnable.value) {
        try {
          String plain = await AesUtils.decrypt(AppSettingsController.instance.appAuthorName, secretKey);
          res = plain == 'AoZora';
        } catch (e) {
          res = false;
        }
      } else {
        res = true;
      }
    } else {
      res = false;
    }
    AppSettingsController.instance.appStoreKey.value = res;
  }

  /// 重置所有敏感数据
  Future<void> reset() async {
    List<Account> list = DBService.instance.getAllAccounts();
    for (final account in list) {
      var logout = account.copyWith(
        id: account.id,
        userName: '',
        credential: '',
        isActive: false,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await DBService.instance.addAccount(logout);
    }
    await SecureStoreService.instance.removeAppSecretKey();
    LocalStorageService.instance.setValue(LocalStorageService.kWebDAVPassword, '');
    AppSettingsController.instance.setAppAuthorName('AoZora');
    AppSettingsController.instance.setAppSafeEnable(false);
    AppSettingsController.instance.appStoreKey.value = false;
    SmartDialog.showToast('已重置敏感数据');
  }

  @override
  Future<void> onInit() async {
    await checkKeyValid();
    super.onInit();
  }
}
