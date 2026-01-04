import 'package:simple_live_app/models/db/follow_user.dart';

typedef Cmp<T> = int Function(T a, T b);

String firstLetterLite(String s) {
  if (s.isEmpty) return '{';
  final c = s.codeUnitAt(0);

  // A-Z a-z
  if ((c >= 65 && c <= 90) || (c >= 97 && c <= 122)) {
    return String.fromCharCode(c).toUpperCase();
  }

  // 其他一律 '{'==123,拼音解析消耗性能
  return '{';
}

String sortText(String? remark, String name) {
  if (remark != null && remark.trim().isNotEmpty) {
    return remark.trim();
  }
  return name;
}

Cmp<FollowUser> userNameAsc = (a, b) {
  final ta = sortText(a.remark, a.userName);
  final tb = sortText(b.remark, b.userName);
  final ka = firstLetterLite(ta);
  final kb = firstLetterLite(tb);
  final c = ka.compareTo(kb);
  if (c != 0) return c;

  return a.userName
      .toLowerCase()
      .compareTo(b.userName.toLowerCase());
};

Cmp<FollowUser> userNameDesc = (a, b) => userNameAsc(b, a);