import 'dart:convert';

import 'package:get/get.dart';
import 'package:simple_live_app/models/db/follow_user_block.dart';
import 'package:simple_live_app/services/db_service.dart';

class FollowBlockService extends GetxService {
  static FollowBlockService get instance => Get.find<FollowBlockService>();

  String _getBlockId(String siteId, String roomId) => "${siteId}_$roomId";

  /// 获取直播间屏蔽设置，不存在则返回默认空对象
  FollowUserBlock getBlock({
    required String siteId,
    required String roomId,
  }) {
    return DBService.instance
        .getFollowUserBlockOrDefault(_getBlockId(siteId, roomId));
  }

  /// 添加屏蔽账户
  Future<void> addBlockAccount({
    required String siteId,
    required String roomId,
    required FollowUserBlockAccount account,
  }) async {
    final block = getBlock(siteId: siteId, roomId: roomId);
    if (block.blockAccounts.any((a) => a.uid == account.uid)) {
      return;
    }
    block.blockAccounts.add(account);
    block.updateTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await DBService.instance.setFollowUserBlock(block);
  }

  /// 移除屏蔽账户
  Future<void> removeBlockAccount({
    required String siteId,
    required String roomId,
    required String uid,
  }) async {
    final block = getBlock(siteId: siteId, roomId: roomId);
    block.blockAccounts.removeWhere((a) => a.uid == uid);
    block.updateTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await DBService.instance.setFollowUserBlock(block);
  }

  /// 添加屏蔽词
  Future<void> addBlockWord({
    required String siteId,
    required String roomId,
    required String word,
  }) async {
    final block = getBlock(siteId: siteId, roomId: roomId);
    if (block.blockWords.contains(word)) {
      return;
    }
    block.blockWords.add(word);
    block.updateTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await DBService.instance.setFollowUserBlock(block);
  }

  /// 移除屏蔽词
  Future<void> removeBlockWord({
    required String siteId,
    required String roomId,
    required String word,
  }) async {
    final block = getBlock(siteId: siteId, roomId: roomId);
    block.blockWords.remove(word);
    block.updateTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await DBService.instance.setFollowUserBlock(block);
  }

  /// 清空该直播间所有屏蔽设置
  Future<void> clearBlock({
    required String siteId,
    required String roomId,
  }) async {
    await DBService.instance
        .deleteFollowUserBlock(_getBlockId(siteId, roomId));
  }

  //----------- 导入/导出 -----------

  String generateJson() {
    var data = DBService.instance.getAllFollowUserBlocks();
    return jsonEncode(data.map((e) => e.toJson()).toList());
  }

  Future<void> inputJson(String content) async {
    var data = jsonDecode(content) as List;
    for (var item in data) {
      var block = FollowUserBlock.fromJson(item);
      await DBService.instance.setFollowUserBlock(block);
    }
  }

  /// 导出单个直播间屏蔽设置
  String generateBlockJson({
    required String siteId,
    required String roomId,
  }) {
    var block = getBlock(siteId: siteId, roomId: roomId);
    return jsonEncode(block.toJson());
  }

  /// 导入单个直播间屏蔽设置（合并模式：追加不重复项）
  Future<void> inputBlockJson({
    required String siteId,
    required String roomId,
    required String content,
  }) async {
    var data = jsonDecode(content);
    var imported = FollowUserBlock.fromJson(data);
    var block = getBlock(siteId: siteId, roomId: roomId);

    for (var account in imported.blockAccounts) {
      if (!block.blockAccounts.any((a) => a.uid == account.uid)) {
        block.blockAccounts.add(account);
      }
    }
    for (var word in imported.blockWords) {
      if (!block.blockWords.contains(word)) {
        block.blockWords.add(word);
      }
    }
    block.updateTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await DBService.instance.setFollowUserBlock(block);
  }
}
