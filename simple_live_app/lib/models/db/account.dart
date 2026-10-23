import 'package:hive_ce/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 8)
class Account {
  /// 全局唯一ID
  @HiveField(0)
  final String id;

  /// 所属平台
  @HiveField(1)
  final String siteId;

  /// 昵称/用户名
  @HiveField(2)
  final String? userName;

  /// 头像
  @HiveField(3)
  final String? avatar;

  /// 平台内的用户ID
  @HiveField(4)
  final String? uid;

  /// 凭证
  @HiveField(5, defaultValue: '')
  String credential;

  /// 是否当前激活账号
  @HiveField(6, defaultValue: true)
  final bool isActive;

  /// 创建/更新时间
  @HiveField(7, defaultValue: 0)
  final int createdAt;
  @HiveField(8, defaultValue: 0)
  final int updatedAt;

  @HiveField(9, defaultValue: false)
  final bool supportQRLogin;

  @HiveField(10, defaultValue: false)
  final bool supportCookieLogin;

  @HiveField(11, defaultValue: false)
  final bool supportWebLogin;

  Account({
    required this.id,
    required this.siteId,
    this.userName,
    this.avatar,
    this.uid,
    required this.credential,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.supportCookieLogin = false,
    this.supportQRLogin = false,
    this.supportWebLogin = false,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      siteId: json['siteId'] as String,
      userName: json['userName'] as String?,
      avatar: json['avatar'] as String?,
      uid: json['uid'] as String?,
      credential: json['credential'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
      supportCookieLogin: json['supportCookieLogin'] as bool,
      supportQRLogin: json['supportQRLogin'] as bool,
      supportWebLogin: json['supportWebLogin'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'siteId': siteId,
        'userName': userName,
        'avatar': avatar,
        'uid': uid,
        'credential': credential,
        'isActive': isActive,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'supportCookieLogin': supportCookieLogin,
        'supportQRLogin': supportQRLogin,
        'supportWebLogin': supportWebLogin,
      };

  Account copyWith({
    String? id,
    String? siteId,
    String? userName,
    String? avatar,
    String? uid,
    String? credential,
    bool? isActive,
    int? createdAt,
    int? updatedAt,
    bool? supportCookieLogin,
    bool? supportQRLogin,
    bool? supportWebLogin,
  }) {
    return Account(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      userName: userName ?? this.userName,
      avatar: avatar ?? this.avatar,
      uid: uid ?? this.uid,
      credential: credential ?? this.credential,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      supportCookieLogin: supportCookieLogin ?? this.supportCookieLogin,
      supportQRLogin: supportQRLogin ?? this.supportQRLogin,
      supportWebLogin: supportWebLogin ?? this.supportWebLogin,
    );
  }

  @override
  String toString() {
    return 'Account('
        'id: $id, '
        'siteId: $siteId, '
        'userName: $userName, '
        'avatar: $avatar, '
        'uid: $uid, '
        'credential: $credential, '
        'isActive: $isActive, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'supportQRLogin: $supportQRLogin, '
        'supportCookieLogin: $supportCookieLogin, '
        'supportWebLogin: $supportWebLogin'
        ')';
  }
}
