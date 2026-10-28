import "dart:math";

mixin HuyaRequestParams {
  static const String baseUrl = "https://www.huya.com";
  static const String wupUrl = "http://wup.huya.com";
  static const String kUserAgent =
      "Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.91 Mobile Safari/537.36 Edg/117.0.0.0";

// regex
  /// 匹配房间数据
  static const String ROOM_DATA_REGEX = r'var\s+TT_ROOM_DATA\s*=\s*(\{[\s\S]*?\})';

  /// 匹配流数据
  static const String STREAM_REGEX = r"stream:\s*(\{[\s\S]*?\n\s*\})";

  /// 匹配 YY ID
  static const String AYYUID_REGEX = r'"yyid":"?(\d+)"?';

  static String HYSDK_UA = "HYSDK(Windows,30000002)_APP(pc_exe&7100004&official)_SDK(trans&2.40.0.6448)";

  /// 随机生成虎牙 SDK 的 UA，如 `adr&13.1.0.3456&official&31`
  static String get requestHuyaUA {
    const platforms = [
      (name: "adr", version: "13.1.0", hasApiLevel: true),
      (name: "ios", version: "13.1.0", hasApiLevel: false),
      (name: "huya_nftv", version: "2.6.10", hasApiLevel: true),
      (name: "pc_exe", version: "7000000", hasApiLevel: false),
    ];

    final platform = platforms[Random().nextInt(platforms.length)];
    var version = platform.version;

    // 支持多版本号的平台，追加一个随机子版本号
    if (platform.name == "adr" || platform.name == "huya_nftv") {
      version = "$version.${Random().nextInt(2000) + 3000}";
    }

    var ua = "${platform.name}&$version&official";

    // 追加 Android API Level（28-36）
    if (platform.hasApiLevel) {
      ua = "$ua&${Random().nextInt(9) + 28}";
    }

    return ua;
  }

  static Map<String, String> get requestHeaders {
    return {
      'Origin': baseUrl,
      'Referer': baseUrl,
      'User-Agent': HYSDK_UA,
    };
  }
}
