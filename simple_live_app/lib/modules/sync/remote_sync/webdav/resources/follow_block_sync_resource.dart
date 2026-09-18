import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:simple_live_app/models/db/follow_user_block.dart';
import 'package:simple_live_app/modules/sync/remote_sync/webdav/interface/sync_resource.dart';
import 'package:simple_live_app/services/db_service.dart';

class FollowBlockSyncResource implements SyncResource<List<FollowUserBlock>> {
  @override
  String get fileName => "SimpleLive_follow_blocks.json";

  @override
  Future<List<FollowUserBlock>> loadLocal() async {
    return DBService.instance.getAllFollowUserBlocks();
  }

  @override
  List<FollowUserBlock>? loadRemote(Archive archive) {
    final file = archive.findFile(fileName);
    if (file == null) return null;
    final jsonData = jsonDecode(utf8.decode(file.content));
    return (jsonData['data'] as List).map((e) => FollowUserBlock.fromJson(e)).toList();
  }

  @override
  Future<void> saveLocal(List<FollowUserBlock> data) async {
    await DBService.instance.followUserBlockBox.clear();
    for (final item in data) {
      await DBService.instance.followUserBlockBox.put(item.id, item);
    }
  }

  @override
  void saveRemote(Archive archive, List<FollowUserBlock> data) {
    final bytes = utf8.encode(jsonEncode({
      'data': data.map((e) => e.toJson()).toList(),
    }));
    archive.addFile(
      ArchiveFile(fileName, bytes.length, bytes),
    );
  }

  @override
  List<FollowUserBlock> merge(
    List<FollowUserBlock> local,
    List<FollowUserBlock> remote,
  ) {
    final Map<String, FollowUserBlock> result = {};
    for (var item in local) {
      result[item.id] = item;
    }
    for (var item in remote) {
      final existing = result[item.id];
      if (existing == null || item.updateTime > existing.updateTime) {
        result[item.id] = item;
      }
    }
    return result.values.toList();
  }
}
