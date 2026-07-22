import 'package:flutter_test/flutter_test.dart';
import 'package:pinyin/pinyin.dart';

void main() {
  test('converts Chinese text to short pinyin initials', () {
    final result = PinyinHelper.getShortPinyin('zzz你好啊');

    expect(result, startsWith('zzz'));
    expect(result, contains('n'));
    expect(result, contains('h'));
    expect(result, endsWith('a'));
  });

  test('validates absolute WebDAV-style directory paths', () {
    final regex = RegExp(r'^/([^/]+)(/[^/]+)*$');

    expect(regex.hasMatch('/123/123'), isTrue);
    expect(regex.hasMatch('/123/123/123/123'), isTrue);
    expect(regex.hasMatch('/123'), isTrue);
    expect(regex.hasMatch('123'), isFalse);
    expect(regex.hasMatch('/123/'), isFalse);
  });
}
