import 'dart:math';

class PasswordUtil {
  static PasswordUtil? _passwordUtil;

  static PasswordUtil get instance {
    _passwordUtil ??= PasswordUtil();
    return _passwordUtil!;
  }

  static final _capitalList = [
    'E',
    'D',
    'F',
    'G',
    'H',
    'I',
    'J',
    'O',
    'K',
    'L',
    'M',
    'A',
    'B',
    'C',
    'X',
    'Y',
    'N',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'Z',
    'X'
  ];

  static final _lowCaseList = [
    'a',
    'v',
    'w',
    'f',
    'g',
    'x',
    'm',
    'h',
    'i',
    'k',
    'l',
    'n',
    'b',
    'c',
    'd',
    'e',
    'o',
    'p',
    'r',
    'j',
    's',
    't',
    'u',
    'y',
    'q',
    'z'
  ];

  static final _numberList = ['2', '9', '0', '1', '5', '6', '3', '4', '7', '8'];

  static final _symbolList = ['~', '@', '*', '?', '#', '%', '!', '='];

  static String generate(
    int len, {
    bool cap = true,
    bool low = true,
    bool number = true,
    bool sym = true,
  }) {
    assert(cap || low || number || sym);

    List<String> list = [];
    if (cap) {
      list.addAll(_capitalList);
    }
    if (low) {
      list.addAll(_lowCaseList);
    }
    if (number) {
      list.addAll(_numberList);
    }
    if (sym) {
      list.addAll(_symbolList);
    }
    StringBuffer stringBuffer = StringBuffer();
    Random random = Random.secure();
    for (int i = 0; i < len; i++) {
      int index = random.nextInt(list.length);
      stringBuffer.write(list[index]);
    }
    return stringBuffer.toString();
  }
}
