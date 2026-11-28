import 'dart:convert';

class LiveRoomDetail {
  /// 房间ID
  final String roomId;

  /// 房间标题
  final String title;

  /// 封面
  final String cover;

  /// 用户名
  final String userName;

  /// 头像
  final String userAvatar;

  /// 在线
  final int online;

  /// 介绍
  final String? introduction;

  /// 公告
  final String? notice;

  /// 状态
  final bool status;

  /// 附加信息
  final dynamic data;

  /// 弹幕附加信息
  final dynamic danmakuData;

  /// 是否录播
  final bool isRecord;

  /// 链接
  final String url;

  /// 平台分类ID（各平台自己的分类ID体系，用于标签自动绑定）
  final String? categoryId;

  /// 平台分类名（如：无畏契约 / VALORANT）
  final String? categoryName;

  /// 平台一级分类名（如：网游 / 娱乐）
  final String? parentCategoryName;

  LiveRoomDetail({
    required this.roomId,
    required this.title,
    required this.cover,
    required this.userName,
    required this.userAvatar,
    required this.online,
    this.introduction,
    this.notice,
    required this.status,
    this.data,
    this.danmakuData,
    required this.url,
    this.isRecord = false,
    this.categoryId,
    this.categoryName,
    this.parentCategoryName,
  });

  LiveRoomDetail copyWith({
    String? roomId,
    String? title,
    String? cover,
    String? userName,
    String? userAvatar,
    int? online,
    String? introduction,
    String? notice,
    bool? status,
    dynamic data,
    dynamic danmakuData,
    String? url,
    bool? isRecord,
    String? categoryId,
    String? categoryName,
    String? parentCategoryName,
  }) {
    return LiveRoomDetail(
      roomId: roomId ?? this.roomId,
      title: title ?? this.title,
      cover: cover ?? this.cover,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      online: online ?? this.online,
      introduction: introduction ?? this.introduction,
      notice: notice ?? this.notice,
      status: status ?? this.status,
      data: data ?? this.data,
      danmakuData: danmakuData ?? this.danmakuData,
      isRecord: isRecord ?? this.isRecord,
      url: url ?? this.url,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      parentCategoryName: parentCategoryName ?? this.parentCategoryName,
    );
  }

  LiveRoomDetail updateData(dynamic newData) {
    return copyWith(data: newData);
  }

  LiveRoomDetail updateDanmakuData(dynamic newDanmakuData) {
    return copyWith(danmakuData: newDanmakuData);
  }

  @override
  String toString() {
    return json.encode({
      "roomId": roomId,
      "title": title,
      "cover": cover,
      "userName": userName,
      "userAvatar": userAvatar,
      "online": online,
      "introduction": introduction,
      "notice": notice,
      "status": status,
      "data": data,
      "danmakuData": danmakuData.toString(),
      "url": url,
      "isRecord": isRecord,
      "categoryId": categoryId,
      "categoryName": categoryName,
      "parentCategoryName": parentCategoryName,
    });
  }
}
