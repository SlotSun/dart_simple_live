import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/app/utils/setting_gen_util.dart';
import 'package:simple_live_app/models/db/follow_snapshot.dart';
import 'package:simple_live_app/services/local_storage_service.dart';

part 'app_settings_controller.g.dart';

class AppSettingsController extends GetxController {
  static AppSettingsController get instance => Get.find<AppSettingsController>();

  /// 缩放模式
  @SettingItem(defaultValue: 0, key: LocalStorageService.kPlayerScaleMode)
  var scaleMode = 0.obs;

  @SettingItem(defaultValue: 16 / 9, key: LocalStorageService.kPlayerAspectByUser)
  var aspectByUser = (16 / 9).obs;

  @SettingItem(defaultValue: 16, key: LocalStorageService.kPlayerAspectWidth)
  var aspectWidth = 16.obs;

  @SettingItem(defaultValue: 9, key: LocalStorageService.kPlayerAspectHeight)
  var aspectHeight = 9.obs;

  @SettingItem(defaultValue: 0, key: LocalStorageService.kThemeMode)
  var themeMode = 0.obs;

  var firstRun = false;

  var dbVer = 0;

  var dbPath = "";

  @override
  Future<void> onInit() async {
    getThemeMode();
    firstRun = LocalStorageService.instance.getValue(LocalStorageService.kFirstRun, true);
    getDanmuSize();
    getDanmuOpacity();
    getDanmuArea();
    getDanmuSpeed();
    getDanmuEnable();
    getDanmakuMaskEnable();
    getDanmuEmoticonEnable();
    getDanmuStrokeWidth();
    getDanmuTopMargin();
    getDanmuBottomMargin();
    danmuFontWeight.value = LocalStorageService.instance.getValue(
        LocalStorageService.kDanmuFontWeight,
        // ignore: deprecated_member_use
        FontWeight.normal.index);
    // limit of canvas_danmaku interface, there is bug if change index to value
    // and now, value was set 0..8, the value needs ..=FontWeight[index] after
    // migration, so marked it, next migration depends on canvas_danmaku upgrade
    getDanmakuFontClamped();
    getDanmakuFontClampUpSens();
    getDanmakuFontClampDownSens();

    getHardwareDecode();
    getChatTextSize();

    getChatTextGap();

    getChatBubbleStyle();

    getQualityLevel();
    getQualityLevelCellular();

    getAutoExitEnable();

    getAutoExitDuration();

    getRoomAutoExitDuration();

    getPlayerCompatMode();

    getPlayerAutoPause();

    getPlayerForceHttps();

    getDouyinHlsFirst();

    getAutoFullScreen();

    getVerticalDragLock();

    // ignore: invalid_use_of_protected_member
    shieldList.value = LocalStorageService.instance.shieldBox.values.toSet();

    getScaleMode();

    getAspectByUser();

    getAspectWidth();

    getAspectHeight();

    getPlayerVolume();
    getPipHideDanmu();

    getWindowMaxAuto();
    getWindowMaxState();

    getWindowPipX();
    getWindowPipY();
    getWindowPipWidth();
    getWindowPipHeight();

    getBilibiliLoginTip();

    getPlayerBufferSize();

    getLogEnable();
    if (logEnable.value) {
      Log.initWriter();
    }

    getFirebaseEnable();

    getCustomPlayerOutput();

    videoOutputDriver.value = LocalStorageService.instance.getValue(
      LocalStorageService.kVideoOutputDriver,
      Platform.isAndroid ? "mediacodec_embed" : "libmpv",
    );

    volumeNorm.value = LocalStorageService.instance.getValue(
      LocalStorageService.kVolumeNorm,
      false,
    );

    audioOutputDriver.value = LocalStorageService.instance.getValue(
      LocalStorageService.kAudioOutputDriver,
      Platform.isAndroid
          ? "audiotrack"
          : Platform.isLinux
              ? "pulse"
              : Platform.isWindows
                  ? "wasapi"
                  : Platform.isIOS
                      ? "audiounit"
                      : Platform.isMacOS
                          ? "coreaudio"
                          : "sdl",
    );

    videoHardwareDecoder.value = LocalStorageService.instance.getValue(
      LocalStorageService.kVideoHardwareDecoder,
      Platform.isAndroid ? "mediacodec" : "auto",
    );

    getVideoDoubleBuffering();

    getEnableRtxVsr();

    getAutoUpdateFollowEnable();

    getAutoUpdateFollowDuration();

    getUpdateFollowThreadCount();

    getFollowSnapshotEnable();

    getDormancyThreshold();

    // danmaku-去重参数
    getDanmuFrequencyControl();

    getDanmuMaxFrequency();

    getDanmuTextNormalization();

    getDanmuWindowMs();
    dbVer = LocalStorageService.instance.getValue(LocalStorageService.kHiveDbVer, 10708);

    followSortMethod.value = SortMethodStore.fromStore(LocalStorageService.instance
        .getValue(LocalStorageService.kFollowSortMethod, SortMethod.watchDuration.storeValue));

    getFollowStyleNotGrid();

    getHideOfflineFollow();

    getHideRemoveFollowButton();

    followSnapshot = LocalStorageService.instance.getNullValue(LocalStorageService.kFollowSnapshot, null);

    initSiteSort();
    initHomeSort();
    await initDataPath();

    super.onInit();
  }

