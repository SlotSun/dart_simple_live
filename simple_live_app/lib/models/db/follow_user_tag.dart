import 'package:hive_ce/hive_ce.dart';

part 'follow_user_tag.g.dart';

/// 标签绑定的平台分类
///
/// 例如标签「无畏契约」绑定：
/// `[{siteId: huya, categoryId: 5937}, {siteId: bilibili, categoryId: 508}]`
/// 关注该分类下的主播时，可自动归入该标签。
@HiveType(typeId: 9)
class TagBinding {
  /// 平台ID（huya/bilibili/douyu/douyin/twitch）
  @HiveField(1)
  String siteId;

  /// 平台自己的分类ID
  @HiveField(2)
  String categoryId;

  /// 分类名（仅展示用）
  @HiveField(3)
  String categoryName;

  TagBinding({
    required this.siteId,
    required this.categoryId,
    this.categoryName = "",
  });

  factory TagBinding.fromJson(Map<String, dynamic> json) {
    return TagBinding(
      siteId: json['siteId'] ?? "",
      categoryId: json['categoryId'] ?? "",
      categoryName: json['categoryName'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'siteId': siteId,
      'categoryId': categoryId,
      'categoryName': categoryName,
    };
  }

  /// 是否匹配指定的平台分类
  bool matches(String site, String category) {
    return siteId == site && categoryId == category;
  }

  TagBinding copyWith({
    String? siteId,
    String? categoryId,
    String? categoryName,
  }) {
    return TagBinding(
      siteId: siteId ?? this.siteId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
    );
  }
}

@HiveType(typeId: 3)
class FollowUserTag {
  @HiveField(1)
  String id;

  // 用户自定义tag
  @HiveField(2)
  String tag;

  // followUserId
  @HiveField(3)
  List<String> userId;

  /// 绑定的平台分类（用于自动归类）
  @HiveField(4, defaultValue: [])
  List<TagBinding> bindings;

  FollowUserTag({
    required this.id,
    required this.tag,
    required this.userId,
    List<TagBinding>? bindings,
  }) : bindings = bindings ?? [];

  factory FollowUserTag.fromJson(Map<String, dynamic> json) {
    return FollowUserTag(
      id: json['id'],
      tag: json['tag'],
      userId: List<String>.from(json['userId']),
      // 老版本同步包没有 bindings 字段，缺失时按空处理
      bindings: (json['bindings'] as List?)
              ?.map((e) => TagBinding.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag': tag,
      'userId': userId,
      'bindings': bindings.map((e) => e.toJson()).toList(),
    };
  }

  FollowUserTag copyWith({
    String? id,
    String? tag,
    List<String>? userId,
    List<TagBinding>? bindings,
  }) {
    return FollowUserTag(
      id: id ?? this.id,
      tag: tag ?? this.tag,
      userId: userId ?? this.userId,
      bindings: bindings ?? this.bindings,
    );
  }
}
