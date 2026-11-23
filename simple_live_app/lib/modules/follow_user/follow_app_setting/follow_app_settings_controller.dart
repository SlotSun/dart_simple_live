import 'package:material_ui/material_ui.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:fractional_indexing_dart/fractional_indexing_dart.dart';
import 'package:get/get.dart' hide Condition;
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/app/utils/extensions/duration_2_str_utils.dart';
import 'package:simple_live_app/app/utils/dynamic_filter.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/db/follow_user_tag.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/services/history_service.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_core/simple_live_core.dart';

class FollowAppSettingsController extends BaseController {
  final appC = Get.find<AppSettingsController>();

  // 用户自定义标签
  RxList<FollowUserTag> userTagList = <FollowUserTag>[].obs;

  // 用户自定义条件
  Rx<int> takeLast = 15.obs;
  Rx<int> minutes = 30.obs;

  /// 正在编辑绑定关系的标签
  final Rxn<FollowUserTag> editingTag = Rxn<FollowUserTag>();

  /// 当前标签已绑定的平台分类
  final RxList<TagBinding> editingBindings = <TagBinding>[].obs;

  @override
  void onInit() {
    updateTagList();
    super.onInit();
  }

  // 修改用户自定义关注设置
  void setFollowSetting(bool hideOfflineFollow) {
    appC.setHideOfflineFollow(hideOfflineFollow);
    EventBus.instance.emit(Constant.kUpdateFollow, 0);
  }

  // 修改隐藏快速取关按钮
  void setRemoveFollowButton(bool hideFollowCardRemoveButton) {
    appC.setHideRemoveFollowButton(hideFollowCardRemoveButton);
  }

  // 标签管理
  void updateTagList() {
    userTagList.assignAll(FollowService.instance.followTagList);
    // 修改tag 通知 follo_user_controller 数据更新
    EventBus.instance.emit(Constant.kUpdateFollow, 0);
  }

  Future removeTag(FollowUserTag tag) async {
    await FollowService.instance.removeFollowUserTag(tag);
    updateTagList();
    Log.i('删除tag${tag.tag}');
  }

  void addTag(String tag) async {
    await FollowService.instance.addFollowUserTag(tag);
    updateTagList();
  }

  Future<void> updateTag(FollowUserTag followUserTag) async {
    await FollowService.instance.updateFollowUserTag(followUserTag);
  }

  void updateTagName(FollowUserTag followUserTag, String newTagName) {
    // 未操作
    if (followUserTag.tag == newTagName) {
      return;
    }
    // 避免重名
    if (userTagList.any((item) => item.tag == newTagName)) {
      SmartDialog.showToast("标签名重复，修改失败");
      return;
    }
    FollowService.instance.updateTagName(followUserTag, newTagName);
    SmartDialog.showToast("标签名修改成功");
    updateTagList();
  }

