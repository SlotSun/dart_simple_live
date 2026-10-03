// GENERATED CODE - DO NOT MODIFY BY HAND
part of "app_settings_controller.dart";

extension AppSettingsControllerSettingGen on AppSettingsController {
  void setScaleMode(int e) {
    scaleMode.value = e;
    LocalStorageService.instance.setValue(kScaleMode, e);
  }

  void getScaleMode() {
    scaleMode.value = LocalStorageService.instance.getValue(kScaleMode, 0);
  }

  void setAspectByUser(double e) {
    aspectByUser.value = e;
    LocalStorageService.instance.setValue(kAspectByUser, e);
  }

  void getAspectByUser() {
    aspectByUser.value = LocalStorageService.instance.getValue(kAspectByUser, 16 / 9);
  }

  void setAspectWidth(int e) {
    aspectWidth.value = e;
    LocalStorageService.instance.setValue(kAspectWidth, e);
  }

  void getAspectWidth() {
    aspectWidth.value = LocalStorageService.instance.getValue(kAspectWidth, 16);
  }

  void setAspectHeight(int e) {
    aspectHeight.value = e;
    LocalStorageService.instance.setValue(kAspectHeight, e);
  }

  void getAspectHeight() {
    aspectHeight.value = LocalStorageService.instance.getValue(kAspectHeight, 9);
  }

  void setThemeMode(int e) {
    themeMode.value = e;
    LocalStorageService.instance.setValue(kThemeMode, e);
  }

  void getThemeMode() {
    themeMode.value = LocalStorageService.instance.getValue(kThemeMode, 0);
  }

  void setHardwareDecode(bool e) {
    hardwareDecode.value = e;
    LocalStorageService.instance.setValue(kHardwareDecode, e);
  }

  void getHardwareDecode() {
    hardwareDecode.value = LocalStorageService.instance.getValue(kHardwareDecode, true);
  }

  void setChatTextSize(double e) {
    chatTextSize.value = e;
    LocalStorageService.instance.setValue(kChatTextSize, e);
  }

  void getChatTextSize() {
    chatTextSize.value = LocalStorageService.instance.getValue(kChatTextSize, 14.0);
  }

  void setChatTextGap(double e) {
    chatTextGap.value = e;
    LocalStorageService.instance.setValue(kChatTextGap, e);
  }

  void getChatTextGap() {
    chatTextGap.value = LocalStorageService.instance.getValue(kChatTextGap, 4.0);
  }

  void setChatBubbleStyle(bool e) {
    chatBubbleStyle.value = e;
    LocalStorageService.instance.setValue(kChatBubbleStyle, e);
  }

  void getChatBubbleStyle() {
    chatBubbleStyle.value = LocalStorageService.instance.getValue(kChatBubbleStyle, false);
  }

  void setDanmuSize(double e) {
    danmuSize.value = e;
    LocalStorageService.instance.setValue(kDanmuSize, e);
  }

  void getDanmuSize() {
    danmuSize.value = LocalStorageService.instance.getValue(kDanmuSize, 16.0);
  }

  void setDanmuSpeed(double e) {
    danmuSpeed.value = e;
    LocalStorageService.instance.setValue(kDanmuSpeed, e);
  }

  void getDanmuSpeed() {
    danmuSpeed.value = LocalStorageService.instance.getValue(kDanmuSpeed, 10.0);
  }

  void setDanmuArea(double e) {
    danmuArea.value = e;
    LocalStorageService.instance.setValue(kDanmuArea, e);
  }

  void getDanmuArea() {
    danmuArea.value = LocalStorageService.instance.getValue(kDanmuArea, 0.8);
  }

  void setDanmuOpacity(double e) {
    danmuOpacity.value = e;
    LocalStorageService.instance.setValue(kDanmuOpacity, e);
  }

  void getDanmuOpacity() {
    danmuOpacity.value = LocalStorageService.instance.getValue(kDanmuOpacity, 1.0);
  }

  void setDanmuEnable(bool e) {
    danmuEnable.value = e;
    LocalStorageService.instance.setValue(kDanmuEnable, e);
  }

  void getDanmuEnable() {
    danmuEnable.value = LocalStorageService.instance.getValue(kDanmuEnable, true);
  }

  void setDanmakuMaskEnable(bool e) {
    danmakuMaskEnable.value = e;
    LocalStorageService.instance.setValue(kDanmakuMaskEnable, e);
  }

  void getDanmakuMaskEnable() {
    danmakuMaskEnable.value = LocalStorageService.instance.getValue(kDanmakuMaskEnable, false);
  }

