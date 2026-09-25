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

  static Map<String, String> get requestHeaders {
    return {
      'Origin': baseUrl,
      'Referer': baseUrl,
      'User-Agent': HYSDK_UA,
    };
  }
}
