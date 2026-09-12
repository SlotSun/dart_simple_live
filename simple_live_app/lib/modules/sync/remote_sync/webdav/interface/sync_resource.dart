import 'package:archive/archive.dart';

abstract class SyncResource<T> {
  String get fileName;

  Future<T> loadLocal();

  /// 从下载后的 archive 中读取
  T? loadRemote(Archive archive);

  Future<void> saveLocal(T data);

  /// 写入待上传的 archive
  void saveRemote(Archive archive, T data);

  T merge(T local, T remote);
}
