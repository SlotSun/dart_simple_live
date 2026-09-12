import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/utils/extensions/duration_2_str_utils.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/db/follow_user_tag.dart';
import 'package:simple_live_app/modules/sync/remote_sync/webdav/interface/sync_resource.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_app/services/local_storage_service.dart';

class FollowBundle {
  final List<FollowUser> follows;
  final List<FollowUserTag> tags;

  FollowBundle({
    List<FollowUser>? follows,
    List<FollowUserTag>? tags,
  })  : follows = follows ?? [],
        tags = tags ?? [];
}

class FollowSyncResource implements SyncResource<FollowBundle> {
  @override
  String get fileName => "SimpleLive_follows.json";

  String get tagFileName => "SimpleLive_Tags.json";

  @override
  Future<FollowBundle> loadLocal() async {
    // 同步时加载所有记录（包含墓碑），确保墓碑可以传播到其他设备
    var followList = DBService.instance.getAllFollowList();
    var tagList = DBService.instance.getFollowTagList();
    return FollowBundle(
      follows: followList,
      tags: tagList,
    );
  }

  @override
  FollowBundle? loadRemote(Archive archive) {
    final followFile = archive.findFile(fileName);
    final tagFile = archive.findFile(tagFileName);
    if (followFile == null || tagFile == null) return null;

    final followJsonData = jsonDecode(utf8.decode(followFile.content));
    var followRemoteList = (followJsonData['data'] as List).map((e) => FollowUser.fromJson(e)).toList();
    final tagJsonData = jsonDecode(utf8.decode(tagFile.content));
    var tagRemoteList = (tagJsonData['data'] as List).map((e) => FollowUserTag.fromJson(e)).toList();
    return FollowBundle(
      follows: followRemoteList,
      tags: tagRemoteList,
    );
  }

  @override
  Future<void> saveLocal(FollowBundle data) async {
    await DBService.instance.followBox.clear();
    for (final item in data.follows) {
      await DBService.instance.followBox.put(item.id, item);
    }
    await DBService.instance.tagBox.clear();
    for (final tag in data.tags) {
      await DBService.instance.tagBox.put(tag.id, tag);
    }
    EventBus.instance.emit(Constant.kUpdateFollow, 0);
  }

  @override
  void saveRemote(Archive archive, FollowBundle data) {
    final followBytes = utf8.encode(jsonEncode({
      'data': data.follows.map((e) => e.toJson()).toList(),
    }));

    archive.addFile(
      ArchiveFile(
        fileName,
        followBytes.length,
        followBytes,
      ),
    );

    final tagBytes = utf8.encode(jsonEncode({
      'data': data.tags.map((e) => e.toJson()).toList(),
    }));

    archive.addFile(
      ArchiveFile(
        tagFileName,
        tagBytes.length,
        tagBytes,
      ),
    );
  }

  @override
  FollowBundle merge(
    FollowBundle local,
    FollowBundle remote,
  ) {
    DateTime curLast = DateTime.fromMillisecondsSinceEpoch(
      LocalStorageService.instance.getValue(
        LocalStorageService.kWebDAVLastRecoverTime,
        DateTime(2026, 1, 1).millisecondsSinceEpoch,
      ),
    );
    var resFollows = _mergeFollowList(localList: local.follows, remoteList: remote.follows, curLast: curLast);

    // tags after merge, logic from data_check
    final Map<String, List<String>> tagMap = {
      for (var tag in local.tags) tag.tag: <String>[],
    };

    for (var follow in resFollows) {
      if (follow.tag != "全部") {
        tagMap.putIfAbsent(follow.tag, () => <String>[]).add(follow.id);
      }
    }
    final resTags = <FollowUserTag>[];
    String? lastKey;
    for (var entry in tagMap.entries) {
      lastKey = FractionalIndexing.generateKeyBetween(lastKey, null);
      final followUserTag = FollowUserTag(
        id: lastKey,
        tag: entry.key,
        userId: entry.value,
      );
      resTags.add(followUserTag);
    }
    return FollowBundle(follows: resFollows, tags: resTags);
  }

