import 'package:get/get.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:simple_live_tv_app/app/constant.dart';
import 'package:simple_live_tv_app/app/sites.dart';
import 'package:simple_live_tv_app/services/local_storage_service.dart';

class DouyuAccountService extends GetxService {
  static DouyuAccountService get instance => Get.find<DouyuAccountService>();
  final cookie = ''.obs;
  String did = '';
  String ltp0 = '';
  final _site = Sites.allSites[Constant.kDouyu]!.liveSite as DouyuSite;
  final _storage = LocalStorageService.instance;

  @override
  void onInit() {
    super.onInit();
    cookie.value = _storage.getValue(LocalStorageService.kDouyuCookie, '');
    did = _storage.getValue(LocalStorageService.kDouyuDid, '');
    ltp0 = _storage.getValue(LocalStorageService.kDouyuLtp0, '');
    _site.onCookieRefreshed = _saveCookie;
    _updateSite();
  }

  Future<void> _saveCookie(String value) async {
    cookie.value = value;
    await _storage.setValue(LocalStorageService.kDouyuCookie, value);
  }

  void _updateSite() {
    _site.setSiteAttrs({'cookie': cookie.value, 'dy_did': did, 'ltp0': ltp0});
  }

  Future<bool> loginWithPassport(String deviceId, String passportLtp0) async {
    final value =
        await _site.refreshCookie(deviceId, passportLtp0, force: true);
    if (value.isEmpty) return false;
    did = deviceId;
    ltp0 = passportLtp0;
    await _storage.setValue(LocalStorageService.kDouyuDid, did);
    await _storage.setValue(LocalStorageService.kDouyuLtp0, ltp0);
    await _saveCookie(value);
    _updateSite();
    return true;
  }

  Future<void> logout() async {
    did = '';
    ltp0 = '';
    cookie.value = '';
    _updateSite();
    await _storage.setValue(LocalStorageService.kDouyuDid, '');
    await _storage.setValue(LocalStorageService.kDouyuLtp0, '');
    await _saveCookie('');
  }
}
