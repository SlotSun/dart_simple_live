import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:simple_live_core/src/common/http_client.dart' as core_http;
import 'package:simple_live_core/src/platforms/douyu/douyu_utils.dart';
import 'package:simple_live_tv_app/services/douyu_account_service.dart';
import 'package:simple_live_tv_app/services/local_storage_service.dart';

class FakeTransport implements HttpClientAdapter {
  FakeTransport(this.handle);
  final FutureOr<ResponseBody> Function(RequestOptions) handle;
  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      handle(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object data, {Map<String, List<String>>? headers}) =>
    ResponseBody.fromString(jsonEncode(data), 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
      ...?headers
    });

String validCookie() {
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({
        'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 604800,
      })))
      .replaceAll('=', '');
  return 'acf_jwt_token=e30.$payload.fake-test-signature';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => CoreLog.enableLog = false);

  test('passport refresh does not log credentials in verbose HTTP mode',
      () async {
    final client = core_http.HttpClient.instance.dio;
    final originalAdapter = client.httpClientAdapter;
    final originalPrint = CoreLog.onPrintLog;
    final originalLogType = CoreLog.requestLogType;
    final messages = <String>[];
    CoreLog.enableLog = true;
    CoreLog.requestLogType = RequestLogType.all;
    CoreLog.onPrintLog = (_, message) => messages.add(message);
    addTearDown(() {
      client.httpClientAdapter = originalAdapter;
      CoreLog.onPrintLog = originalPrint;
      CoreLog.requestLogType = originalLogType;
      CoreLog.enableLog = false;
    });
    client.httpClientAdapter = FakeTransport((_) => jsonResponse({
          'error': 0
        }, headers: {
          'set-cookie': ['${validCookie()}; Path=/']
        }));
    expect(await DouyuUtils.refreshCookie(did: 'device', ltp0: 'secret-token'),
        contains('acf_jwt_token='));
    expect(messages, isEmpty);
    client.httpClientAdapter = FakeTransport((request) {
      throw DioException(requestOptions: request, error: 'secret-token');
    });
    await expectLater(
        DouyuUtils.refreshCookie(did: 'device', ltp0: 'secret-token'),
        throwsA(anything));
    expect(messages, isEmpty);
  });

  test('official QR flow captures HttpOnly LTP0 after phone confirmation',
      () async {
    var polls = 0;
    final dio = Dio()
      ..httpClientAdapter = FakeTransport((request) {
        switch (request.uri.path) {
          case '/lapi/did/api/get':
            return ResponseBody.fromString(
                'slive_did({"error":0,"data":{"did":"device-id"}});', 200);
          case '/scan/generateCode':
            expect(request.headers['Cookie'], contains('dy_did=device-id'));
            return jsonResponse({
              'error': 0,
              'data': {
                'code': 'qr-session',
                'url': 'https://m.douyu.com/test-qr'
              }
            });
          case '/japi/scan/auth':
            polls++;
            if (polls == 1) return jsonResponse({'error': -2});
            if (polls == 2) return jsonResponse({'error': 1});
            return jsonResponse({
              'error': 0,
              'data': {'url': 'https://passport.douyu.com/confirm'}
            });
          case '/confirm':
            return ResponseBody.fromString(
                'appClient_json_callback({"error":0});', 200,
                headers: {
                  'set-cookie': [
                    'LTP0=persistent-test-token; Domain=.passport.douyu.com; Path=/; Secure; HttpOnly'
                  ]
                });
          default:
            throw StateError('Unexpected request');
        }
      });
    final session = DouyuQrLogin(dio: dio);
    expect(await session.generate(), 'https://m.douyu.com/test-qr');
    expect(await session.poll(), DouyuQrStatus.waiting);
    expect(await session.poll(), DouyuQrStatus.scanned);
    expect(await session.poll(), DouyuQrStatus.authorized);
    expect(session.did, 'device-id');
    expect(session.ltp0, 'persistent-test-token');
    session.close();
  });

  test('expired QR cannot complete login', () async {
    final dio = Dio()
      ..httpClientAdapter = FakeTransport((request) {
        if (request.uri.path.contains('/did/'))
          return jsonResponse({'error': 2});
        if (request.uri.path.endsWith('generateCode')) {
          return jsonResponse({
            'error': 0,
            'data': {'code': 'expired', 'url': 'https://m.douyu.com/qr'}
          });
        }
        return jsonResponse({'error': -1});
      });
    final session = DouyuQrLogin(dio: dio);
    await session.generate();
    expect(await session.poll(), DouyuQrStatus.expired);
    expect(session.ltp0, isEmpty);
    session.close();
  });

  test(
      'refresh failure retains existing cookie; logout invalidates in-flight refresh',
      () async {
    final client = core_http.HttpClient.instance.dio;
    final originalAdapter = client.httpClientAdapter;
    addTearDown(() => client.httpClientAdapter = originalAdapter);
    client.httpClientAdapter = FakeTransport((_) => jsonResponse({'error': 1}));
    const oldCookie = 'acf_jwt_token=expired';
    final site = DouyuSite();
    await site.setSiteAttrs({'cookie': oldCookie});
    expect(await site.refreshCookie('device', 'token'), oldCookie);
    final reply = Completer<ResponseBody>();
    final started = Completer<void>();
    client.httpClientAdapter = FakeTransport((_) {
      started.complete();
      return reply.future;
    });
    final pending = site.refreshCookie('device', 'token');
    await started.future;
    await site.setSiteAttrs({'cookie': '', 'dy_did': '', 'ltp0': ''});
    reply.complete(jsonResponse({
      'error': 0
    }, headers: {
      'set-cookie': ['${validCookie()}; Path=/']
    }));
    expect(await pending, isEmpty);
  });

  test('TV passport credentials survive restart and are removed by logout',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('slive-douyu-test-');
    Hive.init(directory.path);
    final client = core_http.HttpClient.instance.dio;
    final originalAdapter = client.httpClientAdapter;
    client.httpClientAdapter = FakeTransport((request) {
      expect(request.headers['cookie'], contains('LTP0=long-lived-token'));
      return jsonResponse({
        'error': 0
      }, headers: {
        'set-cookie': ['${validCookie()}; Path=/']
      });
    });
    try {
      final storage = Get.put(LocalStorageService());
      await storage.init();
      var account = Get.put(DouyuAccountService());
      expect(
          await account.loginWithPassport(
              'persistent-device', 'long-lived-token'),
          isTrue);
      await Hive.close();
      Get.reset();
      final reopened = Get.put(LocalStorageService());
      await reopened.init();
      account = Get.put(DouyuAccountService());
      expect(account.did, 'persistent-device');
      expect(account.ltp0, 'long-lived-token');
      expect(DouyuUtils.isCookieExpired(account.cookie.value), isFalse);
      await account.logout();
      expect(reopened.getValue(LocalStorageService.kDouyuLtp0, ''), isEmpty);
      expect(reopened.getValue(LocalStorageService.kDouyuCookie, ''), isEmpty);
    } finally {
      client.httpClientAdapter = originalAdapter;
      await Hive.close();
      Get.reset();
      expect(directory.absolute.path,
          startsWith(Directory.systemTemp.absolute.path));
      await directory.delete(recursive: true);
    }
  });
}
