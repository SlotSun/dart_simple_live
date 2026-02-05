import 'package:simple_live_app/app/utils/dynamic_filter.dart';
/// 排序条件
class SortCondition<T> {
  final Comparable Function(T item) valueGetter;
  final bool ascending;

  SortCondition({
    required this.valueGetter,
    this.ascending = true,
  });
}

extension MappableListExtension<T extends Mappable> on List<T> {
  /// 动态排序函数
  List<T> dynamicSort(List<SortCondition<T>> sortConditions) {
    sort(
      (a, b) {
        for (final cond in sortConditions) {
          final aValue = cond.valueGetter(a);
          final bValue = cond.valueGetter(b);

          final cmp = aValue.compareTo(bValue);
          if (cmp != 0) return cond.ascending ? cmp : -cmp;
        }
        return 0;
      },
    );

    return this;
  }
}
