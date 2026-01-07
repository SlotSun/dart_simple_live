class FontModel {
  final String id;
  final String name;
  final List<String> files;
  final String desc;
  final String official;
  final FontLicense? license;
  bool isDownloaded;

  FontModel({
    required this.id,
    required this.name,
    required this.files,
    required this.desc,
    required this.official,
    this.license,
    this.isDownloaded = false,
  });

  factory FontModel.fromJson(Map<String, dynamic> json) {
    return FontModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      files:
          (json['files'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      desc: json['desc'] as String? ?? '',
      official: json['official'] as String? ?? '',
      license: json['license'] != null
          ? FontLicense.fromJson(json['license'] as Map<String, dynamic>)
          : null,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'files': files,
      'desc': desc,
      'official': official,
      'license': license?.toJson(),
      'isDownloaded': isDownloaded,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FontModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class FontLicense {
  final String name;
  final String url;

  const FontLicense({
    required this.name,
    required this.url,
  });

  factory FontLicense.fromJson(Map<String, dynamic> json) {
    return FontLicense(
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
    };
  }
}
