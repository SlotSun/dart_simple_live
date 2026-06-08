import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pinyin/pinyin.dart';
import 'package:pool/pool.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/app/utils/duration_2_str_utils.dart';
import 'package:simple_live_app/app/utils/dynamic_sort.dart';
import 'package:simple_live_app/app/utils/string_normalizer.dart';
import 'package:simple_live_app/models/db/follow_snapshot.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/db/follow_user_tag.dart';
import 'package:simple_live_app/models/db/history.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:synchronized/synchronized.dart';

class FollowService extends GetxService {
  StreamSubscription<dynamic>? subscription;

  static FollowService get instance => Get.find<FollowService>();

  final StreamController _updatedListController = StreamController.broadcast();

  Stream get updatedListStream => _updatedListController.stream;

  /// 关注用户列表
  RxList<FollowUser> followList = RxList<FollowUser>();

  /// 直播中的用户列表
  RxList<FollowUser> liveList = RxList<FollowUser>();

  /// 未直播的用户列表
  RxList<FollowUser> notLiveList = RxList<FollowUser>();

  /// 用户自定义的tag
  RxList<FollowUserTag> followTagList = RxList<FollowUserTag>();

  /// 当前tag的用户列表
  RxList<FollowUser> curTagFollowList = RxList<FollowUser>();

  /// 线程安全
  final _lock = Lock();

  /// 已经更新状态的数量
  var updatedCount = 0;

  /// 是否正在更新
  var updating = false.obs;

  Timer? updateTimer;

  int _totalToUpdate = 0;

  int _refreshCycle = 0;

  bool _snap = false;

  @override
  Future<void> onInit() async {
    subscription = EventBus.instance.listen(Constant.kUpdateFollow, (data) {
      if (data is History) {
        updateFollowHistory(data);
      } else {
        loadData(updateStatus: false);
      }
    });
    await initFollowList();
    initTimer();
    cleanupTombstones();
    super.onInit();
  }

  Future<void> updateTagName(
      FollowUserTag followUserTag, String newTagName) async {
    final FollowUserTag newTag = followUserTag.copyWith(tag: newTagName);
    updateFollowUserTag(newTag);
    // update item's tag when update tagName
    for (var i in newTag.userId) {
      var follow = DBService.instance.followBox.get(i);
      if (follow != null) {
        follow.tag = newTagName;
        await addFollow(follow);
      }
    }
  }

  Future<void> updateFollowUserTag(FollowUserTag tag) async {
    if (tag.tag == '全部') {
      return;
    }
    await DBService.instance.updateFollowTag(tag);
    // 查找并修改
    var index = followTagList.indexWhere((oTag) => oTag.id == tag.id);
    followTagList[index] = tag;
  }

  Future<void> addFollowUserTag(String tag) async {
    // 判断待添加tag是否已存在，存在则return
    if (followTagList.any((item) => item.tag == tag)) {
      SmartDialog.showToast("标签名重复，修改失败");
      return;
    }
    FollowUserTag item = await DBService.instance.addFollowTag(tag);
    followTagList.add(item);
  }

  Future removeFollowUserTag(FollowUserTag tag) async {
    // 将tag下的所有follow设置为全部
    for (var i in tag.userId) {
      var follow = DBService.instance.followBox.get(i);
      if (follow != null) {
        follow.tag = "全部";
        await FollowService.instance.addFollow(follow);
      }
    }
    followTagList.remove(tag);
    await DBService.instance.deleteFollowTag(tag.id);
  }

  // 获取用户自定义标签列表
  void getAllTagList() {
    var list = DBService.instance.getFollowTagList();
    followTagList.assignAll(list);
  }

  /// 获取包含“全部”的标签选项列表
  List<FollowUserTag> getTagOptionsWithAll() {
    return [
      FollowUserTag(id: '0', tag: '全部', userId: []),
      ...followTagList,
    ];
  }

