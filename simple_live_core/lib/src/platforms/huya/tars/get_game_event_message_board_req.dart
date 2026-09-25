import 'package:simple_live_core/src/platforms/huya/tars/types.dart';
import 'package:tars_dart/tars/codec/tars_displayer.dart';
import 'package:tars_dart/tars/codec/tars_input_stream.dart';
import 'package:tars_dart/tars/codec/tars_output_stream.dart';
import 'package:tars_dart/tars/codec/tars_struct.dart';

class GetGameEventMessageBoardReq extends TarsStruct {
  int lPid = 0; //tag 0
  String sOffset = ""; //tag 1
  HuyaUserId tId = HuyaUserId(); //tag 2
  int iMessageBoardScope = 0; //tag 3
  int iPageSize = 10; //tag 4

  @override
  void readFrom(TarsInputStream _is) {
    lPid                 = _is.read(lPid, 0, false);
    sOffset              = _is.read(sOffset, 1, false);
    tId                  = _is.read(tId, 2, false);
    iMessageBoardScope   = _is.read(iMessageBoardScope, 3, false);
    iPageSize            = _is.read(iPageSize, 4, false);
  }

  @override
  void writeTo(TarsOutputStream _os) {
    _os.write(lPid, 0);
    _os.write(sOffset, 1);
    _os.write(tId, 2);
    _os.write(iMessageBoardScope, 3);
    _os.write(iPageSize, 4);
  }

  @override
  TarsStruct deepCopy() {
    return GetGameEventMessageBoardReq()
      ..lPid = lPid
      ..sOffset = sOffset
      ..tId = tId
      ..iMessageBoardScope = iMessageBoardScope
      ..iPageSize = iPageSize
    ;
  }

  @override
  displayAsString(StringBuffer sb, int level) {
    TarsDisplayer _ds = TarsDisplayer(sb, level: level);
    _ds.DisplayInt(lPid, "lPid");
    _ds.DisplayString(sOffset, "sOffset");
    _ds.DisplayTarsStruct(tId, "tId");
    _ds.DisplayInt(iMessageBoardScope, "iMessageBoardScope");
    _ds.DisplayInt(iPageSize, "iPageSize");
  }
}
