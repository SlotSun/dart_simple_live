import 'package:tars_dart/tars/codec/tars_input_stream.dart';
import 'package:tars_dart/tars/codec/tars_output_stream.dart';
import 'package:tars_dart/tars/codec/tars_struct.dart';


class SendItemSubBroadcastPacket extends TarsStruct {
  int iItemType = 0; // tag 0
  String strPayId = ""; // tag 1
  int lPresenterUid = 0; // tag 3
  int lSenderUid = 0; // tag 4
  String sPresenterNick = ""; // tag 5
  String sSenderNick = ""; // tag 6
  String sSendContent = ""; // tag 7
  int iDisplayInfo = 0; // tag 12
  String iSenderIcon = ""; // tag 14
  String iPresenterIcon = ""; // tag 15
  String sExpand = ""; // tag 17
  String sPropsName = ""; // tag 20
  int iAccpet = 0; // tag 21
  int iEventType = 0; // tag 22
  int lRoomId = 0; // tag 24
  int lHomeOwnerUid = 0; // tag 25
  int iPayType = -1; // tag 27
  String sCustomText = ""; // tag 37
  int lPayTotal = 0; // tag 41


  @override
  Object deepCopy() {
    // TODO: implement deepCopy
    throw UnimplementedError();
  }

  @override
  void displayAsString(StringBuffer sb, int level) {
    // TODO: implement displayAsString
  }

  @override
  void readFrom(TarsInputStream _is) {
    iItemType = _is.read(iItemType, 0, false);
    strPayId = _is.read(strPayId, 1, false);
    lPresenterUid = _is.read(lPresenterUid, 3, false);
    lSenderUid = _is.read(lSenderUid, 4, false);
    sPresenterNick = _is.read(sPresenterNick, 5, false);
    sSenderNick = _is.read(sSenderNick, 6, false);
    sSendContent = _is.read(sSendContent, 7, false);
    iDisplayInfo = _is.read(iDisplayInfo, 12, false);
    iSenderIcon = _is.read(iSenderIcon, 14, false);
    iPresenterIcon = _is.read(iPresenterIcon, 15, false);
    sExpand = _is.read(sExpand, 17, false);
    sPropsName = _is.read(sPropsName, 20, false);
    iAccpet = _is.read(iAccpet, 21, false);
    iEventType = _is.read(iEventType, 22, false);
    lRoomId = _is.read(lRoomId, 24, false);
    lHomeOwnerUid = _is.read(lHomeOwnerUid, 25, false);
    iPayType = _is.read(iPayType, 27, false);
    sCustomText = _is.read(sCustomText, 37, false);
    lPayTotal = _is.read(lPayTotal, 41, false);
  }

  @override
  void writeTo(TarsOutputStream _os) {
    // TODO: implement writeTo
  }
}

