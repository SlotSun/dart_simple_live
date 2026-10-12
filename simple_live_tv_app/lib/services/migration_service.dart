import 'package:simple_live_tv_app/app/constant.dart';
import 'package:simple_live_tv_app/app/utils.dart';
import 'package:simple_live_tv_app/models/db/account.dart';

import 'db_service.dart';
import 'local_storage_service.dart';

class MigrationService {
  static Future<void> migrateDataByVersion() async {

    int curAppVer = Utils.parseVersion(Utils.packageInfo.version);
    int curDBVer = LocalStorageService.instance.getValue('kHiveDbVer', 10500);

    if(curDBVer < 10501){
      var curTime = DateTime.now().millisecondsSinceEpoch;
      var accountList = DBService.instance.getAllAccounts();
      var existingSiteIds = accountList.map((e) => e.siteId).toSet();

      final defaults = [
        Account(
          id: '0',
          siteId: Constant.kBiliBili,
          credential: '',
          createdAt: curTime,
          updatedAt: curTime,
        ),
        Account(
            id: '1',
            siteId: Constant.kDouyu,
            credential: '',
            isActive: false,
            createdAt: curTime,
            updatedAt: curTime),
      ];

      for (final ac in defaults) {
        if (existingSiteIds.contains(ac.siteId) == false) {
          DBService.instance.addAccount(ac);
        }
      }
    }
    LocalStorageService.instance.settingsBox.put('kHiveDbVer', curAppVer);
  }
}