  Future<void> initDataPath() async {
    dbPath = (await getApplicationSupportDirectory()).path;
    if (!Platform.isAndroid && !Platform.isIOS) {
      // linux 应该有问题，但我不熟悉，先这么写
      var pathPortable = p.join(p.dirname(Platform.resolvedExecutable), 'data_hive_ce');
      bool dirPortableExist = await Directory(pathPortable).exists();
      if (dirPortableExist) {
        dbPath = pathPortable;
      }
    }
  }

  void initSiteSort() {
    var sort = LocalStorageService.instance
        .getValue(
          LocalStorageService.kSiteSort,
          Sites.allSites.keys.join(","),
        )
        .split(",");
    //如果数量与allSites的数量不一致，将缺失的添加上
    if (sort.length != Sites.allSites.length) {
      var keys = Sites.allSites.keys.toList();
      for (var i = 0; i < keys.length; i++) {
        if (!sort.contains(keys[i])) {
          sort.add(keys[i]);
        }
      }
    }

    siteSort.value = sort;
  }

  void initHomeSort() {
    var sort = LocalStorageService.instance
        .getValue(
          LocalStorageService.kHomeSort,
          Constant.allHomePages.keys.join(","),
        )
        .split(",");
    //如果数量与allSites的数量不一致，将缺失的添加上
    if (sort.length != Constant.allHomePages.length) {
      var keys = Constant.allHomePages.keys.toList();
      for (var i = 0; i < keys.length; i++) {
        if (!sort.contains(keys[i])) {
          sort.add(keys[i]);
        }
      }
    }

    homeSort.value = sort;
  }

  void setNoFirstRun() {
    LocalStorageService.instance.setValue(LocalStorageService.kFirstRun, false);
  }

  @SettingItem(defaultValue: true, key: LocalStorageService.kHardwareDecode)
  var hardwareDecode = true.obs;

  @SettingItem(defaultValue: 14.0, key: LocalStorageService.kChatTextSize)
  var chatTextSize = 14.0.obs;

  @SettingItem(defaultValue: 4.0, key: LocalStorageService.kChatTextGap)
  var chatTextGap = 4.0.obs;

  @SettingItem(defaultValue: false, key: LocalStorageService.kChatBubbleStyle)
  var chatBubbleStyle = false.obs;

  @SettingItem(defaultValue: 16.0, key: LocalStorageService.kDanmuSize)
  var danmuSize = 16.0.obs;

  @SettingItem(defaultValue: 10.0, key: LocalStorageService.kDanmuSpeed)
  var danmuSpeed = 10.0.obs;

  @SettingItem(defaultValue: 0.8, key: LocalStorageService.kDanmuArea)
  var danmuArea = 0.8.obs;

  @SettingItem(defaultValue: 1.0, key: LocalStorageService.kDanmuOpacity)
  var danmuOpacity = 1.0.obs;

  @SettingItem(defaultValue: true, key: LocalStorageService.kDanmuEnable)
  var danmuEnable = true.obs;

  @SettingItem(defaultValue: false, key: LocalStorageService.kDanmakuMaskEnable)
  var danmakuMaskEnable = false.obs;

  /// 弹幕表情包：把 B 站下发的表情渲染成图片。
  /// 关闭后仍然是原来的占位符文本，只是不再下载与合成图片。
  @SettingItem(defaultValue: true, key: LocalStorageService.kDanmuEmoticonEnable)
  var danmuEmoticonEnable = true.obs;

  @SettingItem(defaultValue: 2.0, key: LocalStorageService.kDanmuStrokeWidth)
  var danmuStrokeWidth = 2.0.obs;

