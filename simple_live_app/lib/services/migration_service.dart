import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/app/utils/duration_2_str_utils.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/db/follow_user_tag.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/services/local_storage_service.dart';

class MigrationService {
  /// 将Hive数据迁移到Application Support
  static Future migrateData() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return;
    }
    var hiveFileList = [
      "followuser",
      //旧版本写错成hostiry了
      "hostiry",
      "followusertag",
      "localstorage",
      "danmushield",
    ];
    try {
      var newDir = await getApplicationSupportDirectory();
      var hiveFile = File(p.join(newDir.path, "followuser.hive"));
      if (await hiveFile.exists()) {
        return;
      }

      var oldDir = await getApplicationDocumentsDirectory();
      for (var element in hiveFileList) {
        var oldFile = File(p.join(oldDir.path, "$element.hive"));
        if (await oldFile.exists()) {
          var fileName = "$element.hive";
          if (element == "hostiry") {
            fileName = "history.hive";
          }
          await oldFile.copy(p.join(newDir.path, fileName));
          await oldFile.delete();
        }
        var lockFile = File(p.join(oldDir.path, "$element.lock"));
        if (await lockFile.exists()) {
          await lockFile.delete();
        }
      }
    } catch (e) {
      Log.logPrint(e);
    }
  }

  /// 数据迁移根据版本：from 1.7.8
  static Future<void> migrateDataByVersion() async {
    int curAppVer = Utils.parseVersion(Utils.packageInfo.version);
    int curDBVer = LocalStorageService.instance
        .getValue(LocalStorageService.kHiveDbVer, 10708);
    Log.i("curDBVer: $curDBVer, curAppVer: $curAppVer");
    if (curDBVer <= 10708) {
      LocalStorageService.instance.settingsBox
          .delete(LocalStorageService.kWebDAVLastUploadTime);
      LocalStorageService.instance.settingsBox
          .delete(LocalStorageService.kWebDAVLastRecoverTime);
    }
    // follow_user 添加 tag属性
    // 从followUserTag 读取 标签
    if (curDBVer <= 10709) {
      List tagList = DBService.instance.tagBox.values.toList();
      List<FollowUser> followList =
          DBService.instance.followBox.values.toList();
      for (int i = 0; i < followList.length; i++) {
        for (FollowUserTag tag in tagList) {
          if (tag.userId.contains(followList[i].id)) {
            followList[i].tag = tag.tag;
            DBService.instance.addFollow(followList[i]);
            break;
          }
        }
      }
    }
    // sortkey-romanName
    if (curDBVer <= 10805) {
       await FollowService.instance.followUserAllDataCheck();
    }

    // migrate follow.watchDuration -> follow.watchDurationSec
    // easy to calculate
    // delete this attribute after v10810, I think
    // hive logic temp:
    // old: watchDuration: fields[6] == null ? "00:00:00" : fields[6] as String?
    // new: otherAtr(any type): fields[6] == null ? anyTypeValue : fields[6] as String to anyType
    // String to int: like watchDurationSec, String.toDuration.toInt
    if(curDBVer <= 10807){
      var followList = DBService.instance.followBox.values.toList();
      for (FollowUser follow in followList) {
        follow.watchDurationSec = follow.watchDuration!.toDuration().inSeconds;
        DBService.instance.addFollow(follow);
      }
    }
    // set follow.lastWatchTime as cur timestamp after v10810
    if (curDBVer <= 10809) {
      var followList = DBService.instance.followBox.values.toList();
      var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      for (FollowUser follow in followList) {
        if (follow.lastWatchTime == 0) {
          follow.lastWatchTime = now;
          DBService.instance.addFollow(follow);
        }
      }
      Log.i("Migration: initialized lastWatchTime for ${followList.length} follows");
    }
    LocalStorageService.instance.settingsBox
        .put(LocalStorageService.kHiveDbVer, curAppVer);
  }
}
