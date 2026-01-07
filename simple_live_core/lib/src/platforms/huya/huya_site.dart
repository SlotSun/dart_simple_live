import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:simple_live_core/src/common/http_client.dart';
import 'package:simple_live_core/src/model/tars/get_cdn_token_ex_req.dart';
import 'package:simple_live_core/src/model/tars/get_cdn_token_ex_resp.dart';
import 'package:simple_live_core/src/model/tars/types.dart';
import 'package:simple_live_core/src/platforms/huya/utils.dart';
import 'package:tars_dart/tars/net/base_tars_http.dart';

class HuyaSite implements LiveSite {
  static const String baseUrl = "https://www.huya.com";
  static const String wupUrl = "http://wup.huya.com";
  static const String kUserAgent =
      "Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.91 Mobile Safari/537.36 Edg/117.0.0.0";

  // regex
  /// 匹配房间数据
  static const String ROOM_DATA_REGEX =
      r'var\s+TT_ROOM_DATA\s*=\s*(\{[\s\S]*?\})';

  /// 匹配流数据
  static const String STREAM_REGEX = r"stream:\s*(\{[\s\S]*?\n\s*\})";

  /// 匹配 YY ID
  static const String AYYUID_REGEX = r'"yyid":"?(\d+)"?';

  static const String HYSDK_UA =
      "HYSDK(Windows, 30000002)_APP(pc_exe&7060000&official)_SDK(trans&2.32.3.5646)";

  static Map<String, String> get requestHeaders {
    return {
      'Origin': baseUrl,
      'Referer': baseUrl,
      'User-Agent': HYSDK_UA,
    };
  }

  final BaseTarsHttp tupClient =
      BaseTarsHttp("http://wup.huya.com", "liveui", headers: requestHeaders);


  @override
  String id = "huya";

  @override
  String name = "虎牙直播";

  @override
  LiveDanmaku getDanmaku() => HuyaDanmaku();

  @override
  Future<List<LiveCategory>> getCategores() async {
    List<LiveCategory> categories = [
      LiveCategory(id: "1", name: "网游", children: []),
      LiveCategory(id: "2", name: "单机", children: []),
      LiveCategory(id: "8", name: "娱乐", children: []),
      LiveCategory(id: "3", name: "手游", children: []),
    ];

    for (var item in categories) {
      var items = await getSubCategores(item.id);
      item.children.addAll(items);
    }
    return categories;
  }

  Future<List<LiveSubCategory>> getSubCategores(String id) async {
    var result = await HttpClient.instance.getJson(
      "https://live.cdn.huya.com/liveconfig/game/bussLive",
      queryParameters: {
        "bussType": id,
      },
    );

    List<LiveSubCategory> subs = [];
    for (var item in result["data"]) {
      var gid = "";

      if (item["gid"] is Map) {
        gid = item["gid"]["value"].toString().split(",").first;
      } else if (item["gid"] is double) {
        gid = item["gid"].toInt().toString();
      } else if (item["gid"] is int) {
        gid = item["gid"].toString();
      } else {
        gid = item["gid"].toString();
      }

      var subCategory = LiveSubCategory(
        id: gid,
        name: item["gameFullName"].toString(),
        parentId: id,
        pic: "https://huyaimg.msstatic.com/cdnimage/game/$gid-MS.jpg",
      );
      subs.add(subCategory);
    }

    return subs;
  }