  /// 为关注项设置标签（统一逻辑）
  Future<void> setFollowTag(FollowUser item, FollowUserTag targetTag) async {
    // 当前标签对象（可能为“全部”且不在 followTagList 中）
    FollowUserTag? currentTag;
    if (item.tag != '全部') {
      for (final t in followTagList) {
        if (t.tag == item.tag) {
          currentTag = t;
          break;
        }
      }
    }

    // 从旧标签移除
    if (currentTag != null) {
      currentTag.userId.remove(item.id);
      DBService.instance.updateFollowTag(currentTag);
    }

    // 添加到新标签（跳过“全部”）
    if (targetTag.tag != '全部') {
      // targetTag来源于UI选项，需定位真实对象
      FollowUserTag? tar;
      for (final t in followTagList) {
        if (t.tag == targetTag.tag) {
          tar = t;
          break;
        }
      }
      if (tar != null) {
        tar.userId.addIf(!tar.userId.contains(item.id), item.id);
        DBService.instance.updateFollowTag(tar);
      }
    }

    // 更新FollowUser本身
    item.tag = targetTag.tag;
    await addFollow(item);
  }

  void filterDataByTag(FollowUserTag tag) {
    // 清空curTagFollowList
    curTagFollowList.clear();
    // 用一个新的列表来存储需要删除的 userId
    List<String> toRemove = [];
    for (var id in tag.userId) {
      if (followList.any((x) => x.id == id)) {
        // 找到对应的 followUser 添加到 curTagFollowList
        curTagFollowList.add(followList.firstWhere((x) => x.id == id));
      } else {
        // 标记要删除的 id
        toRemove.add(id);
      }
    }
    // 在遍历结束后统一移除不在 followList 中的 id
    tag.userId.removeWhere((id) => toRemove.contains(id));
    // 更新数据库
    if (toRemove.isNotEmpty) {
      DBService.instance.updateFollowTag(tag);
    }
    listSortByMethod(curTagFollowList,
        AppSettingsController.instance.followSortMethod.value);
  }

  void updateFollowTagOrder(FollowUserTag oldTag, FollowUserTag newTag) {
    // 改变先落库再读库最后更新ui，这中间需要同步等待，数据流程糟糕，开发心智负担重
    // 内存优先：实现外表操作结束后异步落库，多写代码 但逻辑较为简单
    followTagList.removeWhere((x) => x.id == oldTag.id);
    followTagList.add(newTag);
    // hive 以 id排序，额外进行排序操作
    followTagList.sort((tagA, tagB) => tagA.id.compareTo(tagB.id));

    DBService.instance.deleteFollowTag(oldTag.id);
    DBService.instance.updateFollowTag(newTag);
  }

  // 添加关注
  Future<void> addFollow(FollowUser follow) async {
    // follow变动过程中romanName统一变化
    String romanName = "";
    if (follow.remark != null && follow.remark!.isNotEmpty) {
      romanName = PinyinHelper.getShortPinyin(follow.romanName!);
    } else {
      romanName = PinyinHelper.getShortPinyin(follow.userName);
    }
    follow.romanName = romanName.normalize();
    // 重新关注时清除墓碑标记
    follow.deleted = false;
    follow.updateTime = 0;
    // db.add 其实是update会直接更新数据，所以外表也应该实现此功能：有则更，无则添加
    int index = followList.indexWhere((f) => f.id == follow.id);
    if (index != -1) {
      followList[index] = follow;
    } else {
      followList.add(follow);
    }
    liveListSort(); // 每次数据操作后外表进行业务刷新
    await DBService.instance.addFollow(follow);
  }

  // 取消关注（墓碑机制）
  Future<void> removeFollowUser(String id) async {
    // 存储在线状态，数据修改应followList外表和followBox内表保持同步
    // 后续业务逻辑中，将规避直接业务在数据库上操作，落库操作只执行一次
    // 从而规避业务逻辑直读数据库导致的数据混乱
    FollowUser follow = followList.firstWhere((x) => x.id == id);
    followList.removeWhere((x) => x.id == id);
    // 取消关注同时删除用户自定义tag中的关注id
    if (follow.tag != "全部") {
      // 对象引用会直接修改数据无需额外操作
      var tag = followTagList.firstWhereOrNull((tag) => tag.tag == follow.tag);
      if (tag != null) {
        tag.userId.remove(follow.id);
        await FollowService.instance.updateFollowUserTag(tag);
      }
    }
    liveListSort();
    // 设置墓碑标记，而非直接删除记录
    follow.deleted = true;
    follow.updateTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await DBService.instance.addFollow(follow);
  }

