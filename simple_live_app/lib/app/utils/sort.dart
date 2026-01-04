import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/utils/duration_2_str_utils.dart';
import 'package:simple_live_app/models/db/follow_user.dart';

typedef Cmp<T> = int Function(T a, T b);

String firstLetterLite(String s) {
  if (s.isEmpty) return '{';
  final c = s.codeUnitAt(0);
  // 0-9
  if (c >= 48 && c <= 57) return String.fromCharCode(c);
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

void listSortByMethod(List<FollowUser> list, SortMethod sortMethod) {
  // list.sort是非稳定排序
  list.sort((a, b) {
    //  或许可以写一个类似Kotlin-thenBy语法糖保证短路执行
    final liveCmp = b.liveStatus.value.compareTo(a.liveStatus.value);
    if (liveCmp != 0) return liveCmp;
    switch (sortMethod) {
      case SortMethod.watchDuration:
        return b.watchDuration!
            .toDuration()
            .compareTo(a.watchDuration!.toDuration());
      case SortMethod.siteId:
        return a.siteId.compareTo(b.siteId);
      case SortMethod.recently:
        return a.addTime.compareTo(b.addTime);
      case SortMethod.userNameASC:
        return userNameAsc(a, b);
      case SortMethod.userNameDESC:
        return userNameAsc(b, a);
    }
  });
}