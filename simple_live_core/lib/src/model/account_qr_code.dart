import 'package:simple_live_core/src/common/qr_status.dart';

class QRCode {
  final String key;

  // url for generate img
  final String url;

  final int? createdAt;

  final int? expireAt;

  QRCode({
    required this.key,
    required this.url,
    this.createdAt,
    this.expireAt,
  });
}

class QRPollResult {
  QRStatus status;

  // 有效凭证
  String credential;

  // 附加信息
  String message;

  QRPollResult({
    required this.status,
    this.credential = '',
    this.message = '',
  });

  factory QRPollResult.fromJson(Map<String, dynamic> json) {
    return QRPollResult(
      status: QRStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => QRStatus.failed,
      ),
      credential: json['credential'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'credential': credential,
        'message': message,
      };

  QRPollResult copyWith({
    QRStatus? status,
    String? credential,
    int? rawCode,
    String? message,
  }) {
    return QRPollResult(
      status: status ?? this.status,
      credential: credential ?? this.credential,
      message: message ?? this.message,
    );
  }

  @override
  String toString() {
    return 'QRPollResult('
        'status: $status, '
        'credential: $credential, '
        'message: $message'
        ')';
  }
}
