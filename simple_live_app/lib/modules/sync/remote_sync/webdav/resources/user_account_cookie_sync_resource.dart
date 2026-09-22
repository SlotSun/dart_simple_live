import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:simple_live_app/modules/sync/remote_sync/webdav/interface/sync_resource.dart';
import 'package:simple_live_app/services/bilibili_account_service.dart';
import 'package:simple_live_app/services/local_storage_service.dart';
import 'package:simple_live_app/services/platform_service.dart';

class UserAccountCookieSyncResource implements SyncResource<Map<String, String?>> {
  @override
  String get fileName => "SimpleLive_bilibili_account.json";

  @override
  Future<Map<String, String?>> loadLocal() async {
    return {
      'cookie': LocalStorageService.instance.getNullValue(LocalStorageService.kBilibiliCookie, null),
      'douyin_cookie': LocalStorageService.instance.getNullValue(LocalStorageService.kDouyinCookie, null),
      'douyu_cookie': LocalStorageService.instance.getNullValue(LocalStorageService.kDouyuCookie, null),
    };
  }

  @override
  Map<String, String?>? loadRemote(Archive archive) {
    final file = archive.findFile(fileName);
    if (file == null) return null;
    final jsonData = jsonDecode(utf8.decode(file.content))['data'];
    return {
      'cookie': jsonData['cookie'],
      'douyin_cookie': jsonData['douyin_cookie'],
      'douyu_cookie': jsonData['douyu_cookie'],
    };
  }

  @override
  Future<void> saveLocal(Map<String, String?> data) async {
    if (data['cookie'] != null) {
      BiliBiliAccountService.instance.setCookie(data['cookie']!);
      BiliBiliAccountService.instance.loadUserInfo();
    }
    if (data['douyin_cookie'] != null) {
      PlatformService.instance.setDouyuCookie(data['douyin_cookie']!);
    }
    if (data['douyu_cookie'] != null) {
      PlatformService.instance.setDouyuCookie(data['douyu_cookie']!);
    }
  }

  @override
  void saveRemote(Archive archive, Map<String, String?> data) {
    final bytes = utf8.encode(jsonEncode({
      'data': data,
    }));
    archive.addFile(
      ArchiveFile(fileName, bytes.length, bytes),
    );
  }

  @override
  Map<String, String?> merge(Map<String, String?> local, Map<String, String?> remote) {
    return {...local, ...remote};
  }
}