  // 判断关注是否存在
  bool getFollowExist(String id) {
    return DBService.instance.getFollowExist(id);
  }

  // 更新关注的历史记录
  Future<void> updateFollowHistory(History history) async {
    var follow =
        followList.where((follow) => follow.id == history.id).firstOrNull;
    if (follow == null) {
      return;
    } else {
      // sync watch-part between history and follow
      follow.syncDuration = history.syncDuration;
      follow.watchDuration = history.watchDuration;
      follow.watchDurationSec = history.watchDuration!.toDuration().inSeconds;
      await addFollow(follow);
    }
    Log.i("已更新当前播放的观看时长：${follow.watchDuration}");
  }

  void initTimer() {
    if (AppSettingsController.instance.autoUpdateFollowEnable.value) {
      updateTimer?.cancel();
      _refreshCycle = 0;
      updateTimer = Timer.periodic(
        Duration(
            minutes:
                AppSettingsController.instance.autoUpdateFollowDuration.value),
        (timer) {
          CoreLog.i("Update Follow Timer - Cycle: $_refreshCycle");
          loadData(updateStatus: true, cycle: _refreshCycle);
          _refreshCycle = (_refreshCycle + 1) % 2; // 2-cycle rotation
        },
      );
    } else {
      updateTimer?.cancel();
    }
  }

  // 此操作只在初始化时调用一次
  Future<void> initFollowList() async {
    List<FollowUser> list = DBService.instance.getFollowList();

    if (list.isEmpty) {
      updating.value = false;
      followList.assignAll(list);
      liveList.clear();
      notLiveList.clear();
      _updatedListController.add(0);
      return;
    }
    var followSnapshot = AppSettingsController.instance.followSnapshot;
    bool followSnapshotEnable = AppSettingsController.instance.followSnapshotEnable.value;
    // whether to recover snapshot depends on expireAt
    if (followSnapshot != null &&
        followSnapshot.expireAt > DateTime.now().microsecondsSinceEpoch &&
        followSnapshotEnable) {
      final snapshotMap = {
        for (var item in followSnapshot.followSnapshotItems) item.id: item
      };
      for (var item in list) {
        final resItem = snapshotMap[item.id];
        if (resItem != null) {
          item.applySnapshot(resItem);
        }
      }
      _snap = true;
      Log.i("FollowService: follow-snapshot has recovered, expireAt: ${followSnapshot.expireAt}");
    }
    followList.assignAll(list);
    if(_snap){
      liveListSort();
    }
    getAllTagList();
  }

  Future<void> loadData({bool updateStatus = true, int? cycle}) async {
    // snapshot 恢复跳过第一次状态更新
    if(_snap){
      _snap = false;
      return;
    }
    if (updateStatus) {
      startUpdateStatus(cycle: cycle);
    } else {
      _updatedListController.add(0);
    }
  }

  void multiRoundPriority() {
    final historyList = DBService.instance.getHistories();
    final Map<String, int> historyRankMap = {
      for (var i = 0; i < historyList.length; i++) historyList[i].id: i
    };
    final int maxRank = historyList.isNotEmpty ? historyList.length : 1;

    Duration maxDuration = const Duration();
    for (var user in followList) {
      final duration = user.watchDuration!.toDuration();
      if (duration > maxDuration) {
        maxDuration = duration;
      }
    }
    final double maxDurationInSeconds =
        maxDuration.inSeconds > 0 ? maxDuration.inSeconds.toDouble() : 1.0;
    // 简单线性加权组合算法，目前认定观看时长和最近观看时间权重一致
    // 如果用户历史行为序列非常长：可替换为时间衰减 + 观看时长加权
    followList.sort((a, b) {
      // 静态权重
      const double wDuration = 0.5;
      const double wRecency = 0.5;
      // 在线降权，离线增权
      const double wOnline = 0.3;
      const double wOffline = 1 - wOnline;

      // 动态权重
      double normDurationA =
          a.watchDuration!.toDuration().inSeconds.toDouble() /
              maxDurationInSeconds;
      int rankA = historyRankMap[a.id] ?? maxRank;
      double normRecencyA = (maxRank - rankA).toDouble() / maxRank;
      double scoreA =
          ((wDuration * normDurationA) + (wRecency * normRecencyA)) *
              (a.liveStatus.value == 2 ? wOnline : wOffline);

      double normDurationB =
          b.watchDuration!.toDuration().inSeconds.toDouble() /
              maxDurationInSeconds;
      int rankB = historyRankMap[b.id] ?? maxRank;
      double normRecencyB = (maxRank - rankB).toDouble() / maxRank;
      double scoreB =
          ((wDuration * normDurationB) + (wRecency * normRecencyB)) *
              (b.liveStatus.value == 2 ? wOnline : wOffline);

      return scoreB.compareTo(scoreA);
    });
  }