  void setDanmuEmoticonEnable(bool e) {
    danmuEmoticonEnable.value = e;
    LocalStorageService.instance.setValue(kDanmuEmoticonEnable, e);
  }

  void getDanmuEmoticonEnable() {
    danmuEmoticonEnable.value = LocalStorageService.instance.getValue(kDanmuEmoticonEnable, true);
  }

  void setDanmuStrokeWidth(double e) {
    danmuStrokeWidth.value = e;
    LocalStorageService.instance.setValue(kDanmuStrokeWidth, e);
  }

  void getDanmuStrokeWidth() {
    danmuStrokeWidth.value = LocalStorageService.instance.getValue(kDanmuStrokeWidth, 2.0);
  }

  void setDanmakuFontClamped(bool e) {
    danmakuFontClamped.value = e;
    LocalStorageService.instance.setValue(kDanmakuFontClamped, e);
  }

  void getDanmakuFontClamped() {
    danmakuFontClamped.value = LocalStorageService.instance.getValue(kDanmakuFontClamped, false);
  }

  void setDanmakuFontClampUpSens(double e) {
    danmakuFontClampUpSens.value = e;
    LocalStorageService.instance.setValue(kDanmakuFontClampUpSens, e);
  }

  void getDanmakuFontClampUpSens() {
    danmakuFontClampUpSens.value = LocalStorageService.instance.getValue(kDanmakuFontClampUpSens, 9.0);
  }

  void setDanmakuFontClampDownSens(double e) {
    danmakuFontClampDownSens.value = e;
    LocalStorageService.instance.setValue(kDanmakuFontClampDownSens, e);
  }

  void getDanmakuFontClampDownSens() {
    danmakuFontClampDownSens.value = LocalStorageService.instance.getValue(kDanmakuFontClampDownSens, 5.0);
  }

  void setQualityLevel(int e) {
    qualityLevel.value = e;
    LocalStorageService.instance.setValue(kQualityLevel, e);
  }

  void getQualityLevel() {
    qualityLevel.value = LocalStorageService.instance.getValue(kQualityLevel, 2);
  }

  void setQualityLevelCellular(int e) {
    qualityLevelCellular.value = e;
    LocalStorageService.instance.setValue(kQualityLevelCellular, e);
  }

  void getQualityLevelCellular() {
    qualityLevelCellular.value = LocalStorageService.instance.getValue(kQualityLevelCellular, 1);
  }

  void setAutoExitEnable(bool e) {
    autoExitEnable.value = e;
    LocalStorageService.instance.setValue(kAutoExitEnable, e);
  }

  void getAutoExitEnable() {
    autoExitEnable.value = LocalStorageService.instance.getValue(kAutoExitEnable, false);
  }

  void setAutoExitDuration(int e) {
    autoExitDuration.value = e;
    LocalStorageService.instance.setValue(kAutoExitDuration, e);
  }

  void getAutoExitDuration() {
    autoExitDuration.value = LocalStorageService.instance.getValue(kAutoExitDuration, 60);
  }

  void setRoomAutoExitDuration(int e) {
    roomAutoExitDuration.value = e;
    LocalStorageService.instance.setValue(kRoomAutoExitDuration, e);
  }

  void getRoomAutoExitDuration() {
    roomAutoExitDuration.value = LocalStorageService.instance.getValue(kRoomAutoExitDuration, 60);
  }

  void setPlayerCompatMode(bool e) {
    playerCompatMode.value = e;
    LocalStorageService.instance.setValue(kPlayerCompatMode, e);
  }

  void getPlayerCompatMode() {
    playerCompatMode.value = LocalStorageService.instance.getValue(kPlayerCompatMode, false);
  }

  void setPlayerBufferSize(int e) {
    playerBufferSize.value = e;
    LocalStorageService.instance.setValue(kPlayerBufferSize, e);
  }

  void getPlayerBufferSize() {
    playerBufferSize.value = LocalStorageService.instance.getValue(kPlayerBufferSize, 32);
  }

  void setPlayerAutoPause(bool e) {
    playerAutoPause.value = e;
    LocalStorageService.instance.setValue(kPlayerAutoPause, e);
  }

  void getPlayerAutoPause() {
    playerAutoPause.value = LocalStorageService.instance.getValue(kPlayerAutoPause, false);
  }

  void setAutoFullScreen(bool e) {
    autoFullScreen.value = e;
    LocalStorageService.instance.setValue(kAutoFullScreen, e);
  }

  void getAutoFullScreen() {
    autoFullScreen.value = LocalStorageService.instance.getValue(kAutoFullScreen, false);
  }