  // ignore: deprecated_member_use
  var danmuFontWeight = FontWeight.normal.index.obs;

  void setDanmuFontWeight(int e) {
    danmuFontWeight.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kDanmuFontWeight, e);
  }

  @SettingItem(defaultValue: false, key: LocalStorageService.kDanmakuFontClamped)
  var danmakuFontClamped = false.obs;

  var danmakuFontResize = 16.0;

  @SettingItem(defaultValue: 9.0, key: LocalStorageService.kDanmakuFontClampUpSens)
  var danmakuFontClampUpSens = 9.0.obs;

  @SettingItem(defaultValue: 5.0, key: LocalStorageService.kDanmakuFontClampDownSens)
  var danmakuFontClampDownSens = 5.0.obs;

  @SettingItem(defaultValue: 2, key: LocalStorageService.kQualityLevel)
  var qualityLevel = 1.obs;

  @SettingItem(defaultValue: 1, key: LocalStorageService.kQualityLevelCellular)
  var qualityLevelCellular = 1.obs;

  @SettingItem(defaultValue: false, key: LocalStorageService.kAutoExitEnable)
  var autoExitEnable = false.obs;

  @SettingItem(defaultValue: 60, key: LocalStorageService.kAutoExitDuration)
  var autoExitDuration = 60.obs;

  @SettingItem(defaultValue: 60, key: LocalStorageService.kRoomAutoExitDuration)
  var roomAutoExitDuration = 60.obs;

  @SettingItem(defaultValue: false, key: LocalStorageService.kPlayerCompatMode)
  var playerCompatMode = false.obs;

  @SettingItem(defaultValue: 32, key: LocalStorageService.kPlayerBufferSize)
  var playerBufferSize = 32.obs;

  @SettingItem(defaultValue: false, key: LocalStorageService.kPlayerAutoPause)
  var playerAutoPause = false.obs;

  @SettingItem(defaultValue: false, key: LocalStorageService.kAutoFullScreen)
  var autoFullScreen = false.obs;

  // 滑动调节亮度/音量上下滑动手势控制
  @SettingItem(defaultValue: false, key: LocalStorageService.kVerticalDragLock)
  var verticalDragLock = false.obs;

  RxSet<String> shieldList = <String>{}.obs;

  void addShieldList(String e) {
    shieldList.add(e);
    LocalStorageService.instance.shieldBox.put(e, e);
  }

  void removeShieldList(String e) {
    shieldList.remove(e);
    LocalStorageService.instance.shieldBox.delete(e);
  }

  Future clearShieldList() async {
    shieldList.clear();
    await LocalStorageService.instance.shieldBox.clear();
  }

  RxList<String> siteSort = RxList<String>();

  void setSiteSort(List<String> e) {
    siteSort.value = e;
    LocalStorageService.instance.setValue(
      LocalStorageService.kSiteSort,
      siteSort.join(","),
    );
  }

  RxList<String> homeSort = RxList<String>();

  void setHomeSort(List<String> e) {
    homeSort.value = e;
    LocalStorageService.instance.setValue(
      LocalStorageService.kHomeSort,
      homeSort.join(","),
    );
  }

  @SettingItem(defaultValue: 100.0, key: LocalStorageService.kPlayerVolume)
  Rx<double> playerVolume = 100.0.obs;

  @SettingItem(defaultValue: true, key: LocalStorageService.kPIPHideDanmu)
  var pipHideDanmu = true.obs;

  /// window Setting
  // 开屏自动最大化
  @SettingItem(defaultValue: false, key: LocalStorageService.kWindowMaxAuto)
  var windowMaxAuto = false.obs;

  @SettingItem(defaultValue: false, key: LocalStorageService.kWindowMaxState)
  var windowMaxState = false.obs;

  /// window小窗size
  @SettingItem(defaultValue: 0.0, key: LocalStorageService.kWindowPipX)
  var windowPipX = 0.0.obs;

  @SettingItem(defaultValue: 0.0, key: LocalStorageService.kWindowPipY)
  var windowPipY = 0.0.obs;

  @SettingItem(defaultValue: 400.0, key: LocalStorageService.kWindowPipWidth)
  var windowPipWidth = 320.0.obs;

  @SettingItem(defaultValue: 225.0, key: LocalStorageService.kWindowPipHeight)
  var windowPipHeight = 180.0.obs;

  @SettingItem(defaultValue: 0.0, key: LocalStorageService.kDanmuTopMargin)
  var danmuTopMargin = 0.0.obs;

  @SettingItem(defaultValue: 0.0, key: LocalStorageService.kDanmuBottomMargin)
  var danmuBottomMargin = 0.0.obs;

  /// 弹幕去重参数设置
  @SettingItem(defaultValue: true, key: LocalStorageService.kDanmuTextNormalization)
  var danmuTextNormalization = true.obs;

  @SettingItem(defaultValue: 3, key: LocalStorageService.kDanmuMaxFrequency)
  var danmuMaxFrequency = 3.obs;

  @SettingItem(defaultValue: false, key: LocalStorageService.kDanmuFrequencyControl)
  var danmuFrequencyControl = true.obs;

  @SettingItem(defaultValue: 15, key: LocalStorageService.kDanmuWindowMs)
  var danmuWindowMs = 15.obs;

  @SettingItem(defaultValue: true, key: LocalStorageService.kBilibiliLoginTip)
  var bilibiliLoginTip = true.obs;

  @SettingItem(defaultValue: false, key: LocalStorageService.kLogEnable)
  var logEnable = false.obs;

  @SettingItem(defaultValue: true, key: LocalStorageService.kFirebaseEnable)
  var firebaseEnable = true.obs;

  @SettingItem(defaultValue: false, key: LocalStorageService.kCustomPlayerOutput)
  var customPlayerOutput = false.obs;

  var videoOutputDriver = "".obs;

  void setVideoOutputDriver(String e) {
    videoOutputDriver.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kVideoOutputDriver, e);
  }

  /// 音量均衡（自动抬升小音量/压低大音量，mpv dynaudnorm 滤镜；播放器侧 ever 监听热切换）
  var volumeNorm = false.obs;

  void setVolumeNorm(bool e) {
    volumeNorm.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kVolumeNorm, e);
  }

  var audioOutputDriver = "".obs;

  void setAudioOutputDriver(String e) {
    audioOutputDriver.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kAudioOutputDriver, e);
  }

  var videoHardwareDecoder = "".obs;

  void setVideoHardwareDecoder(String e) {
    videoHardwareDecoder.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kVideoHardwareDecoder, e);
  }

  @SettingItem(defaultValue: false, key: LocalStorageService.kVideoDoubleBuffering)
  var videoDoubleBuffering = false.obs;

  @SettingItem(defaultValue: false, key: LocalStorageService.kEnableRtxVsr)
  var enableRtxVsr = false.obs;

  @SettingItem(defaultValue: true, key: LocalStorageService.kAutoUpdateFollowEnable)
  var autoUpdateFollowEnable = false.obs;

  @SettingItem(defaultValue: 10, key: LocalStorageService.kUpdateFollowDuration)
  var autoUpdateFollowDuration = 10.obs;

  @SettingItem(defaultValue: 4, key: LocalStorageService.kUpdateFollowThreadCount)
  var updateFollowThreadCount = 4.obs;

  @SettingItem(defaultValue: false, key: LocalStorageService.kFollowSnapshotEnable)
  var followSnapshotEnable = false.obs;

  @SettingItem(defaultValue: 0, key: LocalStorageService.kDormancyThreshold)
  var dormancyThreshold = 0.obs;

  @SettingItem(defaultValue: false, key: LocalStorageService.kPlayerForceHttps)
  var playerForceHttps = false.obs;

  @SettingItem(defaultValue: false, key: LocalStorageService.kDouyinHlsFirst)
  var douyinHlsFirst = false.obs;

  var followSortMethod = SortMethod.watchDuration.obs;

  void setFollowSortMethod(SortMethod e) {
    followSortMethod.value = e;
    LocalStorageService.instance.setValue(LocalStorageService.kFollowSortMethod, e.storeValue);
  }

  // 关注样式是否卡片化
  @SettingItem(defaultValue: true, key: LocalStorageService.kFollowStyleNotGrid)
  var followStyleNotGrid = true.obs;

  // 隐藏不在线的关注
  @SettingItem(defaultValue: false, key: LocalStorageService.kHideOfflineFollow)
  var hideOfflineFollow = false.obs;

  // 隐藏隐藏快速取关按钮
  @SettingItem(defaultValue: true, key: LocalStorageService.kHideRemoveFollow)
  var hideRemoveFollowButton = true.obs;

  /// 保存关注列表快照
  FollowSnapshot? followSnapshot;

  Future setFollowSnapshot(FollowSnapshot followSnapshot) {
    return LocalStorageService.instance.setValue(LocalStorageService.kFollowSnapshot, followSnapshot);
  }
}