  void startUpdateStatus({int? cycle}) async {
    List<FollowUser> usersToUpdate;
    final totalUsers = followList.length;
    final douyinCount = followList.where((x) => x.siteId == 'douyin').length;

    //tips: 噪音用户画像（高风险平台：90%; 多次手刷; 单高关注数>50; 频繁切直播间; 不登录反复高危操作; 移动宽带用户; 反复关注取消; 多ip切换; 特殊地区风控; 多端在线请求; 黑号）
    if (cycle != null && (totalUsers > 100 || douyinCount > 50)) {
      // 简单28
      final topNCount = (totalUsers * 0.2).round(); // Top 20%
      final bottomNCount = (totalUsers * 0.2).round(); // Bottom 20%
      final middlePartEndIndex = totalUsers - bottomNCount;
      multiRoundPriority();
      final topNUsers = followList.sublist(0, topNCount);
      final middleUsers = followList.sublist(topNCount, middlePartEndIndex);
      if (cycle == 0) {
        usersToUpdate = topNUsers;
        CoreLog.i(
            "Update Follow: Cycle 0, updating top ${usersToUpdate.length}/$totalUsers users.");
      } else {
        usersToUpdate = [...topNUsers, ...middleUsers];
        CoreLog.i(
            "Update Follow: Cycle 1, updating top+middle ${usersToUpdate.length}/$totalUsers users.");
      }
    } else {
      usersToUpdate = List.from(followList);
      if (cycle != null) {
        CoreLog.i(
            "Update Follow: List <= 100, updating all ${usersToUpdate.length} users.");
      }
    }
    _totalToUpdate = usersToUpdate.length;
    updatedCount = 0;
    updating.value = true;

    if (_totalToUpdate == 0) {
      updating.value = false;
      filterData();
      return;
    }

    var threadCount =
        AppSettingsController.instance.updateFollowThreadCount.value;

    var pool = Pool(threadCount);
    var tasks = <Future>[];

    for (var user in usersToUpdate) {
      tasks.add(pool.withResource(() => updateLiveInformation(user)));
    }
    await Future.wait(tasks);
    await pool.close();

    // frequency of snapshot-saving and expireAt calculation depend on user-setting: auto-update
    final minutes = AppSettingsController.instance.autoUpdateFollowDuration.value;
    final expireAt = DateTime.now().add(Duration(minutes: minutes)).microsecondsSinceEpoch;
    AppSettingsController.instance.setFollowSnapshot(
      FollowSnapshot(
        expireAt: expireAt,
        followSnapshotItems: followList.map((e) => e.toSnapshot()).toList(),
      ),
    );
    Log.i("FollowService: follow-snapshot has saved, time: ${DateTime.now()}");
  }

  Future updateLiveInformation(FollowUser item) async {
    try {
      var site = Sites.allSites[item.siteId]!;
      LiveRoomDetail detail =
          await site.liveSite.getRoomDetail(roomId: item.roomId);
      item.liveStatus.value = detail.status ? 2 : 1;
      item.cover.value = detail.status ? detail.cover : "";
      item.title.value = detail.title;
      item.online.value = detail.online;
    } catch (e) {
      Log.logPrint(e);
    } finally {
      await _lock.synchronized(() {
        updatedCount++;
      });
      if (updatedCount >= _totalToUpdate) {
        filterData();
        updating.value = false;
      }
    }
  }