  void updateTagOrder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1; // 处理索引调整
    final item = userTagList.removeAt(oldIndex);
    String newTagKey = FractionalIndexing.generateKeyBetween(newIndex > 0 ? userTagList[newIndex - 1].id : null,
        newIndex < userTagList.length ? userTagList[newIndex].id : null);
    // 用 copyWith 保留标签绑定的平台分类等字段
    final newTag = item.copyWith(id: newTagKey);
    FollowService.instance.updateFollowTagOrder(item, newTag);
    updateTagList();
  }

  Future<void> followDataCheck() async {
    await FollowService.instance.followUserAllDataCheck();
    SmartDialog.showToast("数据校准完成");
  }

  // 标签管理弹窗
  void showTagsManager() {
    Utils.showBottomSheet(
      title: '标签管理',
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppStyle.divider,
        ListTile(
          title: const Text("添加标签"),
          leading: const Icon(Icons.add),
          onTap: () {
            editTagDialog("添加标签");
          },
        ),
        AppStyle.divider,
        // 列表内容
        Expanded(
          child: Obx(
            () => ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: userTagList.length,
              itemBuilder: (context, index) {
                // 偏移
                FollowUserTag item = userTagList[index];
                return ListTile(
                  key: ValueKey(item.id),
                  title: GestureDetector(
                    child: Text(item.tag),
                    onLongPress: () {
                      {
                        editTagDialog("修改标签", followUserTag: item);
                      }
                    },
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      removeTag(item);
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: "绑定平台分类",
                        icon: Icon(
                          item.bindings.isEmpty ? Icons.sell_outlined : Icons.sell,
                          color: item.bindings.isEmpty ? null : Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          showTagBindingManager(item);
                        },
                      ),
                      ReorderableDelayedDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                    ],
                  ),
                );
              },
              onReorderItem: (int oldIndex, int newIndex) {
                updateTagOrder(oldIndex, newIndex);
              },
            ),
          ),
        ),
      ]),
    );
  }

  void editTagDialog(String title, {FollowUserTag? followUserTag}) {
    final TextEditingController tagEditController = TextEditingController(text: followUserTag?.tag);
    bool upMode = title == "添加标签" ? true : false;
    Get.dialog(
      AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        content: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
              TextField(
                controller: tagEditController,
                minLines: 1,
                maxLines: 1,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: AppStyle.edgeInsetsA12,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(
                        alpha: .2,
                      ),
                    ),
                  ),
                ),
                onSubmitted: (tag) {
                  upMode ? addTag(tagEditController.text) : updateTagName(followUserTag!, tagEditController.text);
                  Get.back();
                },
              ),
              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      child: const Text('否'),
                    ),
                    TextButton(
                      onPressed: () {
                        upMode
                            ? addTag(tagEditController.text)
                            : updateTagName(
                                followUserTag!,
                                tagEditController.text,
                              );
                        Get.back();
                      },
                      child: const Text('是'),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- 标签绑定平台分类（自动归类） ----------------

  /// 标签绑定管理：查看/新增/删除 绑定的平台分类
  void showTagBindingManager(FollowUserTag tag) {
    editingTag.value = tag;
    editingBindings.assignAll(tag.bindings);
    Utils.showBottomSheet(
      title: "「${tag.tag}」绑定的平台分类",
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppStyle.divider,
        ListTile(
          title: const Text("添加平台分类"),
          subtitle: const Text("关注该分类下的主播时，会自动归入此标签"),
          leading: const Icon(Icons.add),
          onTap: () {
            Get.back();
            showBindingSitePicker(tag);
          },
        ),
        AppStyle.divider,
        Expanded(
          child: Obx(
            () => editingBindings.isEmpty
                ? const Center(child: Text("尚未绑定平台分类"))
                : ListView.builder(
                    itemCount: editingBindings.length,
                    itemBuilder: (context, index) {
                      final binding = editingBindings[index];
                      final siteName = Sites.allSites[binding.siteId]?.name ?? binding.siteId;
                      return ListTile(
                        title: Text(binding.categoryName.isEmpty ? binding.categoryId : binding.categoryName),
                        subtitle: Text("$siteName  ID: ${binding.categoryId}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            removeTagBinding(tag, binding);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ]),
    );
  }

  /// 选择平台
  void showBindingSitePicker(FollowUserTag tag) {
    final sites = Sites.supportSites;
    Get.dialog(
      SimpleDialog(
        title: const Text("选择平台"),
        children: sites
            .map(
              (site) => SimpleDialogOption(
                onPressed: () {
                  Get.back();
                  showCategoryPicker(tag, site);
                },
                child: Row(
                  children: [
                    Image.asset(site.logo, width: 20),
                    AppStyle.hGap12,
                    Text(site.name),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  /// 选择平台下的分类
  Future<void> showCategoryPicker(FollowUserTag tag, Site site) async {
    SmartDialog.showLoading(msg: "加载分类中");
    List<LiveCategory> categories;
    try {
      categories = await site.liveSite.getCategories();
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast("分类加载失败");
      Log.logPrint(e);
      return;
    }
    SmartDialog.dismiss();
    final List<LiveSubCategory> subs = [];
    final Map<String, String> parentNames = {};
    for (final category in categories) {
      parentNames[category.id] = category.name;
      subs.addAll(category.children);
    }
    final TextEditingController filterController = TextEditingController();
    final RxString keyword = "".obs;
    Get.dialog(
      AlertDialog(
        contentPadding: AppStyle.edgeInsetsA12,
        title: Text("${site.name} 分类"),
        content: SizedBox(
          width: 420,
          height: 460,
          child: Column(
            children: [
              TextField(
                controller: filterController,
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search),
                  hintText: "搜索分类",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => keyword.value = value,
              ),
              AppStyle.vGap8,
              Expanded(
                child: Obx(() {
                  final kw = keyword.value.trim();
                  final list = kw.isEmpty ? subs : subs.where((e) => e.name.contains(kw)).toList();
                  if (list.isEmpty) {
                    return const Center(child: Text("没有匹配的分类"));
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final sub = list[index];
                      final parentName = parentNames[sub.parentId] ?? "";
                      final bound = tag.bindings.any((b) => b.matches(site.id, sub.id));
                      return ListTile(
                        dense: true,
                        title: Text(sub.name),
                        subtitle: parentName.isEmpty ? null : Text(parentName),
                        trailing: bound ? const Icon(Icons.link) : null,
                        onTap: () {
                          Get.back();
                          addTagBinding(tag, site.id, sub.id, sub.name);
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 新增绑定
  Future<void> addTagBinding(FollowUserTag tag, String siteId, String categoryId, String categoryName) async {
    if (tag.bindings.any((binding) => binding.matches(siteId, categoryId))) {
      SmartDialog.showToast("该分类已绑定");
      return;
    }
    tag.bindings = [...tag.bindings, TagBinding(siteId: siteId, categoryId: categoryId, categoryName: categoryName)];
    await FollowService.instance.updateFollowUserTag(tag);
    editingBindings.assignAll(tag.bindings);
    updateTagList();
    SmartDialog.showToast("已绑定「$categoryName」");
    // 已取得分类的关注立即归类一次，其余会在下次刷新时归类
    await FollowService.instance.applyAutoTags();
  }

  /// 删除绑定
  Future<void> removeTagBinding(FollowUserTag tag, TagBinding binding) async {
    tag.bindings =
        tag.bindings.where((item) => !item.matches(binding.siteId, binding.categoryId)).toList();
    await FollowService.instance.updateFollowUserTag(tag);
    editingBindings.assignAll(tag.bindings);
    updateTagList();
  }

  // 关注清理功能
  Future<void> cleanFollow(List<FollowUser> cleanPool) async {
    if (cleanPool.isEmpty) {
      SmartDialog.showToast("没有需要清理的用户");
      return;
    }
    SmartDialog.showLoading(msg: "清理中");
    for (var follow in cleanPool) {
      // 取消关注同时删除标签内的 userId
      if (follow.tag != "全部") {
        var tag = userTagList.firstWhere((tag) => tag.tag == follow.tag);
        tag.userId.remove(follow.id);
        await updateTag(tag);
      }
      await FollowService.instance.removeFollowUser(follow.id);
    }
    SmartDialog.dismiss();
    EventBus.instance.emit(Constant.kUpdateFollow, 0);
    SmartDialog.showToast("清理完成");
  }

  List<FollowUser> buildAutoCleanPool() {
    var followList = FollowService.instance.followList;
    var histories = HistoryService.instance.getHistories();
    if (histories.isEmpty || followList.isEmpty) return [];
    // 筛选出历史记录里已关注的
    final followedIds = followList.map((follow) => follow.id).toSet(); // set性能略优
    final followedHistories = histories.where((history) => followedIds.contains(history.id)).toList();
    if (followedHistories.isEmpty) return [];

    List<Condition> conditions = [
      // Condition('siteId', FilterOperator.equals, Constant.kBiliBili),
      Condition(
        'watchDuration',
        FilterOperator.lessThan,
        Duration(minutes: minutes.value),
        comparableValueProvider: (watchDuration) {
          if (watchDuration is String) {
            return watchDuration.toDuration();
          }
          return null;
        },
      ),
    ];
    // 根据动态条件筛选出需要清理的 关注id
    final df = dynamicFilter(followedHistories, conditions, takeLast: takeLast.value);
    final uidsToClean = df.map((history) => history.id).toSet();

    final autoCleanPool = followList.where((follow) => uidsToClean.contains(follow.id)).toList();
    return autoCleanPool;
  }
}
