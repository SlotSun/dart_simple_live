import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/models/db/account.dart';
import 'package:simple_live_app/modules/sync/remote_sync/webdav/interface/sync_resource.dart';
import 'package:simple_live_app/services/db_service.dart';

class UserAccountCookieSyncResource implements SyncResource<List<Account>> {
  @override
  String get fileName => "slive_account.json";

  @override
  Future<List<Account>> loadLocal() async {
    return DBService.instance.getAllAccounts();
  }

  @override
  List<Account>? loadRemote(Archive archive) {
    final file = archive.findFile(fileName);
    if (file == null) return null;
    final jsonData = jsonDecode(utf8.decode(file.content))['data'];
    List<Account>? res = (jsonData as List).map((e) => Account.fromJson(e)).toList();
    return res;
  }

  @override
  Future<void> saveLocal(List<Account> data) async {
    // 这里会不会有风险？
    await DBService.instance.accountBox.clear();
    for (var item in data) {
      await DBService.instance.addAccount(item);
    }
    EventBus.instance.emit(Constant.kUpdateAccount, 0);;
  }

  @override
  void saveRemote(Archive archive, List<Account> data) {
    final bytes = utf8.encode(jsonEncode({
      'data': data.map((e) => e.toJson()).toList(),
    }));
    archive.addFile(
      ArchiveFile(fileName, bytes.length, bytes),
    );
  }

  @override
  List<Account> merge(List<Account> local, List<Account> remote) {
    final map = {for (final item in local) item.siteId: item};

    for (final account in remote) {
      final localAc = map[account.siteId]!;
      if (account.updatedAt > localAc.updatedAt) {
        map[account.siteId] = account;
      }
    }
    List<Account> res = map.values.toList();
    return res;
  }
}
