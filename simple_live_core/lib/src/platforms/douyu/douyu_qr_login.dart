import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

enum DouyuQrStatus { waiting, scanned, expired, authorized }

/// A separate passport session. Credentials never go through the app's logging
/// HTTP interceptor or its account sync server.
class DouyuQrLogin {
  DouyuQrLogin({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)));

  final Dio _dio;
  final _cookies = <String, Cookie>{};
  final _cancel = CancelToken();
  static final _passport = Uri.parse('https://passport.douyu.com/');
  String _code = '';
  String get did => _cookieValue('dy_did');
  String get ltp0 => _cookieValue('LTP0');

  String _cookieValue(String name) {
    for (final cookie in _cookies.values) {
      if (cookie.name.toLowerCase() == name.toLowerCase()) return cookie.value;
    }
    return '';
  }

  Future<String> generate() async {
    _cookies.clear();
    // The official page requests this endpoint before generating its QR code.
    final device = await _request(_passport.resolve('/lapi/did/api/get'),
        query: {'client_id': '1', 'callback': 'slive_did'});
    final deviceId = device['data']?['did'] as String?;
    final cookie = Cookie(
        'dy_did',
        deviceId?.isNotEmpty == true
            ? deviceId!
            : '10000000000000000000000000001501')
      ..domain = 'douyu.com'
      ..path = '/'
      ..secure = true;
    _cookies['douyu.com/|dy_did'] = cookie;
    final result = await _request(_passport.resolve('/scan/generateCode'),
        data: {'client_id': '1', 'isMultiAccount': '0'});
    if (result['error'] != 0 ||
        result['data']?['code'] == null ||
        result['data']?['url'] == null) {
      throw StateError('斗鱼二维码生成失败，请刷新重试');
    }
    _code = result['data']['code'].toString();
    return result['data']['url'].toString();
  }

  Future<DouyuQrStatus> poll() async {
    if (_code.isEmpty) return DouyuQrStatus.expired;
    final result = await _request(_passport.resolve('/japi/scan/auth'), query: {
      'code': _code,
      'time': DateTime.now().millisecondsSinceEpoch.toString(),
    });
    switch (result['error']) {
      case -2:
        return DouyuQrStatus.waiting;
      case 1:
        return DouyuQrStatus.scanned;
      case -1:
        return DouyuQrStatus.expired;
      case 0:
        // Confirmation supplies a URL that sets the persistent passport cookie.
        final url = result['data']?['url'] as String?;
        if (url == null || url.isEmpty) {
          throw StateError('斗鱼未返回登录确认地址');
        }
        final confirmation = await _request(_passport.resolve(url),
            query: {'callback': 'appClient_json_callback'});
        if (confirmation['error'] != 0 || did.isEmpty || ltp0.isEmpty) {
          throw StateError('斗鱼未返回续期凭据，请刷新二维码重试');
        }
        _code = '';
        return DouyuQrStatus.authorized;
      default:
        throw StateError('斗鱼暂时无法确认登录，请刷新重试');
    }
  }

  Future<Map<String, dynamic>> _request(Uri uri,
      {Map<String, String>? query, Map<String, String>? data}) async {
    if (query != null) {
      uri = uri.replace(queryParameters: {...uri.queryParameters, ...query});
    }
    for (var redirects = 0; redirects < 5; redirects++) {
      if (uri.scheme != 'https' ||
          !(uri.host == 'douyu.com' || uri.host.endsWith('.douyu.com'))) {
        throw StateError('斗鱼登录地址无效');
      }
      final response = await _dio.requestUri<String>(uri,
          data: data,
          cancelToken: _cancel,
          options: Options(
            method: data == null ? 'GET' : 'POST',
            responseType: ResponseType.plain,
            contentType: Headers.formUrlEncodedContentType,
            followRedirects: false,
            validateStatus: (status) =>
                status != null && status >= 200 && status < 400,
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Referer': _passport.toString(),
              'Origin': 'https://passport.douyu.com',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                  'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Cookie': _cookies.values
                  .where((cookie) {
                    final domain = cookie.domain ?? uri.host;
                    return (uri.host == domain ||
                            uri.host.endsWith('.$domain')) &&
                        uri.path.startsWith(cookie.path ?? '/') &&
                        (cookie.expires == null ||
                            cookie.expires!.isAfter(DateTime.now()));
                  })
                  .map((cookie) => '${cookie.name}=${cookie.value}')
                  .join('; '),
            },
          ));
      for (final raw in response.headers['set-cookie'] ?? <String>[]) {
        final cookie = Cookie.fromSetCookieValue(raw);
        cookie.domain =
            (cookie.domain ?? uri.host).replaceFirst(RegExp(r'^\.'), '');
        if (uri.host != cookie.domain &&
            !uri.host.endsWith('.${cookie.domain}')) {
          continue;
        }
        cookie.path ??= '/';
        final key = '${cookie.domain}${cookie.path}|${cookie.name}';
        if (cookie.maxAge == 0 ||
            (cookie.expires != null &&
                !cookie.expires!.isAfter(DateTime.now()))) {
          _cookies.remove(key);
        } else {
          _cookies[key] = cookie;
        }
      }
      if ((response.statusCode ?? 200) >= 300) {
        final location = response.headers.value('location');
        if (location == null) throw StateError('斗鱼登录跳转失败');
        uri = uri.resolve(location);
        data = null;
        continue;
      }
      var text = (response.data ?? '').trim();
      if (!text.startsWith('{')) {
        final callback =
            RegExp(r'^[\w.$]+\s*\(([\s\S]*)\)\s*;?$').firstMatch(text);
        if (callback == null) throw StateError('斗鱼登录响应无效');
        text = callback.group(1)!;
      }
      return jsonDecode(text) as Map<String, dynamic>;
    }
    throw StateError('斗鱼登录跳转次数过多');
  }

  void close() {
    _cancel.cancel();
    _cookies.clear();
    _dio.close(force: true);
  }
}