  void setVerticalDragLock(bool e) {
    verticalDragLock.value = e;
    LocalStorageService.instance.setValue(kVerticalDragLock, e);
  }

  void getVerticalDragLock() {
    verticalDragLock.value = LocalStorageService.instance.getValue(kVerticalDragLock, false);
  }

  void setPlayerVolume(double e) {
    playerVolume.value = e;
    LocalStorageService.instance.setValue(kPlayerVolume, e);
  }

  void getPlayerVolume() {
    playerVolume.value = LocalStorageService.instance.getValue(kPlayerVolume, 100.0);
  }

  void setPipHideDanmu(bool e) {
    pipHideDanmu.value = e;
    LocalStorageService.instance.setValue(kPipHideDanmu, e);
  }

  void getPipHideDanmu() {
    pipHideDanmu.value = LocalStorageService.instance.getValue(kPipHideDanmu, true);
  }

  void setWindowMaxAuto(bool e) {
    windowMaxAuto.value = e;
    LocalStorageService.instance.setValue(kWindowMaxAuto, e);
  }

  void getWindowMaxAuto() {
    windowMaxAuto.value = LocalStorageService.instance.getValue(kWindowMaxAuto, false);
  }

  void setWindowMaxState(bool e) {
    windowMaxState.value = e;
    LocalStorageService.instance.setValue(kWindowMaxState, e);
  }

  void getWindowMaxState() {
    windowMaxState.value = LocalStorageService.instance.getValue(kWindowMaxState, false);
  }

  void setWindowPipX(double e) {
    windowPipX.value = e;
    LocalStorageService.instance.setValue(kWindowPipX, e);
  }

  void getWindowPipX() {
    windowPipX.value = LocalStorageService.instance.getValue(kWindowPipX, 0.0);
  }

  void setWindowPipY(double e) {
    windowPipY.value = e;
    LocalStorageService.instance.setValue(kWindowPipY, e);
  }

  void getWindowPipY() {
    windowPipY.value = LocalStorageService.instance.getValue(kWindowPipY, 0.0);
  }

  void setWindowPipWidth(double e) {
    windowPipWidth.value = e;
    LocalStorageService.instance.setValue(kWindowPipWidth, e);
  }

  void getWindowPipWidth() {
    windowPipWidth.value = LocalStorageService.instance.getValue(kWindowPipWidth, 400.0);
  }

  void setWindowPipHeight(double e) {
    windowPipHeight.value = e;
    LocalStorageService.instance.setValue(kWindowPipHeight, e);
  }

  void getWindowPipHeight() {
    windowPipHeight.value = LocalStorageService.instance.getValue(kWindowPipHeight, 225.0);
  }

  void setDanmuTopMargin(double e) {
    danmuTopMargin.value = e;
    LocalStorageService.instance.setValue(kDanmuTopMargin, e);
  }

  void getDanmuTopMargin() {
    danmuTopMargin.value = LocalStorageService.instance.getValue(kDanmuTopMargin, 0.0);
  }

  void setDanmuBottomMargin(double e) {
    danmuBottomMargin.value = e;
    LocalStorageService.instance.setValue(kDanmuBottomMargin, e);
  }

  void getDanmuBottomMargin() {
    danmuBottomMargin.value = LocalStorageService.instance.getValue(kDanmuBottomMargin, 0.0);
  }

  void setDanmuTextNormalization(bool e) {
    danmuTextNormalization.value = e;
    LocalStorageService.instance.setValue(kDanmuTextNormalization, e);
  }

  void getDanmuTextNormalization() {
    danmuTextNormalization.value = LocalStorageService.instance.getValue(kDanmuTextNormalization, true);
  }

  void setDanmuMaxFrequency(int e) {
    danmuMaxFrequency.value = e;
    LocalStorageService.instance.setValue(kDanmuMaxFrequency, e);
  }

  void getDanmuMaxFrequency() {
    danmuMaxFrequency.value = LocalStorageService.instance.getValue(kDanmuMaxFrequency, 3);
  }

  void setDanmuFrequencyControl(bool e) {
    danmuFrequencyControl.value = e;
    LocalStorageService.instance.setValue(kDanmuFrequencyControl, e);
  }

  void getDanmuFrequencyControl() {
    danmuFrequencyControl.value = LocalStorageService.instance.getValue(kDanmuFrequencyControl, false);
  }

  void setDanmuWindowMs(int e) {
    danmuWindowMs.value = e;
    LocalStorageService.instance.setValue(kDanmuWindowMs, e);
  }

