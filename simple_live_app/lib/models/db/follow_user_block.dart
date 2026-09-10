import 'package:hive_ce/hive_ce.dart';

part 'follow_user_block.g.dart';

@HiveType(typeId: 7)
class FollowUserBlock {
  FollowUserBlock({
    required this.id,
    required this.roomId,
    required this.siteId,
    required this.blockAccounts,
    required this.blockWords,
    this.updateTime = 0,
  });

  /// id=siteId_roomId
  @HiveField(0)
  String id;

  /// 直播间id
  @HiveField(1)
  String roomId;

  /// 直播间平台
  @HiveField(2)
  String siteId;

  /// 屏蔽账户
  @HiveField(3, defaultValue: [])
  List<FollowUserBlockAccount> blockAccounts;

  /// 屏蔽词
  @HiveField(4, defaultValue: [])
  List<String> blockWords;

  /// 更新时间（秒级时间戳）
  @HiveField(5, defaultValue: 0)
  int updateTime;

  factory FollowUserBlock.fromJson(Map<String, dynamic> json) =>
      FollowUserBlock(
        id: json['id'],
        roomId: json['roomId'],
        siteId: json['siteId'],
        blockAccounts: (json['blockAccounts'] as List<dynamic>?)
                ?.map((e) => FollowUserBlockAccount.fromJson(e))
                .toList() ??
            [],
        blockWords: (json['blockWords'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        updateTime: json['updateTime'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'siteId': siteId,
        'blockAccounts': blockAccounts.map((e) => e.toJson()).toList(),
        'blockWords': blockWords,
        'updateTime': updateTime,
      };

  FollowUserBlock copyWith({
    String? id,
    String? roomId,
    String? siteId,
    List<FollowUserBlockAccount>? blockAccounts,
    List<String>? blockWords,
    int? updateTime,
  }) {
    return FollowUserBlock(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      siteId: siteId ?? this.siteId,
      blockAccounts: blockAccounts ?? this.blockAccounts,
      blockWords: blockWords ?? this.blockWords,
      updateTime: updateTime ?? this.updateTime,
    );
  }
}

@HiveType(typeId: 6)
class FollowUserBlockAccount {
  FollowUserBlockAccount({
    required this.uid,
    required this.name,
  });

  @HiveField(0)
  String uid;

  @HiveField(1)
  String name;

  factory FollowUserBlockAccount.fromJson(Map<String, dynamic> json) =>
      FollowUserBlockAccount(
        uid: json['uid'],
        name: json['name'],
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
      };

  FollowUserBlockAccount copyWith({
    String? uid,
    String? name,
  }) {
    return FollowUserBlockAccount(
      uid: uid ?? this.uid,
      name: name ?? this.name,
    );
  }
}
