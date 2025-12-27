T? asT<T>(dynamic value) {
  if (value is T) {
    return value;
  }
  return null;
}
class FontsModel{
  String version;
  int versionNum;
  String versionDesc;
  String downloadUrl;
  FontsModel({
    required this.version,
    required this.versionNum,
    required this.versionDesc,
    required this.downloadUrl,
  });

}