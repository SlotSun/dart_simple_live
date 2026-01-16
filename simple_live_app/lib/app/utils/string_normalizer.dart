extension StringNormalizer on String {
  static final Map<String, String> _toneMap = {
    // a
    'ā': 'a', 'á': 'a', 'ǎ': 'a', 'à': 'a',
    // o
    'ō': 'o', 'ó': 'o', 'ǒ': 'o', 'ò': 'o',
    // e
    'ē': 'e', 'é': 'e', 'ě': 'e', 'è': 'e',
    // i
    'ī': 'i', 'í': 'i', 'ǐ': 'i', 'ì': 'i',
    // u
    'ū': 'u', 'ú': 'u', 'ǔ': 'u', 'ù': 'u',
    // ü / v
    'ü': 'v', 'ǖ': 'v', 'ǘ': 'v', 'ǚ': 'v', 'ǜ': 'v',
  };

  /// 去拼音声调 + ü→v + 转小写
  String normalize() {
    final buffer = StringBuffer();

    for (final rune in toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_toneMap[char] ?? char);
    }

    return buffer.toString();
  }
}