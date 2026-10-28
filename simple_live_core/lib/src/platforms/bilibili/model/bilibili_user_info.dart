import 'dart:convert';

import '../../../common/common_asT.dart';

class BiliBiliUserInfoModel {
  BiliBiliUserInfoModel({
    this.mid,
    this.uname,
    this.userid,
    this.sign,
    this.birthday,
    this.sex,
    this.nickFree,
    this.rank,
    this.face,
  });

  int? mid;
  String? uname;
  String? userid;
  String? sign;
  String? birthday;
  String? sex;
  bool? nickFree;
  String? rank;
  String? face;

  factory BiliBiliUserInfoModel.fromJson(Map<String, dynamic> json) => BiliBiliUserInfoModel(
        mid: asT<int?>(json['mid']),
        uname: asT<String?>(json['uname']),
        userid: asT<String?>(json['userid']),
        sign: asT<String?>(json['sign']),
        birthday: asT<String?>(json['birthday']),
        sex: asT<String?>(json['sex']),
        nickFree: asT<bool?>(json['nick_free']),
        rank: asT<String?>(json['rank']),
        face: asT<String?>(json['face']),
      );

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'mid': mid,
        'uname': uname,
        'userid': userid,
        'sign': sign,
        'birthday': birthday,
        'sex': sex,
        'nick_free': nickFree,
        'rank': rank,
        'face': face,
      };
}
