import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:simple_live_app/app/utils/extensions/duration_2_str_utils.dart';
import 'package:simple_live_app/models/db/history.dart';
import 'package:simple_live_app/modules/sync/remote_sync/webdav/interface/sync_resource.dart';
import 'package:simple_live_app/services/db_service.dart';

class HistorySyncResource implements SyncResource<List<History>> {
  @override
  String get fileName => "SimpleLive_histories.json";

  @override
  Future<List<History>> loadLocal() async {
    return DBService.instance.getHistories();
  }

  @override
  List<History>? loadRemote(Archive archive) {
    final file = archive.findFile(fileName);
    if (file == null) return null;
    final jsonData = jsonDecode(utf8.decode(file.content));
    return (jsonData['data'] as List).map((e) => History.fromJson(e)).toList();
  }

  @override
  Future<void> saveLocal(List<History> data) async {
    await DBService.instance.historyBox.clear();
    for (var item in data) {
      await DBService.instance.addOrUpdateHistory(item);
    }
  }

  @override
  void saveRemote(Archive archive, List<History> data) {
    final bytes = utf8.encode(jsonEncode({
      'data': data.map((e) => e.toJson()).toList(),
    }));
    archive.addFile(
      ArchiveFile(fileName, bytes.length, bytes),
    );
  }

  @override
  List<History> merge(List<History> local, List<History> remote) {
    final map = {for (final item in local) item.id: item};

    for (final remoteItem in remote) {
      final localItem = map[remoteItem.id];

      // 本地没有，直接使用远端
      if (localItem == null) {
        map[remoteItem.id] = remoteItem;
        continue;
      }

      final remoteSeconds = remoteItem.watchDuration?.toDuration().inSeconds ?? 0;
      final localSyncSeconds = localItem.syncDuration;

      // 如果远端时长和本地基础时长一致，取更新时间新的
      if (remoteItem.watchDuration == localItem.watchDuration && localSyncSeconds == 0) {
        map[remoteItem.id] = remoteItem.updateTime.isAfter(localItem.updateTime) ? remoteItem : localItem;
        continue;
      }

      // 合并最终时长 = 远端总时长 + 本地未同步增量
      final totalSeconds = remoteSeconds + localSyncSeconds;

      final mergeItem = remoteItem.updateTime.isAfter(localItem.updateTime) ? remoteItem : localItem;

      map[remoteItem.id] = localItem.copyWith(
        watchDuration: Duration(seconds: totalSeconds).toHMSString(),
        syncDuration: 0,
        updateTime: mergeItem.updateTime,
        roomId: mergeItem.roomId,
        siteId: mergeItem.siteId,
        userName: mergeItem.userName,
        face: mergeItem.face,
      );
    }

    final result = map.values.toList();
    result.sort((a, b) => b.updateTime.compareTo(a.updateTime));
    return result;
  }
}