  void filterData() {
    liveListSort();
    _updatedListController.add(0);
  }

  void liveListSort() {
    listSortByMethod(
        followList, AppSettingsController.instance.followSortMethod.value);
    liveList.assignAll(followList.where((x) => x.liveStatus.value == 2));
    notLiveList.assignAll(followList.where((x) => x.liveStatus.value == 1));
  }

  void listSortByMethod(List<FollowUser> list, SortMethod sortMethod) {
    var liveCondition = SortCondition<FollowUser>(
      valueGetter: (item) => item.liveStatus.value, // Rx<int>
      ascending: false,
    );
    var watchDurationCondition = SortCondition<FollowUser>(
      valueGetter: (item) => item.watchDuration?.toDuration() ?? Duration.zero,
      ascending: false,
    );
    var siteIdCondition = SortCondition<FollowUser>(
      valueGetter: (item) {
        final order = AppSettingsController.instance.siteSort;
        // 返回索引作为 Comparable
        return order.indexOf(item.siteId);
      },
    );
    var recentlyCondition = SortCondition<FollowUser>(
      valueGetter: (item) => item.addTime,
      ascending: false,
    );
    var userNameASCCondition = SortCondition<FollowUser>(
      valueGetter: (item) => item.romanName ?? "",
      ascending: true,
    );
    var userNameDESCCondition = SortCondition<FollowUser>(
      valueGetter: (item) => item.romanName ?? "",
      ascending: false,
    );
    switch (sortMethod) {
      case SortMethod.watchDuration:
        list.dynamicSort([liveCondition, watchDurationCondition]);
      case SortMethod.siteId:
        list.dynamicSort([liveCondition, siteIdCondition]);
      case SortMethod.recently:
        list.dynamicSort([liveCondition, recentlyCondition]);
      case SortMethod.userNameASC:
        list.dynamicSort([liveCondition, userNameASCCondition]);
      case SortMethod.userNameDESC:
        list.dynamicSort([liveCondition, userNameDESCCondition]);
    }
  }

  void exportFile() async {
    if (followList.isEmpty) {
      SmartDialog.showToast("列表为空");
      return;
    }

    try {
      var status = await Utils.checkStorgePermission();
      if (!status) {
        SmartDialog.showToast("无权限");
        return;
      }

      var dir = "";
      if (Platform.isIOS) {
        dir = (await getApplicationDocumentsDirectory()).path;
      } else {
        dir = await FilePicker.platform.getDirectoryPath() ?? "";
      }

      if (dir.isEmpty) {
        return;
      }
      var jsonFile = File(
          '$dir/SimpleLive_${DateTime.now().millisecondsSinceEpoch ~/ 1000}.json');
      var jsonText = generateJson();
      await jsonFile.writeAsString(jsonText);
      SmartDialog.showToast("已导出关注列表");
    } catch (e) {
      Log.logPrint(e);
      SmartDialog.showToast("导出失败：$e");
    }
  }

  void inputFile() async {
    try {
      var status = await Utils.checkStorgePermission();
      if (!status) {
        SmartDialog.showToast("无权限");
        return;
      }
      var file = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (file == null) {
        return;
      }
      var jsonFile = File(file.files.single.path!);
      await inputJson(await jsonFile.readAsString());
      SmartDialog.showToast("导入成功");
    } catch (e) {
      Log.logPrint(e);
      SmartDialog.showToast("导入失败:$e");
    } finally {
      loadData();
    }
  }

