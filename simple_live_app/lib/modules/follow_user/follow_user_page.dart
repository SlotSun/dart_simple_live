import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/db/follow_user_tag.dart';
import 'package:simple_live_app/modules/follow_user/follow_user_controller.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/widgets/filter_button.dart';
import 'package:simple_live_app/widgets/follow_user_item.dart';
import 'package:simple_live_app/widgets/keep_alive_wrapper.dart';
import 'package:simple_live_app/widgets/live_room_card.dart';
import 'package:simple_live_app/widgets/page_grid_view.dart';
import 'package:simple_live_core/simple_live_core.dart';

class FollowUserPage extends GetView<FollowUserController> {
  const FollowUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    var count = MediaQuery.of(context).size.width ~/ 500;
    if (count < 1) count = 1;
    var c = MediaQuery.of(context).size.width ~/ 200;
    if (c < 2) {
      c = 2;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("关注用户"),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Remix.trophy_line),
                      AppStyle.hGap12,
                      Text("赛事订阅"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Remix.blender_line),
                      AppStyle.hGap12,
                      Text("模式切换"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Remix.sort_asc),
                      AppStyle.hGap12,
                      Text("按序排列"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Remix.heart_line),
                      AppStyle.hGap12,
                      Text("关注设置"),
                    ],
                  ),
                ),
              ];
            },
            onSelected: (value) {
              if (value == 4) {
                Get.toNamed(RoutePath.kSettingsFollow);
              }else if(value == 0){
                SmartDialog.showToast("此功能暂未开放！敬请期待！");
              }else if(value == 1){
                controller.showFollowStyleDialog();
              }else if(value == 2){
                controller.showSortDialog();
              }
            },
          ),
        ],
        leading: Obx(
          () => FollowService.instance.updating.value
              ? const IconButton(
                  onPressed: null,
                  icon: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: () {
                    controller.refreshData();
                  },
                  icon: const Icon(Icons.refresh),
                ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppStyle.edgeInsetsL8,
            child: Row(
              children: [
                Expanded(
                  child: Obx(
                    () => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Wrap(
                        spacing: 12,
                        children: controller.tagList.map(
                          (option) {
                            return FilterButton(
                              text: option.tag,
                              selected: controller.filterMode.value == option,
                              onTap: () {
                                controller.setFilterMode(option);
                              },
                            );
                          },
                        ).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => Expanded(
              child: AppSettingsController.instance.followStyleNotGrid.value
                  ? PageGridView(
                      crossAxisSpacing: 12,
                      crossAxisCount: count,
                      pageController: controller,
                      firstRefresh: true,
                      showPCRefreshButton: false,
                      itemBuilder: (_, i) {
                        var item = controller.list[i];
                        var site = Sites.allSites[item.siteId]!;
                        return FollowUserItem(
                          item: item,
                          onRemove: () {
                            controller.removeFollow(item);
                          },
                          onTap: () {
                            AppNavigator.toLiveRoomDetail(
                                site: site, roomId: item.roomId);
                          },
                          onLongPress: () {
                            // 长按弹出操作：设置标签或查看详情
                            Get.bottomSheet(
                              SafeArea(
                                child: Wrap(
                                  children: [
                                    ListTile(
                                      leading:
                                          const Icon(Remix.price_tag_3_line),
                                      title: const Text('设置标签'),
                                      onTap: () {
                                        Get.back();
                                        setFollowTagDialog(item);
                                      },
                                    ),
                                    ListTile(
                                      leading:
                                          const Icon(Remix.information_line),
                                      title: const Text('查看详情'),
                                      onTap: () {
                                        Get.back();
                                        AppNavigator.toFollowInfo(item);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              backgroundColor: Theme.of(context).cardColor,
                            );
                          },
                        );
                      },
                    )
                  : KeepAliveWrapper(
                      child: PageGridView(
                        pageController: controller,
                        padding: AppStyle.edgeInsetsA12,
                        firstRefresh: true,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        crossAxisCount: c,
                        itemBuilder: (_, i) {
                          var item = controller.list[i];
                          // 或许直接继承字段更好，标记工作
                          LiveRoomItem liveRoomItem = LiveRoomItem(
                            roomId: item.roomId,
                            title: item.title.value,
                            cover: item.cover.value,
                            userName: item.userName,
                            online: item.online.value,
                          );
                          var site = Sites.allSites[item.siteId]!;
                          return LiveRoomCard(site, liveRoomItem);
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void setFollowTagDialog(FollowUser follow) {
    /// 控制单选ui
    List<FollowUserTag> copiedList = [
      controller.tagList.first,
      ...controller.tagList.skip(3),
    ];
    Rx<FollowUserTag> checkTag =
        controller.tagList.indexOf(controller.filterMode.value) < 3
            ? copiedList.first.obs
            : controller.filterMode.value.obs;
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
                    controller.setFollowTag(follow, checkTag.value);
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
}
