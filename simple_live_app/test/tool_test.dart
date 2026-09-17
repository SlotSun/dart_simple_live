import 'package:flutter_test/flutter_test.dart';
import 'package:pinyin/pinyin.dart';

void testPinyin(){
  test("测试拼音", (){
    var str = "zzz你好啊";
    var res = PinyinHelper.getShortPinyin(str);
    print(res);
  });
}

void testDirectoryCheck(String path) {
  test("测试文件夹路径检测", () {
    final regex = RegExp(r'^/([^/]+)(/[^/]+)*$');
    var res = regex.hasMatch(path);
    print(res ? "yes" : "no");
  });
}

void testDouyinUrlParse() {
  // 测试抖音URL解析正则 - 验证包含.的房间ID能正确匹配
  var regExp = RegExp(r"live\.douyin\.com/([\d\w.]+)");

  test("抖音URL - 数字ID", () {
    var url = "https://live.douyin.com/123456";
    var match = regExp.firstMatch(url);
    expect(match?.group(1), equals("123456"));
  });

  test("抖音URL - 字母ID", () {
    var url = "https://live.douyin.com/abcDEF";
    var match = regExp.firstMatch(url);
    expect(match?.group(1), equals("abcDEF"));
  });

  test("抖音URL - 带点号的ID (user.)", () {
    var url = "https://live.douyin.com/user.";
    var match = regExp.firstMatch(url);
    expect(match?.group(1), equals("user."));
  });

  test("抖音URL - 带点号的ID (user.name)", () {
    var url = "https://live.douyin.com/user.name";
    var match = regExp.firstMatch(url);
    expect(match?.group(1), equals("user.name"));
  });

  test("抖音URL - 带多个点号的ID", () {
    var url = "https://live.douyin.com/user.name.123";
    var match = regExp.firstMatch(url);
    expect(match?.group(1), equals("user.name.123"));
  });

  test("抖音URL - 带查询参数", () {
    var url = "https://live.douyin.com/user.name?enter_from=share";
    var match = regExp.firstMatch(url);
    expect(match?.group(1), equals("user.name"));
  });
}

void main(){
  var p1 = "/123/123";
  var p2 = "/123/123/123/123";
  var p3= "123";
  var p4 = "/123";
  var p5 = '/123/'; //no
  var pathList = [p1,p2,p3,p4,p5];
  for(var path in pathList){
    testDirectoryCheck(path);
  }
  testDouyinUrlParse();
}