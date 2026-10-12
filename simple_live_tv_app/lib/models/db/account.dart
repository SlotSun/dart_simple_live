import 'package:hive/hive.dart';

part 'account.g.dart';
// tv 简化model / 默认每次都要请求用户数据
@HiveType(typeId: 3)
class Account {
  /// 全局唯一ID
  @HiveField(0)
  String id;

  /// 所属平台
  @HiveField(1)
  String siteId;
  
  /// 凭证
  @HiveField(2, defaultValue: '')
  String credential;
  /// 创建/更新时间
  @HiveField(3, defaultValue: 0)
  int createdAt;
  @HiveField(4, defaultValue: 0)
  int updatedAt;
  
  /// 昵称/用户名
  String? userName;
  
  /// 头像
  String? avatar;

  String? uid;
  
  /// 是否当前激活账号
   bool isActive = false;



  Account({
    required this.id,
    required this.siteId,
    this.userName,
    this.avatar,
    this.uid,
    this.isActive = false,
    required this.credential,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      siteId: json['siteId'] as String,
      credential: json['credential'] as String,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }

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
  }) {
    return Account(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      userName: userName ?? this.userName,
      avatar: avatar ?? this.avatar,
      uid: uid ?? this.uid,
      isActive: isActive ?? this.isActive,
      credential: credential ?? this.credential,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
      };

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
        ')';
  }
}
