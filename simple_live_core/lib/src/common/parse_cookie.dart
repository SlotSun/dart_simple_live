// cookie to map<String,String>
import 'dart:convert';

Map<String, String> parseCookie(String raw) => Map.fromEntries(
  raw.split(';')
      .map((e) => e.trim())
      .where((e) => e.contains('='))
      .map((e) {
    final i = e.indexOf('=');
    return MapEntry(e.substring(0, i).trim(), e.substring(i + 1).trim());
  }),
);

// decode jwt
Map<String, dynamic> decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) throw FormatException('Invalid JWT');

  String normalize(String s) {
    s = s.replaceAll('-', '+').replaceAll('_', '/');
    switch (s.length % 4) {
      case 2: s += '=='; break;
      case 3: s += '=';  break;
    }
    return s;
  }

  final payload = utf8.decode(base64.decode(normalize(parts[1])));
  return jsonDecode(payload) as Map<String, dynamic>;
}