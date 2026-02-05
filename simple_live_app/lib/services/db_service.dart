import 'dart:async';

import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/db/follow_user_tag.dart';
import 'package:simple_live_app/models/db/history.dart';
import 'package:collection/collection.dart';

class DBService extends GetxService {
  static DBService get instance => Get.find<DBService>();
  late Box<History> historyBox;
  late Box<FollowUser> followBox;
  late Box<FollowUserTag> tagBox;

  Future init() async {
    historyBox = await Hive.openBox("History");
    followBox = await Hive.openBox("FollowUser");
    tagBox = await Hive.openBox("FollowUserTag");
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
    final String uniqueId =  FractionalIndexing.generateKeyBetween(lastKey, null);
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
    return followBox.containsKey(id);
  }

  List<FollowUser> getFollowList() {
    return followBox.values.toList();
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
}