  // sync-double
  // database op-log maybe better
  // follow: cur! and webdav! -> keep;
  // follow: cur! and webdav? -> cur_item.add_time>cur_last->keep; else->remove;
  // follow: cur? and webdav! -> remote.item.add_time>cur_last->keep; else->remove
  //
  // tombstone logic:
  // follow.deleted=true means the user was unfollowed
  // follow.updateTime stores the timestamp of the unfollow
  //
  // follow_watchDuration = webdav_watchDuration += syncDuration
  // syncDuration = 0
  List<FollowUser> _mergeFollowList({
    required List<FollowUser> localList,
    required List<FollowUser> remoteList,
    required DateTime curLast,
  }) {
    final Map<String, FollowUser> result = {};
    final localMap = {for (var item in localList) item.id: item};
    final remoteMap = {for (var item in remoteList) item.id: item};
    final curLastSec = curLast.millisecondsSinceEpoch ~/ 1000;

    for (var localItem in localList) {
      var remoteItem = remoteMap[localItem.id];
      if (remoteItem != null) {
        // 两边都有记录，需要合并
        if (localItem.deleted && remoteItem.deleted) {
          // 两边都是墓碑，保留 updateTime 更新的
          result[localItem.id] = localItem.updateTime >= remoteItem.updateTime ? localItem : remoteItem;
        } else if (localItem.deleted) {
          // 本地是墓碑，远程是正常记录
          // 如果本地墓碑时间晚于远程添加时间，则保留墓碑
          if (localItem.updateTime >= remoteItem.addTime.millisecondsSinceEpoch ~/ 1000) {
            result[localItem.id] = localItem;
          } else {
            // 远程重新关注了，清除墓碑
            remoteItem.deleted = false;
            remoteItem.updateTime = 0;
            result[remoteItem.id] = remoteItem;
          }
        } else if (remoteItem.deleted) {
          // 远程是墓碑，本地是正常记录
          // 如果远程墓碑时间晚于本地添加时间，则应用远程墓碑
          if (remoteItem.updateTime >= localItem.addTime.millisecondsSinceEpoch ~/ 1000) {
            result[remoteItem.id] = remoteItem;
          } else {
            // 本地重新关注了，保留本地
            result[localItem.id] = localItem;
          }
        } else {
          // 两边都是正常记录，合并观看时长
          localItem.watchDurationSec = remoteItem.watchDurationSec + localItem.syncDuration;
          localItem.watchDuration = Duration(seconds: localItem.watchDurationSec).toHMSString();
          localItem.syncDuration = 0;
          result[localItem.id] = localItem;
        }
      } else {
        // 仅本地有记录
        if (localItem.deleted) {
          // 本地是墓碑，如果墓碑时间在上次同步之后，保留墓碑以传播到其他设备
          if (localItem.updateTime > curLastSec) {
            result[localItem.id] = localItem;
          }
          // 否则墓碑已过期，不需要保留
        } else {
          // 本地是正常记录，如果添加时间在上次同步之后，保留
          if (localItem.addTime.isAfter(curLast)) {
            result[localItem.id] = localItem;
          }
        }
      }
    }

    for (var remoteItem in remoteList) {
      if (!localMap.containsKey(remoteItem.id)) {
        // 仅远程有记录
        if (remoteItem.deleted) {
          // 远程是墓碑，如果墓碑时间在上次同步之后，保留墓碑
          if (remoteItem.updateTime > curLastSec) {
            result[remoteItem.id] = remoteItem;
          }
        } else {
          // 远程是正常记录，如果添加时间在上次同步之后，保留
          if (remoteItem.addTime.isAfter(curLast)) {
            result[remoteItem.id] = remoteItem;
          }
        }
      }
    }
    return result.values.toList();
  }
}
