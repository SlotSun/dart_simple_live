import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:simple_live_core/src/common/http_client.dart';
import 'package:simple_live_core/src/platforms/douyu/douyu_utils.dart';

class DouyuSite implements LiveSite {
  @override
  String id = "douyu";

  @override
  String name = "斗鱼直播";

  String _cookie = '';

  String _dy_did = '';

  String _ltp0 = '';

  @override
  LiveDanmaku getDanmaku() => DouyuDanmaku();

  @override
  Future<List<LiveCategory>> getCategories() async {
    List<LiveCategory> categories = [];
    var result = await HttpClient.instance.getJson("https://m.douyu.com/api/cate/list");
    var subCateList = result["data"]["cate2Info"] as List;
    for (var item in result["data"]["cate1Info"]) {
      var cate1Id = item["cate1Id"];
      var cate1Name = item["cate1Name"];
      List<LiveSubCategory> subCategories = [];
      subCateList.where((x) => x["cate1Id"] == cate1Id).forEach((element) {
        subCategories.add(LiveSubCategory(
          pic: element["icon"],
          id: element["cate2Id"].toString(),
          parentId: cate1Id.toString(),
          name: element["cate2Name"].toString(),
        ));
      });
      categories.add(
        LiveCategory(
          id: cate1Id.toString(),
          name: cate1Name.toString(),
          children: subCategories,
        ),
      );
    }
    // 根据ID排序
    categories.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));

    return categories;
  }

  @override
  Future<LiveCategoryResult> getCategoryRooms(LiveSubCategory category, {int page = 1}) async {
    var result = await HttpClient.instance.getJson(
      "https://www.douyu.com/gapi/rkc/directory/mixList/2_${category.id}/$page",
      queryParameters: {},
    );

    var items = <LiveRoomItem>[];
    for (var item in result['data']['rl']) {
      if (item["type"] != 1) {
        continue;
      }
      var roomItem = LiveRoomItem(
        cover: item['rs16'].toString(),
        online: item['ol'],
        roomId: item['rid'].toString(),
        title: item['rn'].toString(),
        userName: item['nn'].toString(),
      );
      items.add(roomItem);
    }
    var hasMore = page < result['data']['pgcnt'];
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<List<LivePlayQuality>> getPlayQualities({required LiveRoomDetail detail}) async {
    var data = await DouyuUtils.sign(detail.roomId, cookie: _cookie);
    List<LivePlayQuality> qualities = [];
    var result = await HttpClient.instance.postJson(
      "https://www.douyu.com/lapi/live/getH5PlayV1/${detail.roomId}",
      data: data,
      formUrlEncoded: true,
      header: DouyuUtils.requestHeader(roomId: detail.roomId, cookie: _cookie),
    );

    var cdns = <String>[];
    for (var item in result["data"]["cdnsWithName"]) {
      cdns.add(item["cdn"].toString());
    }

    // 如果cdn以scdn开头，将其放到最后
    cdns.sort((a, b) {
      if (a.startsWith("scdn") && !b.startsWith("scdn")) {
        return 1;
      } else if (!a.startsWith("scdn") && b.startsWith("scdn")) {
        return -1;
      }
      return 0;
    });

    for (var item in result["data"]["multirates"]) {
      qualities.add(LivePlayQuality(
        quality: item["name"].toString(),
        data: DouyuPlayData(item["rate"], cdns),
      ));
    }
    return qualities;
  }

  @override
  Future<LivePlayUrl> getPlayUrls({required LiveRoomDetail detail, required LivePlayQuality quality}) async {
    var data = quality.data as DouyuPlayData;

    List<String> urls = [];
    for (var item in data.cdns) {
      var url = await getPlayUrl(detail.roomId, data.rate, item);
      if (url.isNotEmpty) {
        // if expire=300 and cdn is ws then add &expire=0
        // user must be live in oversea
        // cookie is better, cookie needs refreshed every 7 days
        if (url.contains('expire=300') && url.contains('fcdn=ws')) {
          url = '$url&expire=0';
        }
        urls.add(url);
      }
    }
    return LivePlayUrl(urls: urls);
  }

  Future<String> getPlayUrl(String roomId, int rate, String cdn) async {
    var sign = await DouyuUtils.sign(roomId, rate: rate, cdn: cdn, cookie: _cookie);
    var result = await HttpClient.instance.postJson(
      "https://www.douyu.com/lapi/live/getH5PlayV1/$roomId",
      data: sign,
      formUrlEncoded: true,
      header: DouyuUtils.requestHeader(roomId: roomId, cookie: _cookie),
    );

    return "${result["data"]["rtmp_url"]}/${HtmlUnescape().convert(result["data"]["rtmp_live"].toString())}";
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1}) async {
    var result = await HttpClient.instance.getJson(
      "https://www.douyu.com/japi/weblist/apinc/allpage/6/$page",
      queryParameters: {},
    );

    var items = <LiveRoomItem>[];
    for (var item in result['data']['rl']) {
      if (item["type"] != 1) {
        continue;
      }
      var roomItem = LiveRoomItem(
        cover: item['rs16'].toString(),
        online: item['ol'],
        roomId: item['rid'].toString(),
        title: item['rn'].toString(),
        userName: item['nn'].toString(),
      );
      items.add(roomItem);
    }
    var hasMore = page < result['data']['pgcnt'];
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveRoomDetail> getRoomDetail({required String roomId}) async {
    Map roomInfo = await _getRoomInfo(roomId);

    return LiveRoomDetail(
      cover: roomInfo["room_pic"].toString(),
      online: int.tryParse(roomInfo["room_biz_all"]["hot"].toString()) ?? 0,
      roomId: roomInfo["room_id"].toString(),
      title: roomInfo["room_name"].toString(),
      userName: roomInfo["owner_name"].toString(),
      userAvatar: roomInfo["owner_avatar"].toString(),
      introduction: roomInfo["show_details"].toString(),
      notice: "",
      status: roomInfo["show_status"] == 1 && roomInfo["videoLoop"] != 1 && !roomInfo["room_name"].startsWith("【回放】"),
      danmakuData: roomInfo["room_id"].toString(),
      data: "",
      url: "https://www.douyu.com/$roomId",
      isRecord: roomInfo["videoLoop"] == 1,
    );
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(String keyword, {int page = 1}) async {
    var did = generateRandomString(32);
    var result = await HttpClient.instance.getJson(
      "https://www.douyu.com/japi/search/api/searchShow",
      queryParameters: {
        "kw": keyword,
        "page": page,
        "pageSize": 20,
      },
      header: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.51',
        'referer': 'https://www.douyu.com/search/',
        'Cookie': 'dy_did=$did;acf_did=$did'
      },
    );
    if (result['error'] != 0) {
      throw Exception(result['msg']);
    }
    var items = <LiveRoomItem>[];
    for (var item in result["data"]["relateShow"]) {
      var roomItem = LiveRoomItem(
        roomId: item["rid"].toString(),
        title: item["roomName"].toString(),
        cover: item["roomSrc"].toString(),
        userName: item["nickName"].toString(),
        online: parseHotNum(item["hot"].toString()),
      );
      items.add(roomItem);
    }
    var hasMore = result["data"]["relateShow"].isNotEmpty;
    return LiveSearchRoomResult(hasMore: hasMore, items: items);
  }

  Future<Map> _getRoomInfo(String roomId) async {
    var result =
        await HttpClient.instance.getJson("https://www.douyu.com/betard/$roomId", queryParameters: {}, header: {
      'referer': 'https://www.douyu.com/$roomId',
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.43',
    });
    Map roomInfo;
    if (result is String) {
      roomInfo = json.decode(result)["room"];
    } else {
      roomInfo = result["room"];
    }
    return roomInfo;
  }

  //生成指定长度的16进制随机字符串
  String generateRandomString(int length) {
    var random = Random.secure();
    var values = List<int>.generate(length, (i) => random.nextInt(16));
    StringBuffer stringBuffer = StringBuffer();
    for (var item in values) {
      stringBuffer.write(item.toRadixString(16));
    }
    return stringBuffer.toString();
  }

  @override
  Future<LiveSearchAnchorResult> searchAnchors(String keyword, {int page = 1}) async {
    var did = generateRandomString(32);
    var result = await HttpClient.instance.getJson(
      "https://www.douyu.com/japi/search/api/searchUser",
      queryParameters: {
        "kw": keyword,
        "page": page,
        "pageSize": 20,
        "filterType": 1,
      },
      header: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.51',
        'referer': 'https://www.douyu.com/search/',
        'Cookie': 'dy_did=$did;acf_did=$did'
      },
    );

    var items = <LiveAnchorItem>[];
    for (var item in result["data"]["relateUser"]) {
      var liveStatus = (int.tryParse(item["anchorInfo"]["isLive"].toString()) ?? 0) == 1;
      var roomType = (int.tryParse(item["anchorInfo"]["roomType"].toString()) ?? 0);
      var roomItem = LiveAnchorItem(
        roomId: item["anchorInfo"]["rid"].toString(),
        avatar: item["anchorInfo"]["avatar"].toString(),
        userName: item["anchorInfo"]["nickName"].toString(),
        liveStatus: liveStatus && roomType == 0,
      );
      items.add(roomItem);
    }
    var hasMore = result["data"]["relateUser"].isNotEmpty;
    return LiveSearchAnchorResult(hasMore: hasMore, items: items);
  }

  @override
  Future<bool> getLiveStatus({required String roomId}) async {
    var roomInfo = await _getRoomInfo(roomId);
    return roomInfo["show_status"] == 1 && roomInfo["videoLoop"] != 1 && !roomInfo["room_name"].startsWith("【回放】");
  }

  int parseHotNum(String hn) {
    try {
      var num = double.parse(hn.replaceAll("万", ""));
      if (hn.contains("万")) {
        num *= 10000;
      }
      return num.round();
    } catch (_) {
      return -999;
    }
  }

  @override
  Future<List<LiveSuperChatMessage>> getSuperChatMessage({required String roomId}) {
    //尚不支持
    return Future.value([]);
  }

  Future<String> refreshCookie(String dy_did, String ltp0) async {
    var newCookie = await DouyuUtils.refreshCookie(did: dy_did, ltp0: ltp0, cookie: _cookie);
    _cookie = newCookie;
    return newCookie;
  }

  @override
  Future<void> setSiteAttrs(String data) async {
    final map = jsonDecode(data) as Map<String, dynamic>;
    if (map.containsKey('cookie')) {
      _cookie = map['cookie'] as String;
    }
    if (map.containsKey('dy_did')) {
      _dy_did = map['dy_did'] as String;
      DouyuUtils.setDyDid(_dy_did);
    }
    if (map.containsKey('LTP0')) {
      _ltp0 = map['LTP0'] as String;
    }
  }

  @override
  Future<AccountInfo> getAccountInfo({required String credential}) async {
    setSiteAttrs(credential);
    var newCookie = await DouyuUtils.refreshCookie(did: _dy_did, ltp0: _ltp0, cookie: _cookie);
    var newCredential = jsonDecode(credential) as Map<String, dynamic>;
    newCredential['cookie'] = newCookie;
    return AccountInfo(
      uid: DouyuUtils.pickCookie(newCookie, 'acf_uid'),
      name: Uri.decodeComponent(DouyuUtils.pickCookie(newCookie, 'acf_nickname')),
      avatar: '${Uri.decodeComponent(DouyuUtils.pickCookie(newCookie, 'acf_avatar'))}middle.jpg',
      credential: jsonEncode(newCredential),
      isValid: newCookie.isNotEmpty ? true : false,
    );
  }

  @override
  Future<QRCode> getQRCode() async {
    var didRes = await HttpClient.instance.getText(
      'https://passport.douyu.com/lapi/did/api/get',
      queryParameters: {'client_id': '1', 'callback': 'cb'},
      header: DouyuUtils.requestHeader(isLogin: true),
    );
    var text = (didRes).trim();
    if (text.isNotEmpty && !text.startsWith('{')) {
      final start = text.indexOf('(');
      final end = text.lastIndexOf(')');
      if (start != -1 && end > start) {
        text = text.substring(start + 1, end).trim();
      }
    }
    _dy_did = (jsonDecode(text) as Map<String, dynamic>)['data']['did'] ?? '10000000000000000000000000001501';
    DouyuUtils.setDyDid(_dy_did);
    var result = await HttpClient.instance.postJson(
      'https://passport.douyu.com/scan/generateCode',
      data: {'client_id': '1', 'isMultiAccount': '0'},
      formUrlEncoded: true,
      header: DouyuUtils.requestHeader(isLogin: true),
    );
    if (result["error"] != 0) {
      throw result["data"];
    }
    QRCode qrCode = QRCode(
      expireAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300,
      key: result["data"]["code"],
      url: result["data"]["url"],
    );
    return qrCode;
  }

  @override
  Future<QRPollResult> getQRPollResult({required String qrcodeKey}) async {
    var pollHeader = DouyuUtils.requestHeader(isLogin: true);
    pollHeader['X-Requested-With'] = 'XMLHttpRequest';
    var resp = await HttpClient.instance.getResponse(
      'https://passport.douyu.com/japi/scan/auth',
      responseType: ResponseType.json,
      queryParameters: {
        'code': qrcodeKey,
        'time': DateTime.now().millisecondsSinceEpoch.toString(),
      },
      header: pollHeader,
    );
    QRPollResult qrPollResult = QRPollResult(status: QRStatus.failed);
    var resData = resp.data;
    switch (resData['error']) {
      case -2:
        qrPollResult.status = QRStatus.unscanned;
        qrPollResult.message = resData['msg'];
      case 1:
        qrPollResult.status = QRStatus.scanned;
        qrPollResult.message = resData['msg'];
      case -1:
        qrPollResult.status = QRStatus.expired;
        qrPollResult.message = resData['msg'];
      case 0:
        final url = resData['data']?['url'] as String?;
        if (url == null || url.isEmpty) {
          throw StateError('斗鱼未返回登录确认地址');
        }
        // 这里就会下发 set-cookie lip0 通过 refreshCookie获取最新cookie
        // cookie-jar maybe better
        var pollCookie = resp.headers['set-cookie']!;
        final ltp0 = DouyuUtils.pickSetCookie(pollCookie, 'LTP0');
        var newCookie = await DouyuUtils.refreshCookie(did: _dy_did, ltp0: ltp0, cookie: _cookie);
        // 拼装一下
        final Map<String, dynamic> credentialJson = {'dy_did': _dy_did, 'LTP0': ltp0, 'cookie': newCookie};
        qrPollResult.credential = jsonEncode(credentialJson);
        qrPollResult.status = QRStatus.scanned;
      default:
        throw StateError('斗鱼暂时无法确认登录，请刷新重试');
    }
    return qrPollResult;
  }
}

class DouyuPlayData {
  final int rate;
  final List<String> cdns;

  DouyuPlayData(this.rate, this.cdns);
}
