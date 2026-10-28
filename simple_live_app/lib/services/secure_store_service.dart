import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/log.dart';

class SecureStoreService extends GetxService {
  static SecureStoreService get instance => Get.find<SecureStoreService>();

  // service: used by webdav, platform.service, like db and local
  // store: Safe key
  // app_settings_controller: secureKeepEnable == false
  // ui: try to open Safe-> input password by user or generate password
  // -> encode  platform_cookie and webdav_password -> save
  // -> decode platform_cookie and webdav_password -> save
  //
  final _secureStore = FlutterSecureStorage();
  static const _kAppSecret = 'SLIVE_APP_KEY';

  /// set app_secret_key
  Future<void> setAppSecretKey({String? secretKey}) async {
    Log.d("save secure store");
    await _secureStore.write(key: _kAppSecret, value: secretKey);
  }

  /// remove app_secret_key
  Future<void> removeAppSecretKey() async {
    Log.d("remove secure store");
    if (await _secureStore.containsKey(key: _kAppSecret)) {
      await _secureStore.delete(key: _kAppSecret);
    }
  }

  /// get app_secret_key
  Future<String?> getAppSecureKey({String path = ''}) async {
    Log.d("get secure store: $path");
    var secretKey = await _secureStore.read(key: _kAppSecret);
    return secretKey;
  }

  /// check app_secret_key
  Future<bool> checkAppSecureKey({required String secret}) async {
    var secretKey = await _secureStore.read(key: _kAppSecret);
    return secretKey == secret;
  }
}
