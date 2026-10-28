import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:simple_live_core/src/common/http_client.dart';
import 'package:simple_live_core/src/common/parse_cookie.dart';

class DouyuUtils {
  // params
  static String _did = '10000000000000000000000000001501';

  static final int _encCacheTTL = 5 * 60;

  static Map<String, dynamic> _encKey = {};

  // api
  // douyu-enc
  static final _apiDouyuEnc = "https://www.douyu.com/wgapi/livenc/liveweb/websec/getEncryption";

  // safe auth
  static final _apiDouyuPassport = 'https://passport.douyu.com/lapi/passport/iframe/safeAuth';

  static final douyuOrigin = 'https://www.douyu.com';

  static final douyuLoginReferer = 'https://passport.douyu.com/index/login?type=login&client_id=1';

  // douyu-live-stream
  static Map<String, String> requestHeader({String roomId = '', String cookie = '', bool isLogin = false}) {
    var referer = roomId.isEmpty ? douyuOrigin : '$douyuOrigin/$roomId';
    if (isLogin) {
      referer = douyuLoginReferer;
    }
    var res = {
      'accept': '*/*',
      'accept-encoding': 'gzip, deflate, br, zstd',
      'accept-language': 'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6,zh-Hans;q=0.5',
      'origin': douyuOrigin,
      'referer': referer,
      "content-type": "application/x-www-form-urlencoded",
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.43',
      'cookie': 'dy_did=$_did; acf_did=$_did',
    };
    if (cookie.isNotEmpty) {
      res['cookie'] = cookie;
    }
    return res;
  }

  static void setDyDid(String dy_did) {
    _did = dy_did;
  }

  static Future<String> refreshCookie({String did = '', String ltp0 = '', String cookie = ''}) async {
    // expired-> refresh
    if (_isCookieExpired(cookie) && ltp0.isNotEmpty && did.isNotEmpty) {
      // milliseconds not sec
      final t = DateTime.now().millisecondsSinceEpoch.toString();
      final query = <String, dynamic>{
        'client_id': '1',
        't': t,
        '_': t,
        'callback': 'axiosJsonpCallback',
      };

      final resp = await HttpClient.instance.getResponse(
        _apiDouyuPassport,
        queryParameters: query,
        header: requestHeader(cookie: 'dy_did=$did;LTP0=$ltp0'),
      );
      cookie = (resp.headers['set-cookie'] ?? const <String>[])
          .map((raw) => raw.split(';').first.trim())
          .where((s) => s.contains('='))
          .join('; ');
      // check again
      cookie = _isCookieExpired(cookie) ? '' : cookie;
      _did = did;
    }
    return cookie;
  }

  // expired -> true
  static bool _isCookieExpired(String cookie) {
    final jwt = _getJwtToken(cookie);
    if (jwt == null) return true;
    try {
      var payload = decodeJwtPayload(jwt);
      var exp = payload['exp'];
      if (exp is! int) return true;
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return nowSec >= exp;
    } catch (_) {
      return true;
    }
  }

  static String? _getJwtToken(String cookie) {
    if (cookie.isNotEmpty) {
      for (final pair in cookie.split(';')) {
        final p = pair.trim();
        if (p.startsWith('acf_jwt_token=')) {
          return p.substring('acf_jwt_token='.length);
        }
      }
    }
    return null;
  }

  static bool _encKeyCheck() {
    return (_encKey["expire_at"] ?? 0) > (DateTime.now().millisecondsSinceEpoch ~/ 1000);
  }

  static Future<void> _encKeyUpdate({String cookie = ''}) async {
    if (_encKeyCheck()) {
      return;
    }
    var res = await HttpClient.instance.getJson(
      _apiDouyuEnc,
      queryParameters: {
        "did": _did,
      },
      header: requestHeader(cookie: cookie),
    );
    res['data']?["expire_at"] = DateTime.now().millisecondsSinceEpoch ~/ 1000 + _encCacheTTL;
    _encKey = res['data'];
  }

  // 用于流/登录/弹幕，暂时只需要流获取
  static Future<String> sign(String rid, {int rate = -1, String cdn = "hw-h5", String cookie = ''}) async {
    var ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _encKeyUpdate(cookie: cookie);
    String randStr = _encKey["rand_str"] ?? "";
    int encTime = _encKey["enc_time"] ?? 1;
    String salt = (_encKey['is_special'] ?? 0) == 1 ? "" : "$rid$ts";
    String key = _encKey['key'];

    String secret = randStr;
    // 其实只有一次
    for (var i = 0; i < encTime; i++) {
      secret = md5.convert(utf8.encode("$secret$key")).toString();
    }
    String auth = md5.convert(utf8.encode("$secret$key$salt")).toString();
    var postData = Uri(
      queryParameters: {
        'enc_data': _encKey['enc_data'],
        'tt': '$ts',
        'did': _did,
        'auth': auth,
        'cdn': cdn,
        'ver': 'Douyu_new',
        'rate': '$rate',
        'hevc': '1',
        'fa': '0',
        'ive': '0',
      },
    ).query;
    return postData;
  }
  // todo: 获取real_rid 暂未发现 fake_id

  // 从set-cookie中获取字段
  static String pickSetCookie(List<String> raw, String name) {
    for (final e in raw) {
      final c = Cookie.fromSetCookieValue(e);
      if (c.name == name) {
        return c.value;
      }
    }
    return '';
  }

  // 从cookie 中获取字段
  static String pickCookie(String? cookie, String name) {
    if (cookie == null || cookie.isEmpty) return '';

    for (final part in cookie.split(';')) {
      final p = part.trim();
      if (p.isEmpty) continue;
      final i = p.indexOf('=');
      if (i <= 0) continue;
      if (p.substring(0, i).trim() == name) {
        return p.substring(i + 1).trim();
      }
    }
    return '';
  }
}
