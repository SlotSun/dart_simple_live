import 'dart:convert';
import 'common/common_asT.dart';

class SyncClientInfoModel {
  SyncClientInfoModel({
    required this.name,
    required this.version,
    required this.address,
    required this.port,
    required this.type,
  });

  factory SyncClientInfoModel.fromJson(Map<String, dynamic> json) =>
      SyncClientInfoModel(
        type: asT<String>(json['type'])!,
        name: asT<String>(json['name'])!,
        version: asT<String>(json['version'])!,
        address: asT<String>(json['address'])!,
        port: asT<int>(json['port'])!,
      );
  String type;
  String name;
  String version;
  String address;
  int port;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'version': version,
        'address': address,
        'port': port,
        'type': type,
      };
}
