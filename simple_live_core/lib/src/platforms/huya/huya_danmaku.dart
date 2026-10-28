import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:simple_live_core/simple_live_core.dart';
import 'package:simple_live_core/src/common/web_socket_util.dart';
import 'package:simple_live_core/src/platforms/huya/model/huya_damaku_model.dart';
import 'package:simple_live_core/src/platforms/huya/tars/huya_danmaku.dart';
import 'package:simple_live_core/src/platforms/huya/tars/types.dart';
import 'package:tars_dart/tars/codec/tars_input_stream.dart';
import 'package:tars_dart/tars/codec/tars_output_stream.dart';

import 'huya_utils.dart';

part 'huya_emoticon.dart';

class HuyaDanmakuArgs {
  final int ayyuid;
  final int topSid;
  final int subSid;

  HuyaDanmakuArgs({
    required this.ayyuid,
    required this.topSid,
    required this.subSid,
  });

  @override
  String toString() {
    return json.encode({
      "ayyuid": ayyuid,
      "topSid": topSid,
      "subSid": subSid,
    });
  }
}

class HuyaDanmaku implements LiveDanmaku {
  String get dHuyaUa {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final now = DateTime.now();
    return "webh5&${(now.year % 100).toString().padLeft(2, '0')}${twoDigits(now.month)}${twoDigits(now.day)}${twoDigits(now.hour)}${twoDigits(now.minute)}&websocket";
  }

  String device = "chrome";
  @override
  int heartbeatTime = 60 * 1000;

  @override
  Function(LiveMessage msg)? onMessage;
  @override
  Function(String msg)? onClose;
  @override
  Function()? onReady;
  String serverUrl = "wss://cdnws.api.huya.com:443";

  WebScoketUtils? webScoketUtils;

  List<int> get heartbeatData {
    var cmd = WebSocketCommand()
      ..cmdType = EWebSocketCommandType.EWSCmdC2S_HeartBeatReq.value
      ..data = TarsOutputStream().toUint8List();
    return cmd.toByteArray();
  }

  late HuyaDanmakuArgs danmakuArgs;

  @override
  Future start(dynamic args) async {
    danmakuArgs = args as HuyaDanmakuArgs;
    webScoketUtils = WebScoketUtils(
      url: serverUrl,
      heartBeatTime: heartbeatTime,
      onMessage: (e) {
        decodeMessage(e);
      },
      onReady: () {
        onReady?.call();
        // 这里开始握手
        joinRoom();
      },
      onHeartBeat: () {
        heartbeat();
      },
      onReconnect: () {
        onClose?.call("与服务器断开连接，正在尝试重连");
      },
      onClose: (e) {
        onClose?.call("服务器连接失败$e");
      },
    );
    webScoketUtils?.connect();
  }

  // 业务流程
  // handshake:
  // 1. send live_info-> build_live_info_data
  // 2. send do_launch-> build_do_launch_data
  // 3. send join_groud-> build_join_group_data // vp.js
  // 解码：
  //  WupReq_14: Uri_1400->message
  //  PushMessage_22:iUri_2001314 -> sc
  List<int> buildJoinGroupData({required int pid}) {
    WsRegisterGroupReq wsReq = WsRegisterGroupReq()
      ..groupId = ["live:$pid", "chat:$pid"]
      ..token = "";
    var wsReqByte = wsReq.toByteArray();
    var socketCmd = WebSocketCommand()
      ..cmdType = 16 // RegisterGroupReq
      ..data = wsReqByte;
    return socketCmd.toByteArray();
  }

  // wup
  List<int> buildLiveInfoData({required int pid, required String ua, required String device}) {
    HuyaUserId userId = HuyaUserId()
      ..lUid = 0
      ..sGuid = "0a7d4b0826af6c69380199dc9adc6b50"
      ..sToken = ""
      ..sHuYaUA = ua
      ..sDeviceInfo = device;
    var req = GetLivingInfoReq()
      ..lPresenterUid = pid
      ..tId = userId;
    var wupData = sendWupData(
      servantName: "huyaliveui",
      funcName: "getLivingInfo",
      req: req,
    );
    return wupData;
  }