  void getDanmuWindowMs() {
    danmuWindowMs.value = LocalStorageService.instance.getValue(kDanmuWindowMs, 15);
  }

  void setBilibiliLoginTip(bool e) {
    bilibiliLoginTip.value = e;
    LocalStorageService.instance.setValue(kBilibiliLoginTip, e);
  }

  void getBilibiliLoginTip() {
    bilibiliLoginTip.value = LocalStorageService.instance.getValue(kBilibiliLoginTip, true);
  }

  void setLogEnable(bool e) {
    logEnable.value = e;
    LocalStorageService.instance.setValue(kLogEnable, e);
  }

  void getLogEnable() {
    logEnable.value = LocalStorageService.instance.getValue(kLogEnable, false);
  }

  void setFirebaseEnable(bool e) {
    firebaseEnable.value = e;
    LocalStorageService.instance.setValue(kFirebaseEnable, e);
  }

  void getFirebaseEnable() {
    firebaseEnable.value = LocalStorageService.instance.getValue(kFirebaseEnable, true);
  }

  void setCustomPlayerOutput(bool e) {
    customPlayerOutput.value = e;
    LocalStorageService.instance.setValue(kCustomPlayerOutput, e);
  }

  void getCustomPlayerOutput() {
    customPlayerOutput.value = LocalStorageService.instance.getValue(kCustomPlayerOutput, false);
  }

  void setVideoDoubleBuffering(bool e) {
    videoDoubleBuffering.value = e;
    LocalStorageService.instance.setValue(kVideoDoubleBuffering, e);
  }

  void getVideoDoubleBuffering() {
    videoDoubleBuffering.value = LocalStorageService.instance.getValue(kVideoDoubleBuffering, false);
  }

  void setEnableRtxVsr(bool e) {
    enableRtxVsr.value = e;
    LocalStorageService.instance.setValue(kEnableRtxVsr, e);
  }

  void getEnableRtxVsr() {
    enableRtxVsr.value = LocalStorageService.instance.getValue(kEnableRtxVsr, false);
  }

  void setAutoUpdateFollowEnable(bool e) {
    autoUpdateFollowEnable.value = e;
    LocalStorageService.instance.setValue(kAutoUpdateFollowEnable, e);
  }

  void getAutoUpdateFollowEnable() {
    autoUpdateFollowEnable.value = LocalStorageService.instance.getValue(kAutoUpdateFollowEnable, true);
  }

  void setAutoUpdateFollowDuration(int e) {
    autoUpdateFollowDuration.value = e;
    LocalStorageService.instance.setValue(kAutoUpdateFollowDuration, e);
  }

  void getAutoUpdateFollowDuration() {
    autoUpdateFollowDuration.value = LocalStorageService.instance.getValue(kAutoUpdateFollowDuration, 10);
  }

  void setUpdateFollowThreadCount(int e) {
    updateFollowThreadCount.value = e;
    LocalStorageService.instance.setValue(kUpdateFollowThreadCount, e);
  }

  void getUpdateFollowThreadCount() {
    updateFollowThreadCount.value = LocalStorageService.instance.getValue(kUpdateFollowThreadCount, 4);
  }

  void setFollowSnapshotEnable(bool e) {
    followSnapshotEnable.value = e;
    LocalStorageService.instance.setValue(kFollowSnapshotEnable, e);
  }

  void getFollowSnapshotEnable() {
    followSnapshotEnable.value = LocalStorageService.instance.getValue(kFollowSnapshotEnable, false);
  }

  void setDormancyThreshold(int e) {
    dormancyThreshold.value = e;
    LocalStorageService.instance.setValue(kDormancyThreshold, e);
  }

  void getDormancyThreshold() {
    dormancyThreshold.value = LocalStorageService.instance.getValue(kDormancyThreshold, 0);
  }

  void setPlayerForceHttps(bool e) {
    playerForceHttps.value = e;
    LocalStorageService.instance.setValue(kPlayerForceHttps, e);
  }

  void getPlayerForceHttps() {
    playerForceHttps.value = LocalStorageService.instance.getValue(kPlayerForceHttps, false);
  }

  void setDouyinHlsFirst(bool e) {
    douyinHlsFirst.value = e;
    LocalStorageService.instance.setValue(kDouyinHlsFirst, e);
  }

  void getDouyinHlsFirst() {
    douyinHlsFirst.value = LocalStorageService.instance.getValue(kDouyinHlsFirst, false);
  }

  void setFollowStyleNotGrid(bool e) {
    followStyleNotGrid.value = e;
    LocalStorageService.instance.setValue(kFollowStyleNotGrid, e);
  }

