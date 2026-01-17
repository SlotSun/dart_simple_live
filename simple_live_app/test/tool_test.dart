import 'package:flutter_test/flutter_test.dart';
import 'package:pinyin/pinyin.dart';

void testPinyin(){
  test("测试拼音", (){
    var str = "zzz你好啊";
    var res = PinyinHelper.getShortPinyin(str);
    print(res);
  });
}

void main(){
  testPinyin();
}