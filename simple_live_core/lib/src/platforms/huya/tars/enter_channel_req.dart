import 'package:simple_live_core/src/platforms/huya/tars/types.dart';
import 'package:tars_dart/tars/codec/tars_displayer.dart';
import 'package:tars_dart/tars/codec/tars_input_stream.dart';
import 'package:tars_dart/tars/codec/tars_output_stream.dart';
import 'package:tars_dart/tars/codec/tars_struct.dart';

class EnterChannelReq extends TarsStruct{
  HuyaUserId tUserId = HuyaUserId(); //tag 1
  int lTid = 0;//tag 2
  int lSid = 0;//tag 3
  int iChannelTyp = 0;//tag 4

  @override
  void readFrom(TarsInputStream _is) {
    tUserId              = _is.read(tUserId, 1, false);
    lTid                 = _is.read(lTid, 2, false);
    lSid                 = _is.read(lSid, 3, false);
    iChannelTyp          = _is.read(iChannelTyp, 4, false);
  }

  @override
  void writeTo(TarsOutputStream _os) {
    _os.write(tUserId, 1);
    _os.write(lTid, 2);
    _os.write(lSid, 3);
    _os.write(iChannelTyp, 4);
  }

  @override
  TarsStruct deepCopy() {
    return EnterChannelReq()
      ..tUserId = tUserId
      ..lTid = lTid
      ..lSid = lSid
      ..iChannelTyp = iChannelTyp
    ;
  }

  @override
  displayAsString(StringBuffer sb, int level) {
    TarsDisplayer _ds = TarsDisplayer(sb, level: level);
    _ds.DisplayTarsStruct(tUserId, "tUserId");
    _ds.DisplayInt(lTid, "lTid");
    _ds.DisplayInt(lSid, "lSid");
    _ds.DisplayInt(iChannelTyp, "iChannelTyp");
  }
}