  void exportText() {
    if (followList.isEmpty) {
      SmartDialog.showToast("列表为空");
      return;
    }
    var content = generateJson();
    Get.dialog(
      AlertDialog(
        title: const Text("导出为文本"),
        content: TextField(
          controller: TextEditingController(text: content),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          minLines: 5,
          maxLines: 8,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text("关闭"),
          ),
          TextButton(
            onPressed: () {
              Utils.copyToClipboard(content);
              Get.back();
            },
            child: const Text("复制"),
          ),
        ],
      ),
    );
  }

  void inputText() async {
    final TextEditingController textController = TextEditingController();
    await Get.dialog(
      AlertDialog(
        title: const Text("从文本导入"),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "请输入内容",
          ),
          minLines: 5,
          maxLines: 8,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text("关闭"),
          ),
          TextButton(
            onPressed: () async {
              var content = await Utils.getClipboard();
              if (content != null) {
                textController.text = content;
              }
            },
            child: const Text("粘贴"),
          ),
          TextButton(
            onPressed: () async {
              if (textController.text.isEmpty) {
                SmartDialog.showToast("内容为空");
                return;
              }
              try {
                await inputJson(textController.text);
                SmartDialog.showToast("导入成功");
                Get.back();
                loadData();
              } catch (e) {
                SmartDialog.showToast("导入失败，请检查内容是否正确");
              }
            },
            child: const Text("导入"),
          ),
        ],
      ),
    );
  }

  String generateJson() {
    var data = followList
        .map(
          (item) => {
            "siteId": item.siteId,
            "id": item.id,
            "roomId": item.roomId,
            "userName": item.userName,
            "face": item.face,
            "watchDuration": item.watchDuration,
            "addTime": item.addTime.toString(),
            "remark": item.remark,
            "romanName": item.romanName,
            "tag": item.tag
          },
        )
        .toList();
    return jsonEncode(data);
  }

  Future inputJson(String content) async {
    var data = jsonDecode(content);

    for (var item in data) {
      var follow = FollowUser.fromJson(item);
      await DBService.instance.addFollow(follow);
    }

    await followUserAllDataCheck();
  }

  // 数据校对
  // 核心关注数据有几种错乱情况，需要进行校对，需要一定时间复核代码
  // 1：未关注，但标签包含关注
  // 2: 已关注，且设置标签，但标签不包含
  // 3: 已关注，且设置标签，但标签不存在
  // 4: 标签重复
  // 5: webdav同步导致的数据错乱
  // 校对思路，followList是基础数据源，tagList为索引数据，重建数据即可
  // 根据此思路，可以重写文件导入导出以及webdav恢复逻辑
  Future<void> followUserAllDataCheck() async {
    var followUserListTemp = DBService.instance.getFollowList();
    var oldTagList = DBService.instance.getFollowTagList();
    final Map<String, List<String>> tagMap = {
      for (var tag in oldTagList) tag.tag: <String>[],
    };
    // 手动添加罗马音
    for (FollowUser follow in followUserListTemp) {
      if (follow.remark != null && follow.remark!.isNotEmpty) {
        var roman = PinyinHelper.getShortPinyin(follow.remark!).normalize();
        follow.romanName = roman;
      } else {
        follow.romanName =
            PinyinHelper.getShortPinyin(follow.userName).normalize();
      }
      await DBService.instance.addFollow(follow);
    }
    Log.i("transfer follow.name to roman is down!");
    for (var follow in followUserListTemp) {
      if (follow.tag != "全部") {
        tagMap.putIfAbsent(follow.tag, () => <String>[]).add(follow.id);
      }
    }
    // 落库
    final Map<String, FollowUserTag> res = {};
    String? lastKey;
    for (var entry in tagMap.entries) {
      lastKey = FractionalIndexing.generateKeyBetween(lastKey, null);
      final followUserTag = FollowUserTag(
        id: lastKey,
        tag: entry.key,
        userId: entry.value,
      );
      res[followUserTag.id] = followUserTag;
    }
    await DBService.instance.tagBox.clear();
    await DBService.instance.tagBox.putAll(res);
    Log.i(
        "Follow-Service: data check down，follows:${followUserListTemp.length}，tags:${tagMap.length}");
  }

  /// 清理墓碑记录：删除 updateTime 超过15天的墓碑
  Future<void> cleanupTombstones() async {
    // 墓碑保留15天 = 15 * 24 * 60 * 60 秒
    const int tombstoneTTL = 15 * 24 * 60 * 60;
    final beforeTimestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) - tombstoneTTL;
    final count = await DBService.instance.cleanupTombstones(beforeTimestamp);
    if (count > 0) {
      Log.i("Follow-Service: cleaned $count tombstone records");
    }
  }

  @override
  void onClose() {
    updateTimer?.cancel();
    subscription?.cancel();
    super.onClose();
  }
}
