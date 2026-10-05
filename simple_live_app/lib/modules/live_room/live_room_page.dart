import 'dart:io';

import 'package:floating/floating.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/live_room/danmaku/chat_emoticon_span.dart';
import 'package:simple_live_app/modules/live_room/live_room_controller.dart';
import 'package:simple_live_app/modules/live_room/player/player_controls.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/widgets/context_menu.dart';
import 'package:simple_live_app/widgets/desktop_refresh_button.dart';
import 'package:simple_live_app/widgets/follow_user_item.dart';
import 'package:simple_live_app/widgets/keep_alive_wrapper.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_number.dart';
import 'package:simple_live_app/widgets/settings/settings_switch.dart';
import 'package:simple_live_app/widgets/superchat_card.dart';
import 'package:simple_live_core/simple_live_core.dart';

class LiveRoomPage extends GetView<LiveRoomController> {
  const LiveRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    final page = Obx(
      () {
        if (controller.loadError.value) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("直播间加载失败"),
            ),
            body: Padding(
              padding: AppStyle.edgeInsetsA12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LottieBuilder.asset(
                    'assets/lotties/error.json',
                    height: 140,
                    repeat: false,
                  ),
                  const Text(
                    "直播间加载失败",
                    textAlign: TextAlign.center,
                  ),
                  AppStyle.vGap4,
                  Text(
                    controller.error?.toString() ?? "未知错误",
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  AppStyle.vGap4,
                  Text(
                    "${controller.rxSite.value.id} - ${controller.rxRoomId.value}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: controller.copyErrorDetail,
                        icon: const Icon(Remix.file_copy_line),
                        label: const Text("复制信息"),
                      ),
                      TextButton.icon(
                        onPressed: controller.refreshRoom,
                        icon: const Icon(Remix.refresh_line),
                        label: const Text("刷新"),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        }
        if (controller.fullScreenState.value) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (e, r) {
              controller.exitFull();
            },
            child: Scaffold(
              body: buildMediaPlayer(),
            ),
          );
        } else {
          return buildPageUI();
        }
      },
    );
    if (!Platform.isAndroid) {
      return page;
    }
    return PiPSwitcher(
      floating: controller.pip,
      childWhenDisabled: page,
      childWhenEnabled: buildMediaPlayer(),
    );
  }

  Widget buildPageUI() {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          appBar: AppBar(
            title: Obx(
              () => Text(controller.detail.value?.title ?? "直播间"),
            ),
            actions: buildAppbarActions(context),
          ),
          body: orientation == Orientation.portrait ? buildPhoneUI(context) : buildTabletUI(context),
        );
      },
    );
  }

  Widget buildPhoneUI(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: buildMediaPlayer(),
        ),
        buildUserProfile(context),
        buildMessageArea(),
        buildBottomActions(context),
      ],
    );
  }

  /// 播放器与右侧消息面板之间的分隔条：
  /// 横向拖拽调节面板宽度（实时生效，松手时持久化），双击恢复默认 300
  Widget buildPanelResizeHandle() {
    final settings = AppSettingsController.instance;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (d) {
          final w = settings.messagePanelWidth.value - d.delta.dx;
          settings.messagePanelWidth.value = w.clamp(220.0, 800.0);
        },
        onHorizontalDragEnd: (_) {
          settings.saveMessagePanelWidth();
        },
        onDoubleTap: () {
          settings.setMessagePanelWidth(300.0);
        },
        child: Container(
          width: 8,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Container(
            width: 2,
            color: Colors.grey.withAlpha(50),
          ),
        ),
      ),
    );
  }

  Widget buildTabletUI(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: buildMediaPlayer(),
              ),
              buildPanelResizeHandle(),
              Obx(
                () => SizedBox(
                  width:
                      AppSettingsController.instance.messagePanelWidth.value,
                  child: Column(
                    children: [
                      buildUserProfile(context),
                      buildMessageArea(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(
                color: Colors.grey.withAlpha(25),
              ),
            ),
          ),
          padding: AppStyle.edgeInsetsV4.copyWith(
            bottom: AppStyle.bottomBarHeight + 4,
          ),
          child: Row(
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 14),
                ),
                onPressed: controller.refreshRoom,
                icon: const Icon(Remix.refresh_line),
                label: const Text("刷新"),
              ),
              Obx(
                () => controller.followed.value
                    ? TextButton.icon(
                        style: TextButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                        onPressed: controller.removeFollowUser,
                        icon: const Icon(Remix.heart_fill),
                        label: const Text("取消关注"),
                      )
                    : TextButton.icon(
                        style: TextButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                        onPressed: controller.followUser,
                        icon: const Icon(Remix.heart_line),
                        label: const Text("关注"),
                      ),
              ),
              const Expanded(child: Center()),
              TextButton.icon(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 14),
                ),
                onPressed: controller.share,
                icon: const Icon(Remix.share_line),
                label: const Text("分享"),
              ),
              (Platform.isWindows || Platform.isLinux)
                  ? TextButton.icon(
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      onPressed: controller.visitWebLive,
                      icon: const Icon(Remix.chrome_fill),
                      label: const Text("浏览器打开"),
                    )
                  : TextButton.icon(
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      onPressed: controller.copyUrl,
                      icon: const Icon(Remix.file_copy_line),
                      label: const Text("复制链接"),
                    ),
            ],
          ),
        ),
        //buildBottomActions(context),
      ],
    );
  }

  Widget buildMediaPlayer() {
    var boxFit = BoxFit.contain;
    double? aspectRatio;
    if (AppSettingsController.instance.scaleMode.value == 0) {
      boxFit = BoxFit.contain;
    } else if (AppSettingsController.instance.scaleMode.value == 1) {
      boxFit = BoxFit.fill;
    } else if (AppSettingsController.instance.scaleMode.value == 2) {
      boxFit = BoxFit.cover;
    } else if (AppSettingsController.instance.scaleMode.value == 3) {
      boxFit = BoxFit.contain;
      aspectRatio = 16 / 9;
    } else if (AppSettingsController.instance.scaleMode.value == 4) {
      boxFit = BoxFit.contain;
      aspectRatio = 4 / 3;
    } else if (AppSettingsController.instance.scaleMode.value == 5) {
      boxFit = BoxFit.contain;
      double aspectByUser = AppSettingsController.instance.aspectByUser.value;
      aspectRatio = aspectByUser;
    }
    return Stack(
      children: [
        Video(
          key: controller.globalPlayerKey,
          controller: controller.videoController,
          pauseUponEnteringBackgroundMode: AppSettingsController.instance.playerAutoPause.value,
          resumeUponEnteringForegroundMode: AppSettingsController.instance.playerAutoPause.value,
          controls: (state) {
            return playerControls(state, controller);
          },
          aspectRatio: aspectRatio,
          fit: boxFit,
          // 自己实现
          wakelock: false,
        ),
        Obx(
          () => Visibility(
            visible: !controller.liveStatus.value,
            child: const Center(
              child: Text(
                "未开播",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildUserProfile(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withAlpha(25),
          ),
          bottom: BorderSide(
            color: Colors.grey.withAlpha(25),
          ),
        ),
      ),
      padding: AppStyle.edgeInsetsA8.copyWith(
        left: 12,
        right: 12,
      ),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withAlpha(50)),
                borderRadius: AppStyle.radius24,
              ),
              child: NetImage(
                controller.detail.value?.userAvatar ?? "",
                width: 48,
                height: 48,
                borderRadius: 24,
              ),
            ),
            AppStyle.hGap12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.detail.value?.userName ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppStyle.vGap4,
                  Row(
                    children: [
                      Image.asset(
                        controller.site.logo,
                        width: 20,
                      ),
                      AppStyle.hGap4,
                      Text(
                        controller.site.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppStyle.hGap12,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Remix.fire_fill,
                  size: 20,
                  color: Colors.orange,
                ),
                AppStyle.hGap4,
                Text(
                  Utils.onlineToString(
                    controller.detail.value?.online ?? 0,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withAlpha(25),
          ),
        ),
      ),
      padding: EdgeInsets.only(bottom: AppStyle.bottomBarHeight),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => controller.followed.value
                  ? TextButton.icon(
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      onPressed: controller.removeFollowUser,
                      icon: const Icon(Remix.heart_fill),
                      label: const Text("取消关注"),
                    )
                  : TextButton.icon(
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      onPressed: controller.followUser,
                      icon: const Icon(Remix.heart_line),
                      label: const Text("关注"),
                    ),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 14),
              ),
              onPressed: controller.refreshRoom,
              icon: const Icon(Remix.refresh_line),
              label: const Text("刷新"),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 14),
              ),
              onPressed: controller.share,
              icon: const Icon(Remix.share_line),
              label: const Text("分享"),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMessageArea() {
    return Expanded(
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: EdgeInsets.zero,
              indicatorWeight: 1.0,
              tabs: [
                const Tab(
                  text: "聊天",
                ),
                Tab(
                  child: Obx(
                    () => Text(
                      controller.superChats.isNotEmpty ? "SC(${controller.superChats.length})" : "SC",
                    ),
                  ),
                ),
                const Tab(
                  text: "关注",
                ),
                const Tab(
                  text: "设置",
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Obx(
                    () => Stack(
                      children: [
                        ListView.separated(
                          controller: controller.scrollController,
                          separatorBuilder: (_, i) => Obx(
                            () => SizedBox(
                              // *2与原来的EdgeInsets.symmetric(vertical: )做兼容
                              height: AppSettingsController.instance.chatTextGap.value * 2,
                            ),
                          ),
                          padding: AppStyle.edgeInsetsA12,
                          itemCount: controller.messages.length,
                          itemBuilder: (context, i) {
                            var item = controller.messages[i];
                            return buildMessageItem(item, context);
                          },
                        ),
                        Visibility(
                          visible: controller.disableAutoScroll.value,
                          child: Positioned(
                            right: 12,
                            bottom: 12,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                controller.disableAutoScroll.value = false;
                                controller.chatScrollToBottom();
                              },
                              icon: const Icon(Icons.expand_more),
                              label: const Text("最新"),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  buildSuperChats(),
                  buildFollowList(),
                  buildSettings(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMessageItem(LiveMessage message, BuildContext context) {
    if (message.userName == "LiveSysMessage") {
      return Obx(
        () => SelectableText(
          message.message,
          style: TextStyle(
            color: Colors.grey,
            fontSize: AppSettingsController.instance.chatTextSize.value,
          ),
        ),
      );
    }

    return Obx(
      () => AppSettingsController.instance.chatBubbleStyle.value
          ? Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withAlpha(25),
                      //borderRadius: AppStyle.radius8,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    padding: AppStyle.edgeInsetsA4.copyWith(left: 12, right: 12),
                    child: SelectableText.rich(
                      TextSpan(
                        text: "${message.userName}：",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: AppSettingsController.instance.chatTextSize.value,
                        ),
                        children: buildChatMessageSpans(
                          context,
                          message,
                          TextStyle(
                            color: Get.isDarkMode ? Colors.white : AppColors.black333,
                            // 行内表情的高度按这份 style 的字号推算，必须与正文同源，
                            // 否则用户调「聊天字号」后文字与表情尺寸脱节
                            fontSize: AppSettingsController.instance.chatTextSize.value,
                          ),
                          emoticonsEnabled: AppSettingsController
                              .instance.danmuEmoticonEnable.value,
                        ),
                      ),
                      contextMenuBuilder: _contextMenuBuilderFor(
                        message,
                        fallback: _defaultContextMenu,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SelectableText.rich(
              TextSpan(
                text: "${message.userName}：",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: AppSettingsController.instance.chatTextSize.value,
                ),
                children: buildChatMessageSpans(
                  context,
                  message,
                  TextStyle(
                    color: Get.isDarkMode ? Colors.white : AppColors.black333,
                    fontSize: AppSettingsController.instance.chatTextSize.value,
                  ),
                  emoticonsEnabled:
                      AppSettingsController.instance.danmuEmoticonEnable.value,
                ),
              ),
              contextMenuBuilder: _contextMenuBuilderFor(
                message,
                fallback: _contextMenuBuilder,
              ),
            ),
    );
  }

  /// 会渲染出表情的消息，只在**选区里没有真实文字**时不建上下文菜单。
  ///
  /// `SelectableText.rich` 里的 `WidgetSpan` 在文本里是一个占位字符（`\uFFFC`）。
  /// 右键落在图片上时会把这个占位符当成一个"词"选中：selection 是**有效的**，
  /// 但 `customContextMenuBuilder` 拿它去 `textInside` 时又可能越界抛
  /// `RangeError (start)`；系统默认菜单则干脆给出「复制」，复制出来的是一个
  /// 看不见的占位符——两者都不是可用状态。
  /// 判据因此不能只看 `selection.isValid`，要看剥掉占位符与空白之后还剩不剩
  /// 真实文字：混排消息（`白花300块[热]`）右键点在正文上仍应保留屏蔽/复制能力。
  Widget Function(BuildContext, EditableTextState) _contextMenuBuilderFor(
    LiveMessage message, {
    required Widget Function(BuildContext, EditableTextState) fallback,
  }) {
    final rendersEmoticon = AppSettingsController
            .instance.danmuEmoticonEnable.value &&
        (message.emoticons?.isNotEmpty ?? false);
    if (!rendersEmoticon) {
      return fallback;
    }
    return (context, state) {
      final value = state.textEditingValue;
      if (!shouldShowContextMenu(value.text, value.selection)) {
        return _noContextMenu(context, state);
      }
      return fallback(context, state);
    };
  }

  Widget _noContextMenu(BuildContext context, EditableTextState state) {
    return const SizedBox.shrink();
  }

  /// 与 `SelectableText` 的默认菜单等价（框架里那份 `_defaultContextMenuBuilder`
  /// 是私有的，这里照抄它唯一的一行），保证气泡样式下普通消息的菜单不变。
  Widget _defaultContextMenu(BuildContext context, EditableTextState state) {
    return AdaptiveTextSelectionToolbar.editableText(editableTextState: state);
  }

  Widget _contextMenuBuilder(BuildContext context, EditableTextState editableTextState) {
    // 入参要先剥掉表情占位符：拖选跨过 `白花300块[热]` 时选中文本里带着 \uFFFC，
    // 原样写进屏蔽表就与弹幕原文 `[热]` 永远匹配不上，屏蔽词静默失效
    return customContextMenuBuilder(
      context,
      editableTextState,
      {
        '屏蔽用户': (s) =>
            controller.addCurBlockAccount(stripEmoticonPlaceholder(s)),
        '屏蔽关键词': (s) =>
            controller.addCurBlockWord(stripEmoticonPlaceholder(s)),
      },
    );
  }

  Widget buildSuperChats() {
    return KeepAliveWrapper(
      child: Obx(
        () => ListView.separated(
          padding: AppStyle.edgeInsetsA12,
          itemCount: controller.superChats.length,
          separatorBuilder: (_, i) => AppStyle.vGap12,
          itemBuilder: (_, i) {
            var item = controller.superChats[i];
            return SuperChatCard(
              item,
            );
          },
        ),
      ),
    );
  }

  Widget buildSettings() {
    return ListView(
      padding: AppStyle.edgeInsetsA12,
      children: [
        Obx(
          () => Visibility(
            visible: controller.autoExitEnable.value,
            child: ListTile(
              leading: const Icon(Icons.timer_outlined),
              visualDensity: VisualDensity.compact,
              title: Text("${parseDuration(controller.countdown.value)}后自动关闭"),
            ),
          ),
        ),
        Padding(
          padding: AppStyle.edgeInsetsA12,
          child: Text(
            "聊天区",
            style: Get.textTheme.titleSmall,
          ),
        ),
        SettingsCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => SettingsNumber(
                  title: "文字大小",
                  value: AppSettingsController.instance.chatTextSize.value.toInt(),
                  min: 8,
                  max: 36,
                  onChanged: (e) {
                    AppSettingsController.instance.setChatTextSize(e.toDouble());
                  },
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsNumber(
                  title: "上下间隔",
                  value: AppSettingsController.instance.chatTextGap.value.toInt(),
                  min: 0,
                  max: 12,
                  onChanged: (e) {
                    AppSettingsController.instance.setChatTextGap(e.toDouble());
                  },
                ),
              ),
              AppStyle.divider,
              Obx(
                () => SettingsSwitch(
                  title: "气泡样式",
                  value: AppSettingsController.instance.chatBubbleStyle.value,
                  onChanged: (e) {
                    AppSettingsController.instance.setChatBubbleStyle(e);
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: AppStyle.edgeInsetsA12,
          child: Text(
            "更多设置",
            style: Get.textTheme.titleSmall,
          ),
        ),
        SettingsCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SettingsAction(
                title: "关键词屏蔽",
                onTap: controller.showFollowBlockShield,
              ),
              SettingsAction(
                title: "用户屏蔽",
                onTap: () => controller.showFollowBlockShield(blockWords: false),
              ),
              AppStyle.divider,
              SettingsAction(
                title: "弹幕设置",
                onTap: controller.showDanmuSettingsSheet,
              ),
              AppStyle.divider,
              SettingsAction(
                title: "定时关闭",
                onTap: controller.showAutoExitSheet,
              ),
              AppStyle.divider,
              SettingsAction(
                title: "画面尺寸",
                onTap: controller.showPlayerSettingsSheet,
              ),
              AppStyle.divider,
              SettingsAction(
                title: "自定义画面尺寸",
                onTap: controller.showAspectRatioSheet,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildFollowList() {
    return Obx(
      () => Stack(
        children: [
          RefreshIndicator(
            onRefresh: FollowService.instance.loadData,
            child: ListView.builder(
              itemCount: FollowService.instance.liveList.length,
              itemBuilder: (_, i) {
                var item = FollowService.instance.liveList[i];
                return Obx(
                  () => FollowUserItem(
                    item: item,
                    playing: controller.rxSite.value.id == item.siteId && controller.rxRoomId.value == item.roomId,
                    onTap: () {
                      controller.resetRoom(
                        Sites.allSites[item.siteId]!,
                        item.roomId,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          if (Platform.isLinux || Platform.isWindows || Platform.isMacOS)
            Positioned(
              right: 12,
              bottom: 12,
              child: Obx(
                () => DesktopRefreshButton(
                  refreshing: FollowService.instance.updating.value,
                  onPressed: FollowService.instance.loadData,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> buildAppbarActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          showMore();
        },
        icon: const Icon(Icons.more_horiz),
      ),
    ];
  }

  void showMore() {
    showModalBottomSheet(
      context: Get.context!,
      constraints: const BoxConstraints(
        maxWidth: 600,
      ),
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: AppStyle.bottomBarHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text("刷新"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                controller.refreshRoom();
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              trailing: const Icon(Icons.chevron_right),
              title: const Text("切换清晰度"),
              onTap: () {
                Get.back();
                controller.showQualitySheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.switch_video_outlined),
              title: const Text("切换线路"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.showPlayUrlsSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.aspect_ratio_outlined),
              title: const Text("画面尺寸"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.showPlayerSettingsSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text("截图"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                controller.saveScreenshot();
              },
            ),
            Visibility(
              visible: Platform.isAndroid,
              child: ListTile(
                leading: const Icon(Icons.picture_in_picture),
                title: const Text("小窗播放"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Get.back();
                  controller.enablePIP();
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text("定时关闭"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.showAutoExitSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_sharp),
              title: const Text("分享直播间"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.share();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text("复制链接"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.copyUrl();
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text("APP 中打开"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.openNaviteAPP();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text("播放信息"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.showDebugInfo();
              },
            ),
          ],
        ),
      ),
    );
  }

  String parseDuration(int sec) {
    // 转为时分秒
    var h = sec ~/ 3600;
    var m = (sec % 3600) ~/ 60;
    var s = sec % 60;
    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}小时${m.toString().padLeft(2, '0')}分钟${s.toString().padLeft(2, '0')}秒";
    }
    if (m > 0) {
      return "${m.toString().padLeft(2, '0')}分钟${s.toString().padLeft(2, '0')}秒";
    }
    return "${s.toString().padLeft(2, '0')}秒";
  }
}
