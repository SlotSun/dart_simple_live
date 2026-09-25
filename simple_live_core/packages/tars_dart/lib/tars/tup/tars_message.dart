import 'dart:typed_data';

import '/tars/tup/request_packet.dart';
import '/tars/codec/tars_input_stream.dart';
import '/tars/codec/tars_output_stream.dart';
import '/tars/codec/tars_struct.dart';
import '/tars/codec/tars_displayer.dart';

class TarsMessage extends TarsStruct {
  String className() {
    return "TarsMessage";
  }
  RequestPacket header = RequestPacket();
  Map<String, Uint8List> body = <String, Uint8List>{};

  @override
  void readFrom(TarsInputStream _is) {
    header = _is.readTarsStruct(header, 0, false) as RequestPacket;
    body = _is.readMap<String, Uint8List>(body, 1, false);
  }

  @override
  void writeTo(TarsOutputStream _os) {
    _os.write(header, 0);
    _os.write(body, 1);
  }

  @override
  TarsStruct deepCopy() {
    return TarsMessage()
      ..header = header.deepCopy() as RequestPacket
      ..body = Map<String, Uint8List>.from(body);
  }

  @override
  void displayAsString(StringBuffer sb, int level) {
    TarsDisplayer _ds = TarsDisplayer(sb, level: level);
    _ds.display(header, "header");
    _ds.display(body, "body");
  }
}
