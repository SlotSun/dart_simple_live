import 'dart:io';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/live_room/live_room_controller.dart';
import 'package:simple_live_app/modules/settings/appstyle_settings/appstyle_setting_contorller.dart';
import 'package:simple_live_app/modules/settings/danmu_settings_page.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/widgets/desktop_refresh_button.dart';
import 'package:simple_live_app/widgets/follow_user_item.dart';
import 'package:window_manager/window_manager.dart';

Widget playerControls(
  VideoState videoState,
  LiveRoomController controller,
) {
  return Obx(() {
    if (controller.fullScreenState.value) {
      return buildFullControls(
        videoState,
        controller,
      );
    }
    return buildControls(
      videoState.context.orientation == Orientation.portrait,
      videoState,
      controller,
    );
  });
}

Widget buildDragToMoveArea({required Widget child}) {
  return (!Platform.isAndroid && !Platform.isIOS)
      ? DragToMoveArea(
          child: child,
        )
      : child;
}

Widget buildFullControls(
  VideoState videoState,
  LiveRoomController controller,
) {
  var padding = MediaQuery.of(videoState.context).padding;
  GlobalKey volumeButtonkey = GlobalKey();
  return buildDragToMoveArea(
    child: Stack(
      children: [
        Container(),
        buildDanmuView(videoState, controller),
        Center(
          child: StreamBuilder(
            stream: videoState.widget.controller.player.stream.buffering,
            initialData: videoState.widget.controller.player.state.buffering,
            builder: (_, s) => Visibility(
              visible: s.data ?? false,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            onTap: controller.onTap,
            onDoubleTapDown: controller.onDoubleTap,
            onLongPress: () {
              if (controller.lockControlsState.value) {
                return;
              }
              showFollowUser(controller);
            },
            onVerticalDragStart: controller.onVerticalDragStart,
            onVerticalDragUpdate: controller.onVerticalDragUpdate,
            onVerticalDragEnd: controller.onVerticalDragEnd,
            child: MouseRegion(
              onHover: (PointerHoverEvent event) {
                controller.onHover(event, videoState.context);
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
          ),
        ),
        Obx(
          () => AnimatedPositioned(
            left: 0,
            right: 0,
            top: (controller.showControlsState.value &&
                    !controller.lockControlsState.value)
                ? 0
                : -(56 + padding.top),
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: EdgeInsets.only(
                left: padding.left + 12,
                right: padding.right + 12,
                top: padding.top + 8,
                bottom: 8,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black87,
                  ],
                ),
              ),
              child: _overlayControlsTheme(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (controller.smallWindowState.value) {
                          controller.exitSmallWindow();
                        } else {
                          controller.exitFull();
                        }
                      },
                      icon: const Icon(Icons.arrow_back, size: 22),
                    ),
                    AppStyle.hGap12,
                    Expanded(
                      child: Text(
                        "${controller.detail.value?.title} - ${controller.detail.value?.userName}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AppStyle.hGap12,
                    IconButton(
                      onPressed: () {
                        controller.saveScreenshot();
                      },
                      icon: const Icon(Icons.camera_alt_outlined, size: 22),
                    ),
                    IconButton(
                      onPressed: () {
                        showFollowUser(controller);
                      },
                      icon: const Icon(Remix.play_list_2_line, size: 22),
                    ),
                    Visibility(
                      visible: Platform.isAndroid,
                      child: IconButton(
                        onPressed: () {
                          controller.enablePIP();
                        },
                        icon: const Icon(Icons.picture_in_picture, size: 22),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showPlayerSettings(controller);
                      },
                      icon: const Icon(Icons.more_horiz, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Obx(
          () => AnimatedPositioned(
            left: 0,
            right: 0,
            bottom: (controller.showControlsState.value &&
                    !controller.lockControlsState.value)
                ? 0
                : -(88 + padding.bottom),
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black87,
                  ],
                ),
              ),
              padding: EdgeInsets.only(
                left: padding.left + 12,
                right: padding.right + 12,
                bottom: padding.bottom + 8,
                top: 24,
              ),
              child: _overlayControlsTheme(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        controller.refreshRoom();
                      },
                      icon: const Icon(Remix.refresh_line),
                    ),
                    Offstage(
                      offstage: controller.showDanmakuState.value,
                      child: IconButton(
                        onPressed: () => controller.showDanmakuState.value =
                            !controller.showDanmakuState.value,
                        icon: const ImageIcon(
                          AssetImage('assets/icons/icon_danmaku_open.png'),
                          size: 22,
                        ),
                      ),
                    ),
                    Offstage(
                      offstage: !controller.showDanmakuState.value,
                      child: IconButton(
                        onPressed: () => controller.showDanmakuState.value =
                            !controller.showDanmakuState.value,
                        icon: const ImageIcon(
                          AssetImage('assets/icons/icon_danmaku_close.png'),
                          size: 22,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showDanmakuSettings(controller);
                      },
                      icon: const ImageIcon(
                        AssetImage('assets/icons/icon_danmaku_setting.png'),
                        size: 22,
                      ),
                    ),
                    const Expanded(child: Center()),
                    Visibility(
                      visible: !Platform.isAndroid && !Platform.isIOS,
                      child: IconButton(
                        key: volumeButtonkey,
                        onPressed: () {
                          controller
                              .showVolumeSlider(volumeButtonkey.currentContext!);
                        },
                        icon: const Icon(Icons.volume_down, size: 22),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        showQualitesInfo(controller);
                      },
                      child: Obx(
                        () => Text(
                          controller.currentQualityInfo.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        showLinesInfo(controller);
                      },
                      child: Text(
                        controller.currentLineInfo.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        controller.enterFullScreen();
                      },
                      icon: const Icon(Remix.fullscreen_line),
                    ),
                    IconButton(
                      onPressed: () {
                        if (controller.smallWindowState.value) {
                          controller.exitSmallWindow();
                        } else {
                          controller.exitFull();
                        }
                      },
                      icon: const Icon(Remix.fullscreen_exit_fill),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Obx(
          () => AnimatedPositioned(
            top: 0,
            bottom: 0,
            right: controller.showControlsState.value
                ? padding.right + 12
                : -(64 + padding.right),
            duration: const Duration(milliseconds: 200),
            child: buildLockButton(controller),
          ),
        ),
        Obx(
          () => AnimatedPositioned(
            top: 0,
            bottom: 0,
            left: controller.showControlsState.value
                ? padding.left + 12
                : -(64 + padding.right),
            duration: const Duration(milliseconds: 200),
            child: buildLockButton(controller),
          ),
        ),
        _buildGestureTip(controller),
      ],
    ),
  );
}

Widget buildLockButton(LiveRoomController controller) {
  return Center(
    child: InkWell(
      onTap: () {
        controller.setLockState();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(150),
          borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
          border: Border.all(color: Colors.white.withAlpha(36)),
        ),
        width: 44,
        height: 44,
        child: Center(
          child: Icon(
            controller.lockControlsState.value
                ? Icons.lock_outline_rounded
                : Icons.lock_open_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    ),
  );
}

Widget buildControls(
  bool isPortrait,
  VideoState videoState,
  LiveRoomController controller,
) {
  GlobalKey volumeButtonkey = GlobalKey();
  return Stack(
    children: [
      Container(),
      buildDanmuView(videoState, controller),
      Center(
        child: StreamBuilder(
          stream: videoState.widget.controller.player.stream.buffering,
          initialData: videoState.widget.controller.player.state.buffering,
          builder: (_, s) => Visibility(
            visible: s.data ?? false,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
      Positioned.fill(
        child: GestureDetector(
          onTap: controller.onTap,
          onDoubleTapDown: controller.onDoubleTap,
          onVerticalDragStart: controller.onVerticalDragStart,
          onVerticalDragUpdate: controller.onVerticalDragUpdate,
          onVerticalDragEnd: controller.onVerticalDragEnd,
          child: MouseRegion(
            onEnter: controller.onEnter,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
        ),
      ),
      Obx(
        () => AnimatedPositioned(
          left: 0,
          right: 0,
          bottom: controller.showControlsState.value ? 0 : -56,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black87,
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
            child: _overlayControlsTheme(
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      controller.refreshRoom();
                    },
                    icon: const Icon(Remix.refresh_line),
                  ),
                  Offstage(
                    offstage: controller.showDanmakuState.value,
                    child: IconButton(
                      onPressed: () => controller.showDanmakuState.value =
                          !controller.showDanmakuState.value,
                      icon: const ImageIcon(
                        AssetImage('assets/icons/icon_danmaku_open.png'),
                        size: 22,
                      ),
                    ),
                  ),
                  Offstage(
                    offstage: !controller.showDanmakuState.value,
                    child: IconButton(
                      onPressed: () => controller.showDanmakuState.value =
                          !controller.showDanmakuState.value,
                      icon: const ImageIcon(
                        AssetImage('assets/icons/icon_danmaku_close.png'),
                        size: 22,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      controller.showDanmuSettingsSheet();
                    },
                    icon: const ImageIcon(
                      AssetImage('assets/icons/icon_danmaku_setting.png'),
                      size: 22,
                    ),
                  ),
                  const Expanded(child: Center()),
                  Visibility(
                    visible: !Platform.isAndroid && !Platform.isIOS,
                    child: IconButton(
                      key: volumeButtonkey,
                      onPressed: () {
                        controller.showVolumeSlider(
                          volumeButtonkey.currentContext!,
                        );
                      },
                      icon: const Icon(Icons.volume_down, size: 22),
                    ),
                  ),
                  Offstage(
                    offstage: isPortrait,
                    child: TextButton(
                      onPressed: () {
                        controller.showQualitySheet();
                      },
                      child: Obx(
                        () => Text(
                          controller.currentQualityInfo.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  Offstage(
                    offstage: isPortrait,
                    child: TextButton(
                      onPressed: () {
                        controller.showPlayUrlsSheet();
                      },
                      child: Text(
                        controller.currentLineInfo.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: !Platform.isAndroid && !Platform.isIOS,
                    child: IconButton(
                      onPressed: () {
                        controller.enterSmallWindow();
                      },
                      icon: const Icon(Icons.picture_in_picture, size: 22),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      controller.enterFullScreen();
                    },
                    icon: const Icon(Remix.fullscreen_line),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      _buildGestureTip(controller),
    ],
  );
}

Widget _overlayControlsTheme({required Widget child}) {
  return IconButtonTheme(
    data: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withAlpha(24),
        disabledForegroundColor: Colors.white54,
        minimumSize: const Size(40, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
          side: BorderSide(color: Colors.white.withAlpha(28)),
        ),
      ),
    ),
    child: TextButtonTheme(
      data: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withAlpha(24),
          minimumSize: const Size(44, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
            side: BorderSide(color: Colors.white.withAlpha(28)),
          ),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: child,
    ),
  );
}

Widget _buildGestureTip(LiveRoomController controller) {
  return Obx(
    () => Offstage(
      offstage: !controller.showGestureTip.value,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(204),
            borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
            border: Border.all(color: Colors.white.withAlpha(36)),
          ),
          child: Text(
            controller.gestureTipText.value,
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    ),
  );
}

Widget buildDanmuView(VideoState videoState, LiveRoomController controller) {
  var padding = MediaQuery.of(videoState.context).padding;
  controller.danmakuView ??= DanmakuScreen(
    createdController: controller.initDanmakuController,
    option: DanmakuOption(
      fontSize: AppSettingsController.instance.danmuSize.value,
      area: AppSettingsController.instance.danmuArea.value,
      duration: AppSettingsController.instance.danmuSpeed.value,
      opacity: AppSettingsController.instance.danmuOpacity.value,
      strokeWidth: AppSettingsController.instance.danmuStrokeWidth.value,
      fontWeight: AppSettingsController.instance.danmuFontWeight.value,
      fontFamily: AppStyleSettingController.instance.curFontName.value,
    ),
  );
  return Positioned.fill(
    top: padding.top,
    bottom: padding.bottom,
    child: Obx(
      () => Offstage(
        offstage: !controller.showDanmakuState.value,
        child: Padding(
          padding: controller.fullScreenState.value
              ? EdgeInsets.only(
                  top: AppSettingsController.instance.danmuTopMargin.value,
                  bottom:
                      AppSettingsController.instance.danmuBottomMargin.value,
                )
              : EdgeInsets.zero,
          child: controller.danmakuView!,
        ),
      ),
    ),
  );
}

void showLinesInfo(LiveRoomController controller) {
  if (controller.isVertical.value) {
    controller.showPlayUrlsSheet();
    return;
  }
  Utils.showRightDialog(
    title: "线路",
    useSystem: true,
    child: ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: controller.playUrls.length,
      itemBuilder: (context, i) {
        return ListTile(
          selected: controller.currentLineIndex == i,
          title: Text.rich(
            TextSpan(
              text: "线路${i + 1}",
              children: [
                WidgetSpan(
                    child: Container(
                  decoration: BoxDecoration(
                    borderRadius: AppStyle.radius4,
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  padding: AppStyle.edgeInsetsH4,
                  margin: AppStyle.edgeInsetsL8,
                  child: Text(
                    controller.playUrls[i].contains(".flv") ? "FLV" : "HLS",
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                )),
              ],
            ),
            style: const TextStyle(fontSize: 14),
          ),
          minLeadingWidth: 16,
          onTap: () {
            Utils.hideRightDialog();
            //controller.currentLineIndex = i;
            //controller.setPlayer();
            controller.changePlayLine(i);
          },
        );
      },
    ),
  );
}

void showQualitesInfo(LiveRoomController controller) {
  if (controller.isVertical.value) {
    controller.showQualitySheet();
    return;
  }
  Utils.showRightDialog(
    title: "清晰度",
    useSystem: true,
    child: ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: controller.qualites.length,
      itemBuilder: (_, i) {
        var item = controller.qualites[i];
        return ListTile(
          selected: controller.currentQuality == i,
          title: Text(
            item.quality,
            style: const TextStyle(fontSize: 14),
          ),
          minLeadingWidth: 16,
          onTap: () {
            Utils.hideRightDialog();
            controller.currentQuality = i;
            controller.getPlayUrl();
          },
        );
      },
    ),
  );
}

void showDanmakuSettings(LiveRoomController controller) {
  if (controller.isVertical.value) {
    controller.showDanmuSettingsSheet();
    return;
  }
  Utils.showRightDialog(
    title: "弹幕设置",
    width: 400,
    useSystem: true,
    child: ListView(
      padding: AppStyle.edgeInsetsA12,
      children: [
        DanmuSettingsView(
          danmakuController: controller.danmakuController,
        ),
      ],
    ),
  );
}

void showPlayerSettings(LiveRoomController controller) {
  if (controller.isVertical.value) {
    controller.showPlayerSettingsSheet();
    return;
  }
  Utils.showRightDialog(
    title: "设置",
    width: 320,
    useSystem: true,
    child: Obx(
      () => ListView(
        padding: AppStyle.edgeInsetsV12,
        children: [
          Padding(
            padding: AppStyle.edgeInsetsH16,
            child: Text(
              "画面尺寸",
              style: Get.textTheme.titleMedium,
            ),
          ),
          RadioGroup(
            groupValue: AppSettingsController.instance.scaleMode.value,
            onChanged: (e) {
              AppSettingsController.instance.setScaleMode(e ?? 0);
              controller.updateScaleMode();
            },
            child: Column(
              children: [
                RadioListTile(
                  value: 0,
                  contentPadding: AppStyle.edgeInsetsH4,
                  title: const Text("适应"),
                  visualDensity: VisualDensity.compact,
                ),
                RadioListTile(
                  value: 1,
                  contentPadding: AppStyle.edgeInsetsH4,
                  title: const Text("拉伸"),
                  visualDensity: VisualDensity.compact,
                ),
                RadioListTile(
                  value: 2,
                  contentPadding: AppStyle.edgeInsetsH4,
                  title: const Text("铺满"),
                  visualDensity: VisualDensity.compact,
                ),
                RadioListTile(
                  value: 3,
                  contentPadding: AppStyle.edgeInsetsH4,
                  title: const Text("16:9"),
                  visualDensity: VisualDensity.compact,
                ),
                RadioListTile(
                  value: 4,
                  contentPadding: AppStyle.edgeInsetsH4,
                  title: const Text("4:3"),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void showFollowUser(LiveRoomController controller) {
  if (controller.isVertical.value) {
    controller.showFollowUserSheet();
    return;
  }

  Utils.showRightDialog(
    title: "关注列表",
    width: 400,
    useSystem: true,
    child: Obx(
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
                    playing: controller.rxSite.value.id == item.siteId &&
                        controller.rxRoomId.value == item.roomId,
                    onTap: () {
                      Utils.hideRightDialog();
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
    ),
  );
}
