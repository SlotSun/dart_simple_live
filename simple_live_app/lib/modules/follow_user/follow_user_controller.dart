// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';
import 'package:get/get.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/app/utils/duration_2_str_utils.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/db/follow_user_tag.dart';
import 'package:simple_live_app/services/follow_service.dart';

class FollowUserController extends BasePageController<FollowUser> {
  StreamSubscription<dynamic>? onUpdatedIndexedStream;
  StreamSubscription<dynamic>? onUpdatedListStream;

  /// 0:全部 1:直播中 2:未直播
  var filterMode = FollowUserTag(id: "0", tag: "全部", userId: []).obs;
  RxList<FollowUserTag> tagList = [
    FollowUserTag(id: "0", tag: "全部", userId: []),
    FollowUserTag(id: "1", tag: "直播中", userId: []),
    FollowUserTag(id: "2", tag: "未开播", userId: []),
  ].obs;

  // 用户自定义标签
  RxList<FollowUserTag> userTagList = <FollowUserTag>[].obs;

  // 用户自定义显示顺序 - default：watchDuration
  Rx<SortMethod> sortMethod = SortMethod.watchDuration.obs;

  // 用户关注列表样式控制
  Rx<bool> isGrid = true.obs;

  // 排序方式
  var sortMap = {
    SortMethod.watchDuration: "观看时长",
    SortMethod.siteId: "直播平台",
    SortMethod.recently: "最近添加",
    SortMethod.userNameASC: "用户名A-Z",
    SortMethod.userNameDESC: "用户名Z-A",
  };

  // 关注列表样式
  var followStyleMap = {
    true: "紧凑模式",
    false: "卡片模式"
  };

  @override
  void onInit() {
    onUpdatedIndexedStream = EventBus.instance.listen(
      EventBus.kBottomNavigationBarClicked,
      (index) {
        if (index == 1) {
          scrollToTopOrRefresh();
        }
      },
    );
    onUpdatedListStream =
        FollowService.instance.updatedListStream.listen((event) {
      filterData();
    });
    super.onInit();
  }

  @override
  Future refreshData() async {
    await FollowService.instance.loadData();
    updateTagList();
    super.refreshData();
  }

  @override
  Future<List<FollowUser>> getData(int page, int pageSize) async {
    if (page > 1) {
      return Future.value([]);
    }
    if (filterMode.value.tag == "全部") {
      return FollowService.instance.followList.value;
    } else if (filterMode.value.tag == "直播中") {
      return FollowService.instance.liveList.value;
    } else if (filterMode.value.tag == "未开播") {
      return FollowService.instance.notLiveList.value;
    } else {
      FollowService.instance.filterDataByTag(filterMode.value);
      return FollowService.instance.curTagFollowList.value;
    }
  }

  void updateTagList() {
    userTagList.assignAll(FollowService.instance.followTagList);
    tagList.value = tagList.take(3).toList();
    for (var i in userTagList) {
      if (!tagList.contains(i)) {
        tagList.add(i);
      }
    }
  }

  void filterData() {
    if (filterMode.value.tag == "全部") {
      list.assignAll(FollowService.instance.followList.value);
    } else if (filterMode.value.tag == "直播中") {
      list.assignAll(FollowService.instance.liveList.value);
    } else if (filterMode.value.tag == "未开播") {
      list.assignAll(FollowService.instance.notLiveList.value);
    } else {
      FollowService.instance.filterDataByTag(filterMode.value);
      list.assignAll(FollowService.instance.curTagFollowList);
    }
    listSortByMethod();
  }

  // 用户自定义关注样式
  Future<void> showFollowStyleDialog() async {
    isGrid.value = await Utils.showMapOptionDialog(
          title: "关注样式切换",
          followStyleMap,
          isGrid.value,
        ) ??
        true;
  }

  // 用户自定义顺序dialog
  Future<void> showSortDialog() async {
    sortMethod.value = await Utils.showMapOptionDialog(
            sortMap, sortMethod.value,
            title: "排序方式") ??
        SortMethod.watchDuration;
    listSortByMethod();
  }

  // 按自定义顺序调整list
  void listSortByMethod() {
    // list.sort是非稳定排序
    list.sort((a, b) {
      //  或许可以写一个类似Kotlin-thenBy语法糖保证短路执行
      final liveCmp = b.liveStatus.value.compareTo(a.liveStatus.value);
      if (liveCmp != 0) return liveCmp;
      switch (sortMethod.value) {
        case SortMethod.watchDuration:
          return b.watchDuration!
              .toDuration()
              .compareTo(a.watchDuration!.toDuration());
        case SortMethod.siteId:
          return a.siteId.compareTo(b.siteId);
        case SortMethod.recently:
          return a.addTime.compareTo(b.addTime);
        case SortMethod.userNameASC:
          return a.userName.compareTo(b.userName);
        case SortMethod.userNameDESC:
          return b.userName.compareTo(a.userName);
      }
    });
  }

  void setFilterMode(FollowUserTag tag) {
    filterMode.value = tag;
    filterData();
  }

  void removeFollow(FollowUser follow) async {
    var result = await Utils.showAlertDialog("确定要取消关注${follow.userName}吗?",
        title: "取消关注");
    if (!result) {
      return;
    }
    // 取消关注同时删除标签内的 userId
    if (follow.tag != "全部") {
      var tag = tagList.firstWhere((tag) => tag.tag == follow.tag);
      tag.userId.remove(follow.id);
      updateTag(tag);
    }
    await FollowService.instance.removeFollowUser(follow.id);
    refreshData();
  }

  void updateFollow(FollowUser follow) {
    FollowService.instance.addFollow(follow);
  }

  void setFollowTag(FollowUser follow, FollowUserTag targetTag) {
    FollowService.instance.setFollowTag(follow, targetTag);
    filterData();
  }

  Future<void> updateTag(FollowUserTag followUserTag) async {
    await FollowService.instance.updateFollowUserTag(followUserTag);
  }

  @override
  void onClose() {
    onUpdatedIndexedStream?.cancel();
    super.onClose();
  }
}