  void getFollowStyleNotGrid() {
    followStyleNotGrid.value = LocalStorageService.instance.getValue(kFollowStyleNotGrid, true);
  }

  void setHideOfflineFollow(bool e) {
    hideOfflineFollow.value = e;
    LocalStorageService.instance.setValue(kHideOfflineFollow, e);
  }

  void getHideOfflineFollow() {
    hideOfflineFollow.value = LocalStorageService.instance.getValue(kHideOfflineFollow, false);
  }

  void setHideRemoveFollowButton(bool e) {
    hideRemoveFollowButton.value = e;
    LocalStorageService.instance.setValue(kHideRemoveFollowButton, e);
  }

  void getHideRemoveFollowButton() {
    hideRemoveFollowButton.value = LocalStorageService.instance.getValue(kHideRemoveFollowButton, true);
  }
}

// storage keys
const String kScaleMode = "ScaleMode";
const String kAspectByUser = "PlayerAspectByUser";
const String kAspectWidth = "PlayerAspectWidth";
const String kAspectHeight = "PlayerAspectHeight";
const String kThemeMode = "ThemeMode";
const String kHardwareDecode = "HardwareDecode";
const String kChatTextSize = "ChatTextSize";
const String kChatTextGap = "ChatTextGap";
const String kChatBubbleStyle = "ChatBubbleStyle";
const String kDanmuSize = "DanmuSize";
const String kDanmuSpeed = "DanmuSpeed";
const String kDanmuArea = "DanmuArea";
const String kDanmuOpacity = "DanmuOpacity";
const String kDanmuEnable = "DanmuEnable";
const String kDanmakuMaskEnable = "DanmakuMaskEnable";
const String kDanmuEmoticonEnable = "DanmuEmoticonEnable";
const String kDanmuStrokeWidth = "DanmuStrokeWidth";
const String kDanmakuFontClamped = "DanmakuFontClamped";
const String kDanmakuFontClampUpSens = "DanmakuFontClampUpSens";
const String kDanmakuFontClampDownSens = "DanmakuFontClampDownSens";
const String kQualityLevel = "QualityLevel";
const String kQualityLevelCellular = "QualityLevelCellular";
const String kAutoExitEnable = "AutoExitEnable";
const String kAutoExitDuration = "AutoExitDuration";
const String kRoomAutoExitDuration = "RoomAutoExitDuration";
const String kPlayerCompatMode = "PlayerCompatMode";
const String kPlayerBufferSize = "PlayerBufferSize";
const String kPlayerAutoPause = "PlayerAutoPause";
const String kAutoFullScreen = "AutoFullScreen";
const String kVerticalDragLock = "VerticalDragLock";
const String kPlayerVolume = "PlayerVolume";
const String kPipHideDanmu = "PIPHideDanmu";
const String kWindowMaxAuto = "WindowMaxAuto";
const String kWindowMaxState = "WindowMaxState";
const String kWindowPipX = "WindowPipX";
const String kWindowPipY = "WindowPipY";
const String kWindowPipWidth = "WindowPipWidth";
const String kWindowPipHeight = "WindowPipHeight";
const String kDanmuTopMargin = "DanmuTopMargin";
const String kDanmuBottomMargin = "DanmuBottomMargin";
const String kDanmuTextNormalization = "DanmuTextNormalization";
const String kDanmuMaxFrequency = "DanmuMaxFrequency";
const String kDanmuFrequencyControl = "DanmuFrequencyControl";
const String kDanmuWindowMs = "DanmuWindowMs";
const String kBilibiliLoginTip = "BilibiliLoginTip";
const String kLogEnable = "LogEnable";
const String kFirebaseEnable = "FirebaseEnable";
const String kCustomPlayerOutput = "CustomPlayerOutput";
const String kVideoDoubleBuffering = "VideoDoubleBuffering";
const String kEnableRtxVsr = "EnableRtxVsr";
const String kAutoUpdateFollowEnable = "AutoUpdateFollowEnable";
const String kAutoUpdateFollowDuration = "AutoUpdateFollowDuration";
const String kUpdateFollowThreadCount = "UpdateFollowThreadCount";
const String kFollowSnapshotEnable = "FollowSnapshotEnable";
const String kDormancyThreshold = "DormancyThreshold";
const String kPlayerForceHttps = "PlayerForceHttps";
const String kDouyinHlsFirst = "DouyinHlsFirst";
const String kFollowStyleNotGrid = "FollowStyleNotGrid";
const String kHideOfflineFollow = "HideOfflineFollow";
const String kHideRemoveFollowButton = "kHideRemoveFollow";
