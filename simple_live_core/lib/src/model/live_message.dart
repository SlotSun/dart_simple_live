import 'dart:convert';

enum LiveMessageType {
  /// 聊天
  chat,

  /// 礼物,暂时不支持
  gift,

  /// 在线人数
  online,

  /// 醒目留言
  superChat,
}

class LiveMessage {
  /// 消息类型
  final LiveMessageType type;

  /// 用户名
  final String userName;

  /// 用户 id
  final String? userId;

  /// 信息
  final String message;

  /// 数据
  /// 单Type=Online时，Data为人气值(long)
  final dynamic data;

  /// 弹幕颜色
  final LiveMessageColor color;

  /// 弹幕表情包（可选，目前仅 B 站直播间提供）
  final List<LiveMessageEmoticon>? emoticons;

  LiveMessage({
    required this.type,
    required this.userName,
    required this.message,
    this.data,
    this.userId,
    required this.color,
    this.emoticons,
  });

  @override
  String toString() {
    return json.encode({
      "type": type.index,
      "userName": userName,
      "message": message,
      "data": data.toString(),
      "color": color.toString(),
      if (emoticons != null)
        "emoticons": emoticons!.map((e) => e.toJson()).toList(),
    });
  }
}

/// 弹幕里的表情包（B 站直播间的「表情包」弹幕）
///
/// 注意：表情是以图片形式下发的，[message] 里对应位置只有占位符文本（如 `[doge]`），
/// 需要渲染层用 [url] 取图后替换 [name] 才能显示成图片。
class LiveMessageEmoticon {
  /// 占位符文本，如 `[doge]`
  ///
  /// 为 null 表示无法定位到文本中的具体占位符，渲染层应把它追加到消息末尾。
  final String? name;

  /// 图片地址（已规范化为 https）
  final String url;

  /// 服务端下发的原始宽，用于还原宽高比（可能为 null，此时以图片自带尺寸为准）
  final int? width;

  /// 服务端下发的原始高
  final int? height;

  const LiveMessageEmoticon({
    required this.name,
    required this.url,
    this.width,
    this.height,
  });

  /// 供 [LiveMessage.toString] 组装 JSON 用的对象形态。
  ///
  /// 不要用 [toString] 代替它：那会得到一个 JSON 字符串，外层再
  /// `json.encode` 一次就变成「字符串数组」，消费方按对象取值会拿到字符串。
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "url": url,
      "width": width,
      "height": height,
    };
  }

  @override
  String toString() {
    return json.encode(toJson());
  }
}

class LiveMessageColor {
  final int r, g, b;
  LiveMessageColor(this.r, this.g, this.b);
  static LiveMessageColor get white => LiveMessageColor(255, 255, 255);
  static LiveMessageColor numberToColor(int intColor) {
    var obj = intColor.toRadixString(16);

    LiveMessageColor color = LiveMessageColor.white;
    if (obj.length == 4) {
      obj = "00$obj";
    }
    if (obj.length == 6) {
      var R = int.parse(obj.substring(0, 2), radix: 16);
      var G = int.parse(obj.substring(2, 4), radix: 16);
      var B = int.parse(obj.substring(4, 6), radix: 16);

      color = LiveMessageColor(R, G, B);
    }
    if (obj.length == 8) {
      var R = int.parse(obj.substring(2, 4), radix: 16);
      var G = int.parse(obj.substring(4, 6), radix: 16);
      var B = int.parse(obj.substring(6, 8), radix: 16);
      //var A = int.parse(obj.substring(0, 2), radix: 16);
      color = LiveMessageColor(R, G, B);
    }

    return color;
  }

  @override
  String toString() {
    return "#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}";
  }
}

class LiveSuperChatMessage {
  final String userName;
  final String face;
  final String message;
  final int price;
  final DateTime startTime;
  final DateTime endTime;
  final String backgroundColor;
  final String backgroundBottomColor;
  LiveSuperChatMessage({
    required this.backgroundBottomColor,
    required this.backgroundColor,
    required this.endTime,
    required this.face,
    required this.message,
    required this.price,
    required this.startTime,
    required this.userName,
  });

  @override
  String toString() {
    return json.encode({
      "userName": userName,
      "face": face,
      "message": message,
      "price": price,
      "startTime": startTime,
      "endTime": endTime,
      "backgroundColor": backgroundColor,
      "backgroundBottomColor": backgroundBottomColor,
    });
  }
}
