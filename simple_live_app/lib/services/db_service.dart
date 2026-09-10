import 'dart:async';

import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/db/follow_user_block.dart';
import 'package:simple_live_app/models/db/follow_user_tag.dart';
import 'package:simple_live_app/models/db/history.dart';
import 'package:collection/collection.dart';

class DBService extends GetxService {
  static DBService get instance => Get.find<DBService>();
  late Box<History> historyBox;
  late Box<FollowUser> followBox;
  late Box<FollowUserTag> tagBox;
  late Box<FollowUserBlock> followUserBlockBox;

  Future init() async {
    historyBox = await Hive.openBox("History");
    followBox = await Hive.openBox("FollowUser");
    tagBox = await Hive.openBox("FollowUserTag");
    followUserBlockBox = await Hive.openBox("FollowUserBlock");
  }

  Future<void> clearFollowTag() async {
    await tagBox.clear();
  }

  bool getFollowTagExist(String id) {
    return tagBox.containsKey(id);
  }

  List<FollowUserTag> getFollowTagList() {
    return tagBox.values.toList();
  }

  Future updateFollowTag(FollowUserTag followTag) async {
    await tagBox.put(followTag.id, followTag);
  }

  Future<FollowUserTag> addFollowTag(String tag) async {
    // 查找数据库中是否已存在 存在则直接返回
    if (getFollowTagExistByTag(tag)) {
      return getFollowTag(tag)!;
    }
    String? lastKey = tagBox.keys.lastOrNull;
    final String uniqueId =
        FractionalIndexing.generateKeyBetween(lastKey, null);
    final followUserTag = FollowUserTag(id: uniqueId, tag: tag, userId: []);
    await tagBox.put(uniqueId, followUserTag);
    return followUserTag;
  }

  Future deleteFollowTag(String id) async {
    await tagBox.delete(id);
  }

  FollowUserTag? getFollowTag(String tag) {
    return tagBox.values.firstWhereOrNull((item) => item.tag == tag);
  }

  // 判断tag名称是否重复
  bool getFollowTagExistByTag(String tag) {
    return tagBox.values.any((item) => item.tag == tag);
  }

  bool getFollowExist(String id) {
    var follow = followBox.get(id);
    return follow != null && !follow.deleted;
  }

  List<FollowUser> getFollowList() {
    return followBox.values.where((f) => !f.deleted).toList();
  }

  /// 获取所有关注列表（包含墓碑记录），用于同步和清理
  List<FollowUser> getAllFollowList() {
    return followBox.values.toList();
  }

  /// 清理墓碑记录：删除 updateTime 超过15天的墓碑
  Future<int> cleanupTombstones(int beforeTimestamp) async {
    final keysToDelete = <String>[];
    for (var entry in followBox.toMap().entries) {
      if (entry.value.deleted &&
          entry.value.updateTime > 0 &&
          entry.value.updateTime < beforeTimestamp) {
        keysToDelete.add(entry.key as String);
      }
    }
    await followBox.deleteAll(keysToDelete);
    return keysToDelete.length;
  }

  Future addFollow(FollowUser follow) async {
    await followBox.put(follow.id, follow);
  }

  Future deleteFollow(String id) async {
    await followBox.delete(id);
  }

  History? getHistory(String id) {
    if (historyBox.containsKey(id)) {
      return historyBox.get(id);
    }
    return null;
  }

  Future addOrUpdateHistory(History history) async {
    await historyBox.put(history.id, history);
  }

  Future delHistory(String id) async {
    await historyBox.delete(id);
  }

  List<History> getHistories() {
    var his = historyBox.values.toList();
    his.sort((a, b) => b.updateTime.compareTo(a.updateTime));
    return his;
  }

  //----------- FollowUserBlock -----------

  /// 获取直播间屏蔽设置，不存在则返回 null
  FollowUserBlock? getFollowUserBlock(String id) {
    return followUserBlockBox.get(id);
  }

  /// 获取直播间屏蔽设置，不存在则创建默认值（id 格式同 FollowUser.id: siteId_roomId）
  FollowUserBlock getFollowUserBlockOrDefault(String id) {
    return followUserBlockBox.get(id) ??
        FollowUserBlock(
          id: id,
          roomId: id.split('_').last,
          siteId: id.split('_').first,
          blockAccounts: [],
          blockWords: [],
        );
  }

  /// 添加或更新屏蔽设置
  Future setFollowUserBlock(FollowUserBlock block) async {
    await followUserBlockBox.put(block.id, block);
  }

  /// 删除屏蔽设置
  Future deleteFollowUserBlock(String id) async {
    await followUserBlockBox.delete(id);
  }

  /// 获取所有屏蔽设置
  List<FollowUserBlock> getAllFollowUserBlocks() {
    return followUserBlockBox.values.toList();
  }
}
