import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:simple_live_app/services/local_storage_service.dart';
import 'package:simple_live_app/services/platform_service.dart';
import 'package:simple_live_core/src/common/http_client.dart' as core_http;

class PassportTransport implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
      RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    expect(options.headers['cookie'], contains('LTP0=mobile-renewal-token'));
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({
          'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 604800,
        })))
        .replaceAll('=', '');
    return ResponseBody.fromString('{"error":0}', 200, headers: {
      'set-cookie': ['acf_jwt_token=e30.$payload.test-signature; Path=/'],
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('mobile saved LTP0 is restored and cleared with the playback cookie', () async {
    final directory = await Directory.systemTemp.createTemp('slive-mobile-douyu-');
    Hive.init(directory.path);
    final client = core_http.HttpClient.instance.dio;
    final previousAdapter = client.httpClientAdapter;
    client.httpClientAdapter = PassportTransport();
    try {
      final storage = Get.put(LocalStorageService());
      await storage.init();
      var service = Get.put(PlatformService());
      expect(await service.loginDouyuWithPassport('mobile-device', 'mobile-renewal-token'), isTrue);
      await Hive.close();
      Get.reset();
      final reopened = Get.put(LocalStorageService());
      await reopened.init();
      service = Get.put(PlatformService());
      expect(service.dyLtp0, 'mobile-renewal-token');
      expect(service.dy_did, 'mobile-device');
      expect(service.douyuCookie.value, contains('acf_jwt_token='));
      await service.douyuLogout();
      await reopened.flush();
      expect(reopened.getValue(LocalStorageService.kDouyuLTP0, ''), isEmpty);
      expect(reopened.getValue(LocalStorageService.kDouyuCookie, ''), isEmpty);
    } finally {
      client.httpClientAdapter = previousAdapter;
      await Hive.close();
      Get.reset();
      expect(directory.absolute.path, startsWith(Directory.systemTemp.absolute.path));
      await directory.delete(recursive: true);
    }
  });
}