  List<int> buildDoLaunchData({required String ua, required String device}) {
    HuyaUserId userId = HuyaUserId()
      ..lUid = 0
      ..sGuid = ""
      ..sToken = ""
      ..sHuYaUA = ua
      ..sDeviceInfo = device;
    var userBase = LiveUserBase()
      ..eSource = 3
      ..eType = 0
      ..uaEx = LiveAppUAEx();
    LiveLaunchReq req = LiveLaunchReq()
      ..id = userId
      ..liveUb = userBase
      ..supportDomain = true;
    var wupData = sendWupData(
      servantName: "liveui",
      funcName: "doLaunch",
      req: req,
    );
    return wupData;
  }

  void joinRoom() {
    try {
      var pid = danmakuArgs.topSid;
      var data = buildJoinGroupData(pid: pid);
      var doLaunchData = buildDoLaunchData(ua: dHuyaUa, device: device);
      var liveInfoData = buildLiveInfoData(pid: pid, ua: dHuyaUa, device: device);
      webScoketUtils?.sendMessage(liveInfoData);
      webScoketUtils?.sendMessage(doLaunchData);
      webScoketUtils?.sendMessage(data);
    } catch (e) {
      CoreLog.error("join_data_error:$e");
    }
  }

  @override
  void heartbeat() {
    webScoketUtils?.sendMessage(heartbeatData);
  }

  @override
  Future stop() async {
    onMessage = null;
    onClose = null;
    webScoketUtils?.close();
  }

  Future<void> decodeMessage(List<int> data) async {
    try {
      var stream = TarsInputStream(Uint8List.fromList(data));
      var type = stream.read(0, 0, false);
      if (type == 7) {
        stream = TarsInputStream(stream.readBytes(1, false));
        HYPushMessage wSPushMessage = HYPushMessage();
        wSPushMessage.readFrom(stream);
        if (wSPushMessage.uri == 1400) {
          HYMessage messageNotice = HYMessage();
          messageNotice.readFrom(TarsInputStream(Uint8List.fromList(wSPushMessage.msg)));
          var uname = messageNotice.userInfo.sNickName;
          var content = messageNotice.content;

          // skip sys-information
          if(uname == '系统消息'){
            return;
          }
          // websocket maybe need cookie check, reg temp instead
          // xxx(来自一元上头条)
          // RegExp scReg = RegExp(r'\(来自.+?上头条\)');
          // if (scReg.hasMatch(content)) {
          //   callSc();
          // }
          var color = messageNotice.bulletFormat.fontColor;
          var emoticons = _getHuyaEmoticonsFromContent(content: content);
          onMessage?.call(
            LiveMessage(
              type: LiveMessageType.chat,
              color: color <= 0 ? LiveMessageColor.white : LiveMessageColor.numberToColor(color),
              message: content,
              userName: uname,
              emoticons: emoticons.isNotEmpty ? emoticons : null,
            ),
          );
        } else if (wSPushMessage.uri == 8006) {
          int online = 0;
          var s = TarsInputStream(Uint8List.fromList(wSPushMessage.msg));
          online = s.read(online, 0, false);
          onMessage?.call(
            LiveMessage(
              type: LiveMessageType.online,
              data: online,
              color: LiveMessageColor.white,
              message: "",
              userName: "",
            ),
          );
        }
      } else if (type == 22) {
        WSPushMessageV2 wsPushMessageV2 = WSPushMessageV2();
        stream = TarsInputStream(stream.readBytes(1, false));
        wsPushMessageV2.readFrom(stream);
        for (var item in wsPushMessageV2.vMsgItem) {
          // match uri
          // '110003': ai(666,大气，NB etc)
          // '2001317': sc
          // '1400': 醒目留言
          // '8006': sc-countDown
          // '6220': RankInfoNotice
          // '1091000': pk
          if (item.iUri == 2001317) {
            callSc();
          }
        }
      } else {
        // 或许还有想看别人刷礼物的需求
      }
    } catch (e) {
      CoreLog.error(e);
    }
  }

  Future<void> callSc() async {
    var sc = await getHuyaSuperChatMessageList(lPid: danmakuArgs.topSid);
    if (sc.isNotEmpty) {
      onMessage?.call(
        LiveMessage(
          type: LiveMessageType.superChat,
          userName: "SUPER_CHAT_MESSAGE",
          message: "SUPER_CHAT_MESSAGE",
          color: LiveMessageColor.white,
          data: sc.first,
        ),
      );
    }
  }
}
