class AccountInfo {
  String? name;
  String? avatar;
  String? uid;
  String credential = '';
  bool isValid = false;

  AccountInfo({
    this.name,
    this.avatar,
    this.uid,
    this.credential = '',
    this.isValid = false,
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      uid: json['uid'] as String?,
      credential: json['credential'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'avatar': avatar,
        'uid': uid,
        'credential': credential,
        'isValid': isValid,
      };

  Map<String, dynamic> toMap() => toJson();

  AccountInfo copyWith({
    String? name,
    String? avatar,
    String? uid,
    String? credential,
    bool? isValid,
  }) {
    return AccountInfo(
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      uid: uid ?? this.uid,
      credential: credential ?? this.credential,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  String toString() {
    return 'AccountInfo('
        'name: $name, '
        'avatar: $avatar, '
        'uid: $uid, '
        'credential: $credential'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountInfo &&
        other.name == name &&
        other.avatar == avatar &&
        other.uid == uid &&
        other.credential == credential;
  }

  @override
  int get hashCode => Object.hash(name, avatar, uid, credential);
}
