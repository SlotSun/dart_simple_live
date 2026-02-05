// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/db/follow_user_tag.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
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

  // 排序方式
  var sortMap = {
    SortMethod.watchDuration: "观看时长",
    SortMethod.siteId: "直播平台",
    SortMethod.recently: "最近添加",
    SortMethod.userNameASC: "用户名A-Z",
    SortMethod.userNameDESC: "用户名Z-A",
  };

  // 关注列表样式
  var followStyleMap = {true: "紧凑模式", false: "卡片模式"};

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
    onUpdatedListStream = FollowService.instance.updatedListStream.listen(
      (event) {
        updateTagList();
        filterData();
      },
    );

    sortMethod = AppSettingsController.instance.followSortMethod;
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
  }

  // 用户自定义关注样式
  Future<void> showFollowStyleDialog() async {
    var res = await Utils.showMapOptionDialog(
      title: "关注样式切换",
      followStyleMap,
      AppSettingsController.instance.followStyleNotGrid.value,
    );
    if (res != null) {
      AppSettingsController.instance.setFollowStyleNotGrid(res);
    }
  }

  // 用户自定义顺序dialog
  Future<void> showSortDialog() async {
    var res = await Utils.showMapOptionDialog(sortMap, sortMethod.value,
        title: "排序方式");
    if (res != null) {
      sortMethod.value = res;
      AppSettingsController.instance.setFollowSortMethod(sortMethod.value);
      if (filterMode.value.tag == "未开播" ||
          filterMode.value.tag == "全部" ||
          filterMode.value.tag == "直播中") {
        FollowService.instance.liveListSort();
      }
      filterData();
    }
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
      var tag = tagList.firstWhereOrNull((tag) => tag.tag == follow.tag);
      if (tag != null) {
        tag.userId.remove(follow.id);
        updateTag(tag);
      }
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

  // 弹出底部菜单栏
  void showBottomMenu(FollowUser item) {
    Get.bottomSheet(
      SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Remix.price_tag_3_line),
              title: const Text('设置标签'),
              onTap: () {
                Get.back();
                setFollowTagDialog(item);
              },
            ),
            ListTile(
              leading: const Icon(Remix.information_line),
              title: const Text('查看详情'),
              onTap: () {
                Get.back();
                AppNavigator.toFollowInfo(item);
              },
            ),
          ],
        ),
      ),
      backgroundColor: Get.theme.cardColor,
    );
  }

  void setFollowTagDialog(FollowUser follow) {
    /// 控制单选ui
    List<FollowUserTag> copiedList = [
      tagList.first,
      ...tagList.skip(3),
    ];
    Rx<FollowUserTag> checkTag = tagList.indexOf(filterMode.value) < 3
        ? copiedList.first.obs
        : filterMode.value.obs;
    final ScrollController scrollController = ScrollController();
    Get.dialog(
      AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '设置标签',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.check,
                  ),
                  onPressed: () {
                    setFollowTag(follow, checkTag.value);
                    Get.back();
                  },
                ),
              ],
            ),
            const Divider(),
            Obx(
              () {
                int selectedIndex = copiedList.indexOf(checkTag.value);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (selectedIndex >= 0) {
                    scrollController.animateTo(
                      selectedIndex * 60.0, // 假设每项高度为 60
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });
                return SizedBox(
                  height: 300,
                  width: 300,
                  child: RadioGroup<FollowUserTag>(
                    groupValue: checkTag.value,
                    onChanged: (value) {
                      checkTag.value = value!;
                    },
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: copiedList.length,
                      itemBuilder: (context, index) {
                        var tagItem = copiedList[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: Colors.grey.shade300, width: 1.0),
                            ),
                          ),
                          child: RadioListTile<FollowUserTag>(
                            title: Text(tagItem.tag),
                            value: tagItem,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void onClose() {
    onUpdatedIndexedStream?.cancel();
    super.onClose();
  }
}
