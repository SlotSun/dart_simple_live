import 'package:simple_live_core/src/platforms/huya/tars/types.dart';
import 'package:tars_dart/tars/codec/tars_displayer.dart';
import 'package:tars_dart/tars/codec/tars_input_stream.dart';
import 'package:tars_dart/tars/codec/tars_output_stream.dart';
import 'package:tars_dart/tars/codec/tars_struct.dart';

class GameEventMessageBoardInfo extends TarsStruct {
  MessageUser tMessageUser = MessageUser(); //tag 0
  String sContent = ""; //tag 1
  int iCost = 0; //tag 2
  int iTotalSec = 0; //tag 4
  int iCountDown = 0; //tag 5
  int lMessageId = 0; //tag 9
  int iCostPay = 0; //tag 12

  @override
  void readFrom(TarsInputStream _is) {
    tMessageUser         = _is.read(tMessageUser, 0, false);
    sContent             = _is.read(sContent, 1, false);
    iCost                = _is.read(iCost, 2, false);
    iTotalSec            = _is.read(iTotalSec, 4, false);
    iCountDown           = _is.read(iCountDown, 5, false);
    lMessageId           = _is.read(lMessageId, 9, false);
    iCostPay             = _is.read(iCostPay, 12, false);
  }

  @override
  void writeTo(TarsOutputStream _os) {
    _os.write(tMessageUser, 0);
    _os.write(sContent, 1);
    _os.write(iCost, 2);
    _os.write(iTotalSec, 4);
    _os.write(iCountDown, 5);
    _os.write(lMessageId, 9);
    _os.write(iCostPay, 12);
  }

  @override
  TarsStruct deepCopy() {
    return GameEventMessageBoardInfo()
      ..tMessageUser = tMessageUser
      ..sContent = sContent
      ..iCost = iCost
      ..iTotalSec = iTotalSec
      ..iCountDown = iCountDown
      ..lMessageId = lMessageId
      ..iCostPay = iCostPay
    ;
  }

  @override
  displayAsString(StringBuffer sb, int level) {
    TarsDisplayer _ds = TarsDisplayer(sb, level: level);
    _ds.DisplayTarsStruct(tMessageUser, "tMessageUser");
    _ds.DisplayString(sContent, "sContent");
    _ds.DisplayInt(iCost, "iCost");
    _ds.DisplayInt(iTotalSec, "iTotalSec");
    _ds.DisplayInt(iCountDown, "iCountDown");
    _ds.DisplayInt(lMessageId, "lMessageId");
    _ds.DisplayInt(iCostPay, "iCostPay");
  }
}
