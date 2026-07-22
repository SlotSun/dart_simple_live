import 'dart:io';

import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/live_room/live_room_controller.dart';
import 'package:simple_live_app/modules/live_room/player/player_controls.dart';
import 'package:simple_live_app/services/follow_service.dart';
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
          return _buildLoadErrorPage(context);
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

  Widget _buildLoadErrorPage(BuildContext context) {
    final semantic = context.appTheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("直播间加载失败"),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppStyle.edgeInsetsA16,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: semantic.elevatedSurface,
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radius16),
                  border: Border.all(color: semantic.border),
                  boxShadow: [
                    BoxShadow(
                      color: semantic.shadow,
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: AppStyle.edgeInsetsA24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExcludeSemantics(
                        child: LottieBuilder.asset(
                          'assets/lotties/error.json',
                          height: 120,
                          repeat: false,
                          animate: !MediaQuery.of(context).disableAnimations,
                        ),
                      ),
                      AppStyle.vGap12,
                      Text(
                        "直播间加载失败",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: semantic.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AppStyle.vGap8,
                      Text(
                        controller.error?.toString() ?? "未知错误",
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: semantic.textSecondary,
                        ),
                      ),
                      AppStyle.vGap12,
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDesignTokens.space12,
                            vertical: AppDesignTokens.space8,
                          ),
                          decoration: BoxDecoration(
                            color: semantic.secondarySurface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: semantic.border),
                          ),
                          child: Text(
                            "${controller.rxSite.value.id} - ${controller.rxRoomId.value}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: semantic.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      AppStyle.vGap16,
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppDesignTokens.space8,
                        runSpacing: AppDesignTokens.space8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: controller.copyErrorDetail,
                            icon: const Icon(Remix.file_copy_line, size: 18),
                            label: const Text("复制信息"),
                          ),
                          FilledButton.icon(
                            onPressed: controller.refreshRoom,
                            icon: const Icon(Remix.refresh_line, size: 18),
                            label: const Text("刷新"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPageUI() {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          appBar: AppBar(
            title: Obx(
              () => Text(
                controller.detail.value?.title ?? "直播间",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            actions: buildAppbarActions(context),
          ),
          body: orientation == Orientation.portrait
              ? buildPhoneUI(context)
              : buildTabletUI(context),
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

  Widget buildTabletUI(BuildContext context) {
    final semantic = context.appTheme;
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: buildMediaPlayer(),
              ),
              Flexible(
                flex: 2,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
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
        SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: semantic.elevatedSurface,
              border: Border(
                top: BorderSide(color: semantic.border),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignTokens.space12,
              vertical: AppDesignTokens.space8,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildBottomAction(
                    context,
                    onPressed: controller.refreshRoom,
                    icon: Remix.refresh_line,
                    label: "刷新",
                  ),
                  AppStyle.hGap8,
                  Obx(
                    () => _buildBottomAction(
                      context,
                      onPressed: controller.followed.value
                          ? controller.removeFollowUser
                          : controller.followUser,
                      icon: controller.followed.value
                          ? Remix.heart_fill
                          : Remix.heart_line,
                      label: controller.followed.value ? "取消关注" : "关注",
                      emphasized: !controller.followed.value,
                    ),
                  ),
                  AppStyle.hGap24,
                  _buildBottomAction(
                    context,
                    onPressed: controller.share,
                    icon: Remix.share_line,
                    label: "分享",
                  ),
                  AppStyle.hGap8,
                  (Platform.isWindows || Platform.isLinux)
                      ? _buildBottomAction(
                          context,
                          onPressed: controller.visitWebLive,
                          icon: Remix.chrome_fill,
                          label: "浏览器打开",
                        )
                      : _buildBottomAction(
                          context,
                          onPressed: controller.copyUrl,
                          icon: Remix.file_copy_line,
                          label: "复制链接",
                        ),
                ],
              ),
            ),
          ),
        ),
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
    }
    return Stack(
      children: [
        Video(
          key: controller.globalPlayerKey,
          controller: controller.videoController,
          pauseUponEnteringBackgroundMode:
              AppSettingsController.instance.playerAutoPause.value,
          resumeUponEnteringForegroundMode:
              AppSettingsController.instance.playerAutoPause.value,
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
    final semantic = context.appTheme;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesignTokens.space12,
        AppDesignTokens.space12,
        AppDesignTokens.space12,
        AppDesignTokens.space8,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: semantic.elevatedSurface,
          borderRadius: BorderRadius.circular(AppDesignTokens.radius16),
          border: Border.all(color: semantic.border),
          boxShadow: [
            BoxShadow(
              color: semantic.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: AppStyle.edgeInsetsA12,
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: semantic.border),
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
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: semantic.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AppStyle.vGap4,
                      Row(
                        children: [
                          Image.asset(
                            controller.site.logo,
                            width: 18,
                            height: 18,
                          ),
                          AppStyle.hGap4,
                          Flexible(
                            child: Text(
                              controller.site.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: semantic.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppStyle.hGap8,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignTokens.space8,
                    vertical: AppDesignTokens.space4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: theme.colorScheme.primary.withAlpha(44),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Remix.fire_fill,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      AppStyle.hGap4,
                      Text(
                        Utils.onlineToString(
                          controller.detail.value?.online ?? 0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: semantic.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBottomActions(BuildContext context) {
    final semantic = context.appTheme;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: semantic.elevatedSurface,
          border: Border(
            top: BorderSide(color: semantic.border),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.space12,
          vertical: AppDesignTokens.space8,
        ),
        child: Row(
          children: [
            Expanded(
              child: Obx(
                () => _buildBottomAction(
                  context,
                  onPressed: controller.followed.value
                      ? controller.removeFollowUser
                      : controller.followUser,
                  icon: controller.followed.value
                      ? Remix.heart_fill
                      : Remix.heart_line,
                  label: controller.followed.value ? "取消关注" : "关注",
                  emphasized: !controller.followed.value,
                ),
              ),
            ),
            AppStyle.hGap8,
            Expanded(
              child: _buildBottomAction(
                context,
                onPressed: controller.refreshRoom,
                icon: Remix.refresh_line,
                label: "刷新",
              ),
            ),
            AppStyle.hGap8,
            Expanded(
              child: _buildBottomAction(
                context,
                onPressed: controller.share,
                icon: Remix.share_line,
                label: "分享",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMessageArea() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDesignTokens.space12,
          0,
          AppDesignTokens.space12,
          AppDesignTokens.space8,
        ),
        child: Builder(
          builder: (context) {
            final semantic = context.appTheme;
            final theme = Theme.of(context);
            return Material(
              color: semantic.elevatedSurface,
              surfaceTintColor: Colors.transparent,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesignTokens.radius16),
                side: BorderSide(color: semantic.border),
              ),
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    Container(
                      color: semantic.secondarySurface,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelPadding: EdgeInsets.zero,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(
                            AppDesignTokens.radius12,
                          ),
                        ),
                        labelColor: theme.colorScheme.onPrimaryContainer,
                        unselectedLabelColor: semantic.textSecondary,
                        tabs: [
                          const Tab(text: "聊天"),
                          Tab(
                            child: Obx(
                              () => Text(
                                controller.superChats.isNotEmpty
                                    ? "SC(${controller.superChats.length})"
                                    : "SC",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const Tab(text: "关注"),
                          const Tab(text: "设置"),
                        ],
                      ),
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
                                      height: AppSettingsController
                                              .instance.chatTextGap.value *
                                          2,
                                    ),
                                  ),
                                  padding: AppStyle.edgeInsetsA12,
                                  itemCount: controller.messages.length,
                                  itemBuilder: (context, i) {
                                    var item = controller.messages[i];
                                    return buildMessageItem(context, item);
                                  },
                                ),
                                if (controller.disableAutoScroll.value)
                                  Positioned(
                                    right: 12,
                                    bottom: 12,
                                    child: FilledButton.tonalIcon(
                                      onPressed: () {
                                        controller.disableAutoScroll.value = false;
                                        controller.chatScrollToBottom();
                                      },
                                      icon: const Icon(Icons.expand_more),
                                      label: const Text("最新"),
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
          },
        ),
      ),
    );
  }

  Widget buildMessageItem(BuildContext context, LiveMessage message) {
    final semantic = context.appTheme;
    final theme = Theme.of(context);

    if (message.userName == "LiveSysMessage") {
      return Obx(
        () => Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignTokens.space12,
              vertical: AppDesignTokens.space8,
            ),
            decoration: BoxDecoration(
              color: semantic.secondarySurface,
              borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
              border: Border.all(color: semantic.border),
            ),
            child: SelectableText(
              message.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: semantic.textTertiary,
                fontSize: AppSettingsController.instance.chatTextSize.value,
              ),
            ),
          ),
        ),
      );
    }

    return Obx(
      () {
        final userStyle = theme.textTheme.bodyMedium?.copyWith(
          color: semantic.textSecondary,
          fontSize: AppSettingsController.instance.chatTextSize.value,
          fontWeight: FontWeight.w600,
        );
        final messageStyle = theme.textTheme.bodyMedium?.copyWith(
          color: semantic.textPrimary,
          fontSize: AppSettingsController.instance.chatTextSize.value,
        );

        if (AppSettingsController.instance.chatBubbleStyle.value) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(16),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(AppDesignTokens.radius12),
                      bottomLeft: Radius.circular(AppDesignTokens.radius12),
                      bottomRight: Radius.circular(AppDesignTokens.radius12),
                    ),
                    border: Border.all(
                      color: theme.colorScheme.primary.withAlpha(34),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignTokens.space12,
                    vertical: AppDesignTokens.space8,
                  ),
                  child: SelectableText.rich(
                    TextSpan(
                      text: "${message.userName}：",
                      style: userStyle,
                      children: [
                        TextSpan(
                          text: message.message,
                          style: messageStyle,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return SelectableText.rich(
          TextSpan(
            text: "${message.userName}：",
            style: userStyle,
            children: [
              TextSpan(
                text: message.message,
                style: messageStyle,
              )
            ],
          ),
        );
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
    return Builder(
      builder: (context) {
        final semantic = context.appTheme;
        final theme = Theme.of(context);
        return ListView(
          padding: AppStyle.edgeInsetsA12,
          children: [
            Obx(
              () => Visibility(
                visible: controller.autoExitEnable.value,
                child: Padding(
                  padding: AppStyle.edgeInsetsB12,
                  child: SettingsCard(
                    child: ListTile(
                      leading: Icon(
                        Icons.timer_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        "${parseDuration(controller.countdown.value)}后自动关闭",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildSectionHeader(context, "聊天区"),
            SettingsCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(
                    () => SettingsNumber(
                      title: "文字大小",
                      value: AppSettingsController.instance.chatTextSize.value
                          .toInt(),
                      min: 8,
                      max: 36,
                      onChanged: (e) {
                        AppSettingsController.instance
                            .setChatTextSize(e.toDouble());
                      },
                    ),
                  ),
                  AppStyle.divider,
                  Obx(
                    () => SettingsNumber(
                      title: "上下间隔",
                      value: AppSettingsController.instance.chatTextGap.value
                          .toInt(),
                      min: 0,
                      max: 12,
                      onChanged: (e) {
                        AppSettingsController.instance
                            .setChatTextGap(e.toDouble());
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
            AppStyle.vGap12,
            _buildSectionHeader(context, "更多设置"),
            SettingsCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SettingsAction(
                    title: "关键词屏蔽",
                    onTap: controller.showDanmuShield,
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
                ],
              ),
            ),
            AppStyle.vGap12,
            Text(
              "直播设置会立即生效",
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: semantic.textTertiary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildFollowList() {
    return Obx(
      () => Stack(
        children: [
          RefreshIndicator(
            onRefresh: FollowService.instance.loadData,
            child: ListView.builder(
              padding: AppStyle.edgeInsetsV8,
              itemCount: FollowService.instance.liveList.length,
              itemBuilder: (_, i) {
                var item = FollowService.instance.liveList[i];
                return Obx(
                  () => FollowUserItem(
                    item: item,
                    playing: controller.rxSite.value.id == item.siteId &&
                        controller.rxRoomId.value == item.roomId,
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
      Padding(
        padding: AppStyle.edgeInsetsR8,
        child: IconButton.filledTonal(
          tooltip: "更多",
          onPressed: () {
            showMore();
          },
          icon: const Icon(Icons.more_horiz),
        ),
      ),
    ];
  }

  void showMore() {
    showModalBottomSheet(
      context: Get.context!,
      constraints: const BoxConstraints(
        maxWidth: 600,
      ),
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppDesignTokens.space12,
            right: AppDesignTokens.space12,
            bottom: AppStyle.bottomBarHeight + AppDesignTokens.space12,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildMoreTile(
                context,
                icon: Icons.refresh,
                title: "刷新",
                onTap: () {
                  controller.refreshRoom();
                },
              ),
              _buildMoreTile(
                context,
                icon: Icons.play_circle_outline,
                title: "切换清晰度",
                onTap: () {
                  Get.back();
                  controller.showQualitySheet();
                },
              ),
              _buildMoreTile(
                context,
                icon: Icons.switch_video_outlined,
                title: "切换线路",
                onTap: () {
                  Get.back();
                  controller.showPlayUrlsSheet();
                },
              ),
              _buildMoreTile(
                context,
                icon: Icons.aspect_ratio_outlined,
                title: "画面尺寸",
                onTap: () {
                  Get.back();
                  controller.showPlayerSettingsSheet();
                },
              ),
              _buildMoreTile(
                context,
                icon: Icons.camera_alt_outlined,
                title: "截图",
                onTap: () {
                  controller.saveScreenshot();
                },
              ),
              Visibility(
                visible: Platform.isAndroid,
                child: _buildMoreTile(
                  context,
                  icon: Icons.picture_in_picture,
                  title: "小窗播放",
                  onTap: () {
                    Get.back();
                    controller.enablePIP();
                  },
                ),
              ),
              _buildMoreTile(
                context,
                icon: Icons.timer_outlined,
                title: "定时关闭",
                onTap: () {
                  Get.back();
                  controller.showAutoExitSheet();
                },
              ),
              _buildMoreTile(
                context,
                icon: Icons.share_sharp,
                title: "分享直播间",
                onTap: () {
                  Get.back();
                  controller.share();
                },
              ),
              _buildMoreTile(
                context,
                icon: Icons.copy,
                title: "复制链接",
                onTap: () {
                  Get.back();
                  controller.copyUrl();
                },
              ),
              _buildMoreTile(
                context,
                icon: Icons.open_in_new,
                title: "APP 中打开",
                onTap: () {
                  Get.back();
                  controller.openNaviteAPP();
                },
              ),
              _buildMoreTile(
                context,
                icon: Icons.info_outline_rounded,
                title: "播放信息",
                onTap: () {
                  Get.back();
                  controller.showDebugInfo();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(
    BuildContext context, {
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    bool emphasized = false,
  }) {
    final semantic = context.appTheme;
    final theme = Theme.of(context);
    final foreground = emphasized
        ? theme.colorScheme.onPrimaryContainer
        : semantic.textPrimary;

    return TextButton.icon(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.space12,
          vertical: AppDesignTokens.space8,
        ),
        foregroundColor: foreground,
        backgroundColor: emphasized
            ? theme.colorScheme.primaryContainer
            : semantic.secondarySurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
          side: BorderSide(
            color: emphasized
                ? theme.colorScheme.primary.withAlpha(44)
                : semantic.border,
          ),
        ),
        textStyle: theme.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final semantic = context.appTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: semantic.textSecondary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _buildMoreTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final semantic = context.appTheme;
    final theme = Theme.of(context);

    return Padding(
      padding: AppStyle.edgeInsetsV4,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.space12,
          vertical: 2,
        ),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: semantic.secondarySurface,
            borderRadius: BorderRadius.circular(AppDesignTokens.radius10),
            border: Border.all(color: semantic.border),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: semantic.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: semantic.textTertiary,
        ),
        onTap: onTap,
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
