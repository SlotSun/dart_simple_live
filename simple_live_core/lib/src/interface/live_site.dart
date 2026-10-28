import 'package:simple_live_core/src/common/qr_status.dart';
import 'package:simple_live_core/src/model/account_info.dart';
import 'package:simple_live_core/src/model/account_qr_code.dart';
import 'package:simple_live_core/src/model/live_anchor_item.dart';

import '../interface/live_danmaku.dart';
import '../model/live_category_result.dart';
import '../model/live_message.dart';
import '../model/live_play_url.dart';
import '../model/live_room_detail.dart';
import '../model/live_search_result.dart';

import '../model/live_category.dart';
import '../model/live_play_quality.dart';
import '../model/live_room_item.dart';

class LiveSite {
  /// 站点唯一ID
  String id = "";

  /// 站点名称
  String name = "";

  /// 站点名称
  LiveDanmaku getDanmaku() => LiveDanmaku();

  /// 读取网站的分类
  Future<List<LiveCategory>> getCategories() {
    return Future.value(<LiveCategory>[]);
  }

  /// 搜索直播间
  Future<LiveSearchRoomResult> searchRooms(String keyword, {int page = 1}) {
    return Future.value(
        LiveSearchRoomResult(hasMore: false, items: <LiveRoomItem>[]));
  }

  /// 搜索直播间
  Future<LiveSearchAnchorResult> searchAnchors(String keyword, {int page = 1}) {
    return Future.value(
        LiveSearchAnchorResult(hasMore: false, items: <LiveAnchorItem>[]));
  }

  /// 读取类目下房间
  Future<LiveCategoryResult> getCategoryRooms(LiveSubCategory category,
      {int page = 1}) {
    return Future.value(
        LiveCategoryResult(hasMore: false, items: <LiveRoomItem>[]));
  }

  /// 读取推荐的房间
  Future<LiveCategoryResult> getRecommendRooms({int page = 1}) {
    return Future.value(
        LiveCategoryResult(hasMore: false, items: <LiveRoomItem>[]));
  }

  /// 读取房间详情
  Future<LiveRoomDetail> getRoomDetail({required String roomId}) {
    return Future.value(LiveRoomDetail(
      cover: '',
      online: 0,
      roomId: '',
      status: false,
      title: '',
      url: '',
      userAvatar: '',
      userName: '',
    ));
  }

  /// 读取房间清晰度
  Future<List<LivePlayQuality>> getPlayQualities(
      {required LiveRoomDetail detail}) {
    return Future.value(<LivePlayQuality>[]);
  }

  /// 读取播放链接
  Future<LivePlayUrl> getPlayUrls(
      {required LiveRoomDetail detail, required LivePlayQuality quality}) {
    return Future.value(LivePlayUrl(urls: []));
  }

  /// 查询直播状态
  Future<bool> getLiveStatus({required String roomId}) {
    return Future.value(false);
  }

  /// 读取指定房间的SC
  Future<List<LiveSuperChatMessage>> getSuperChatMessage(
      {required String roomId}) {
    return Future.value([]);
  }

  /// 配置站点参数，包括不限于 cookie/ua
  ///
  /// `data` string2json来适配不同平台的credentials
  void setSiteAttrs(String data){
  }

  /// 获取登录二维码
  Future<QRCode> getQRCode() {
    return Future.value(QRCode(key: '', url: ''));
  }

  /// 获取二维码扫码状态
  Future<QRPollResult> getQRPollResult({required String qrcodeKey}) {
    return Future.value(QRPollResult(status: QRStatus.failed));
  }
  /// data follow: login or init -> getAccountInfo(== check credential like cookie/did etc)
  /// if account_info.isValid == true -> save -> setSiteAttrs->
  /// because every site is singleInstant
  /// 获取账号数据
  Future<AccountInfo> getAccountInfo({required String credential}) {
    return Future.value(AccountInfo());
  }
}