  @override
  Future<LiveCategoryResult> getCategoryRooms(LiveSubCategory category,
      {int page = 1}) async {
    var resultText = await HttpClient.instance.getJson(
      "https://www.huya.com/cache.php",
      queryParameters: {
        "m": "LiveList",
        "do": "getLiveListByPage",
        "tagAll": 0,
        "gameId": category.id,
        "page": page
      },
    );
    var result = json.decode(resultText);
    var items = <LiveRoomItem>[];
    for (var item in result["data"]["datas"]) {
      var cover = item["screenshot"].toString();
      if (!cover.contains("?")) {
        cover += "?x-oss-process=style/w338_h190&";
      }
      var title = item["introduction"]?.toString() ?? "";
      if (title.isEmpty) {
        title = item["roomName"]?.toString() ?? "";
      }

      var roomItem = LiveRoomItem(
        roomId: item["profileRoom"].toString(),
        title: title,
        cover: cover,
        userName: item["nick"].toString(),
        online: int.tryParse(item["totalCount"].toString()) ?? 0,
      );
      items.add(roomItem);
    }
    var hasMore = result["data"]["page"] < result["data"]["totalPage"];
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<List<LivePlayQuality>> getPlayQualites(
      {required LiveRoomDetail detail}) {
    List<LivePlayQuality> qualities = <LivePlayQuality>[];
    var urlData = detail.data as HuyaUrlDataModel;
    if (urlData.bitRates.isEmpty) {
      urlData.bitRates = [
        HuyaBitRateModel(
          name: "原画",
          bitRate: 0,
        ),
        HuyaBitRateModel(name: "高清", bitRate: 2000),
      ];
    }

    for (var item in urlData.bitRates) {
      qualities.add(LivePlayQuality(
        data: {
          "urls": urlData.lines,
          "bitRate": item.bitRate,
        },
        quality: item.name,
      ));
    }

    return Future.value(qualities);
  }

  @override
  Future<LivePlayUrl> getPlayUrls(
      {required LiveRoomDetail detail,
      required LivePlayQuality quality}) async {
    var ls = <String>[];
    for (var element in quality.data["urls"]) {
      var line = element as HuyaLineModel;
      var url = await getPlayUrl(line, quality.data["bitRate"]);
      ls.add(url);
    }
    return LivePlayUrl(
      urls: ls,
      headers: {"user-agent": HYSDK_UA},
    );
  }

  Future<String> getPlayUrl(HuyaLineModel line, int bitRate) async {
    var suffix = line.lineType == HuyaLineType.hls ? "m3u8" : "flv";
    var antiCode = await getCndTokenInfoEx(line.streamName);
    antiCode = buildAntiCode(line.streamName, line.presenterUid, antiCode);
    var url = '${line.line}/${line.streamName}.$suffix?$antiCode&codec=264';
    if (bitRate > 0) {
      url += "&ratio=$bitRate";
    }
    return url;
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1}) async {
    var resultText = await HttpClient.instance.getJson(
      "https://www.huya.com/cache.php",
      queryParameters: {
        "m": "LiveList",
        "do": "getLiveListByPage",
        "tagAll": 0,
        "page": page
      },
    );
    var result = json.decode(resultText);
    var items = <LiveRoomItem>[];
    for (var item in result["data"]["datas"]) {
      var cover = item["screenshot"].toString();
      if (!cover.contains("?")) {
        cover += "?x-oss-process=style/w338_h190&";
      }
      var title = item["introduction"]?.toString() ?? "";
      if (title.isEmpty) {
        title = item["roomName"]?.toString() ?? "";
      }

      var roomItem = LiveRoomItem(
        roomId: item["profileRoom"].toString(),
        title: title,
        cover: cover,
        userName: item["nick"].toString(),
        online: int.tryParse(item["totalCount"].toString()) ?? 0,
      );
      items.add(roomItem);
    }
    var hasMore = result["data"]["page"] < result["data"]["totalPage"];
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveRoomDetail> getRoomDetail({required String roomId}) async {
    late LiveRoomDetail result;
    var resultText = await HttpClient.instance.getText(
      "$baseUrl/$roomId",
      queryParameters: {},
      header: requestHeaders,
    );
    // get_live_status
    var roomData = RegExp(ROOM_DATA_REGEX, multiLine: false)
        .firstMatch(resultText)
        ?.group(0)
        ?.replaceAll("var TT_ROOM_DATA = ", "");
    var streamData = RegExp(STREAM_REGEX)
            .firstMatch(resultText)
            ?.group(0)
            ?.replaceAll("stream: ", "")
            .split('\n')[0] ??
        '""';
    if (roomData != null) {
      try {
        Map<String, dynamic> roomDataJson = json.decode(roomData);
        Map<String, dynamic> streamJson = json.decode(streamData);
        var streamDataJson = streamJson["data"][0];
        var streamDataGameLiveInfo = streamDataJson["gameLiveInfo"];
        result = LiveRoomDetail(
          roomId: roomId,
          title: streamDataGameLiveInfo["introduction"],
          cover: streamDataGameLiveInfo["screenshot"],
          userName: streamDataGameLiveInfo["nick"],
          userAvatar: streamDataGameLiveInfo["avatar180"],
          online: streamDataGameLiveInfo["totalCount"],
          status: roomDataJson["state"] == "ON" &&
              roomDataJson["isReplay"] == false,
          url: "https://www.huya.com/$roomId",
          introduction: streamDataGameLiveInfo["introduction"],
          notice: streamDataGameLiveInfo["introduction"],
          isRecord: roomDataJson["isReplay"],
        );
        // live -> add HuyaUrlDataModel and danmaku
        if (result.status) {
          var streamDataGameStreamInfo =
              streamDataJson["gameStreamInfoList"][0];
          // danmaku
          // maybe int or string don't know why
          var topSid =
              int.tryParse(streamDataGameStreamInfo["lChannelId"].toString());
          var subSid = int.tryParse(
              streamDataGameStreamInfo["lSubChannelId"].toString());
          var yySid = int.tryParse(streamDataGameLiveInfo["yyid"].toString());
          result = result.updateDanmakuData(
            HuyaDanmakuArgs(
              ayyuid: yySid ?? 0,
              topSid: topSid ?? 0,
              subSid: subSid ?? 0,
            ),
          );

          // HuyaUrlDataModel
          var huyaLines = <HuyaLineModel>[];
          var huyaBiterates = <HuyaBitRateModel>[];
          final lineTypes = {
            'sFlvUrl': HuyaLineType.flv,
            'sHlsUrl': HuyaLineType.hls,
          };
          //读取可用线路
          var lines = streamDataJson["gameStreamInfoList"];
          for (var item in lines) {
            lineTypes.forEach((key, type) {
              final url = item[key]?.toString() ?? "";
              if (url.isNotEmpty) {
                huyaLines.add(
                  HuyaLineModel(
                    line: url,
                    lineType: type,
                    flvAntiCode: item["sFlvAntiCode"].toString(),
                    hlsAntiCode: item["sHlsAntiCode"].toString(),
                    streamName: item["sStreamName"].toString(),
                    cdnType: item["sCdnType"].toString(),
                    presenterUid: topSid ?? 0,
                  ),
                );
              }
            });
          }
          //清晰度
          var biterates = streamJson["vMultiStreamInfo"];
          for (var item in biterates) {
            var name = item["sDisplayName"].toString();
            if (name.contains("HDR")) {
              continue;
            }
            huyaBiterates.add(HuyaBitRateModel(
              bitRate: item["iBitRate"],
              name: name,
            ));
          }
          result = result.updateData(
            HuyaUrlDataModel(
              url: "huya need rebuild new url",
              lines: huyaLines,
              bitRates: huyaBiterates,
              uid: getUid(t: 13, e: 10),
            ),
          );
        }
      } catch (e) {
        CoreLog.error('JSON 解析失败: $e');
        CoreLog.error('原始字符串: $roomData');
      }
    }

    return result;
  }

  // 构造 anticode, python转写
  /// [stream] streamname [presenterUid] 用户id [antiCode] 页面anti
  ///
  /// return ture anticode
  String buildAntiCode(String stream, int presenterUid, String antiCode) {
    var mapAnti = Uri(query: antiCode).queryParametersAll;
    if (!mapAnti.containsKey("fm")) {
      return antiCode;
    }

    var ctype = mapAnti["ctype"]?.first ?? "huya_pc_exe";
    var platformId = int.tryParse(mapAnti["t"]?.first ?? "0");

    bool isWap = platformId == 103;
    var clacStartTime = DateTime.now().millisecondsSinceEpoch;

    CoreLog.i(
        "using $presenterUid | ctype-{$ctype} | platformId - {$platformId} | isWap - {$isWap} | $clacStartTime");

    var seqId = presenterUid + clacStartTime;
    final secretHash =
        md5.convert(utf8.encode('$seqId|$ctype|$platformId')).toString();

    final convertUid = rotl64(presenterUid);
    final calcUid = isWap ? presenterUid : convertUid;
    final fm = Uri.decodeComponent(mapAnti['fm']!.first);
    final secretPrefix = utf8.decode(base64.decode(fm)).split('_').first;
    var wsTime = mapAnti['wsTime']!.first;
    final secretStr =
        '${secretPrefix}_${calcUid}_${stream}_${secretHash}_$wsTime';

    final wsSecret = md5.convert(utf8.encode(secretStr)).toString();

    final rnd = Random();
    final ct =
        ((int.parse(wsTime, radix: 16) + rnd.nextDouble()) * 1000).toInt();
    final uuid = (((ct % 1e10) + rnd.nextDouble()) * 1e3 % 0xffffffff)
        .toInt()
        .toString();
    final Map<String, dynamic> antiCodeRes = {
      'wsSecret': wsSecret,
      'wsTime': wsTime,
      'seqid': seqId,
      'ctype': ctype,
      'ver': '1',
      'fs': mapAnti['fs']!.first,
      'fm': fm,
      't': platformId,
    };
    if (isWap) {
      antiCodeRes.addAll({
        'uid': presenterUid,
        'uuid': uuid,
      });
    } else {
      antiCodeRes['u'] = convertUid;
    }

    return antiCodeRes.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  /// return sFlvToken
  Future<String> getCndTokenInfoEx(String stream) async {
    var func = "getCdnTokenInfoEx";
    var tid = HuyaUserId();
    tid.sHuYaUA = "pc_exe&7060000&official";
    var tReq = GetCdnTokenExReq();
    tReq.tId = tid;
    tReq.sStreamName = stream;
    var resp = await tupClient.tupRequest(func, tReq, GetCdnTokenExResp());
    return resp.sFlvToken;
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(String keyword,
      {int page = 1}) async {
    var resultText = await HttpClient.instance.getJson(
      "https://search.cdn.huya.com/",
      queryParameters: {
        "m": "Search",
        "do": "getSearchContent",
        "q": keyword,
        "uid": 0,
        "v": 4,
        "typ": -5,
        "livestate": 0,
        "rows": 20,
        "start": (page - 1) * 20,
      },
    );
    var result = json.decode(resultText);
    var items = <LiveRoomItem>[];
    for (var item in result["response"]["3"]["docs"]) {
      var cover = item["game_screenshot"].toString();
      if (!cover.contains("?")) {
        cover += "?x-oss-process=style/w338_h190&";
      }

      var title = item["game_introduction"]?.toString() ?? "";
      if (title.isEmpty) {
        title = item["game_roomName"]?.toString() ?? "";
      }

      var roomItem = LiveRoomItem(
        roomId: item["room_id"].toString(),
        title: title,
        cover: cover,
        userName: item["game_nick"].toString(),
        online: int.tryParse(item["game_total_count"].toString()) ?? 0,
      );
      items.add(roomItem);
    }
    var hasMore = result["response"]["3"]["numFound"] > (page * 20);
    return LiveSearchRoomResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveSearchAnchorResult> searchAnchors(String keyword,
      {int page = 1}) async {
    var resultText = await HttpClient.instance.getJson(
      "https://search.cdn.huya.com/",
      queryParameters: {
        "m": "Search",
        "do": "getSearchContent",
        "q": keyword,
        "uid": 0,
        "v": 1,
        "typ": -5,
        "livestate": 0,
        "rows": 20,
        "start": (page - 1) * 20,
      },
    );
    var result = json.decode(resultText);
    var items = <LiveAnchorItem>[];
    for (var item in result["response"]["1"]["docs"]) {
      var anchorItem = LiveAnchorItem(
        roomId: item["room_id"].toString(),
        avatar: item["game_avatarUrl180"].toString(),
        userName: item["game_nick"].toString(),
        liveStatus: item["gameLiveOn"],
      );
      items.add(anchorItem);
    }
    var hasMore = result["response"]["1"]["numFound"] > (page * 20);
    return LiveSearchAnchorResult(hasMore: hasMore, items: items);
  }

  @override
  Future<bool> getLiveStatus({required String roomId}) async {
    var resultText = await HttpClient.instance.getText(
      "$baseUrl/$roomId",
      queryParameters: {},
      header: requestHeaders,
    );
    var jsonString = RegExp(ROOM_DATA_REGEX, multiLine: false)
        .firstMatch(resultText)
        ?.group(0)
        ?.replaceAll("var TT_ROOM_DATA = ", "");
    if (jsonString != null) {
      try {
        Map<String, dynamic> roomData = json.decode(jsonString);
        return roomData["state"] == "ON" && roomData["isReplay"] == false;
      } catch (e) {
        CoreLog.error('JSON 解析失败: $e');
        CoreLog.error('原始字符串: $jsonString');
      }
    }
    return false;
  }
  
  /// 匿名登录获取uid
  Future<String> getAnonymousUid() async {
    var result = await HttpClient.instance.postJson(
      "https://udblgn.huya.com/web/anonymousLogin",
      data: {
        "appId": 5002,
        "byPass": 3,
        "context": "",
        "version": "2.4",
        "data": {}
      },
      header: {
        "user-agent": kUserAgent,
      },
    );
    return result["data"]["uid"].toString();
  }

  String getUUid() {
    var currentTime = DateTime.now().millisecondsSinceEpoch;
    var randomValue = Random().nextInt(4294967295);
    var result = (currentTime % 10000000000 * 1000 + randomValue) % 4294967295;
    return result.toString();
  }

  String getUid({int? t, int? e}) {
    var n = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
        .split("");
    var o = List.filled(36, '');
    if (t != null) {
      for (var i = 0; i < t; i++) {
        o[i] = n[Random().nextInt(e ?? n.length)];
      }
    } else {
      o[8] = o[13] = o[18] = o[23] = "-";
      o[14] = "4";
      for (var i = 0; i < 36; i++) {
        if (o[i].isEmpty) {
          var r = Random().nextInt(16);
          o[i] = n[19 == i ? 3 & r | 8 : r];
        }
      }
    }
    return o.join("");
  }

  @override
  Future<List<LiveSuperChatMessage>> getSuperChatMessage(
      {required String roomId}) {
    //尚不支持
    return Future.value([]);
  }
}

class HuyaUrlDataModel {
  final String url;
  final String uid;
  List<HuyaLineModel> lines;
  List<HuyaBitRateModel> bitRates;

  HuyaUrlDataModel({
    required this.bitRates,
    required this.lines,
    required this.url,
    required this.uid,
  });

  @override
  String toString() {
    return json.encode({
      "url": url,
      "uid": uid,
      "lines": lines.map((e) => e.toString()).toList(),
      "bitRates": bitRates.map((e) => e.toString()).toList(),
    });
  }
}

enum HuyaLineType {
  flv,
  hls,
}

class HuyaLineModel {
  final String line;
  final String cdnType;
  final String flvAntiCode;
  final String hlsAntiCode;
  final String streamName;
  final HuyaLineType lineType;
  int bitRate;
  final int presenterUid;

  HuyaLineModel({
    required this.line,
    required this.lineType,
    required this.flvAntiCode,
    required this.hlsAntiCode,
    required this.streamName,
    required this.cdnType,
    this.bitRate = 0,
    required this.presenterUid,
  });

  @override
  String toString() {
    return json.encode({
      "line": line,
      "cdnType": cdnType,
      "flvAntiCode": flvAntiCode,
      "hlsAntiCode": hlsAntiCode,
      "streamName": streamName,
      "lineType": lineType.toString(),
      "presenterUid": presenterUid,
    });
  }
}

class HuyaBitRateModel {
  final String name;
  final int bitRate;

  HuyaBitRateModel({
    required this.bitRate,
    required this.name,
  });

  @override
  String toString() {
    return json.encode({
      "name": name,
      "bitRate": bitRate,
    });
  }
}
