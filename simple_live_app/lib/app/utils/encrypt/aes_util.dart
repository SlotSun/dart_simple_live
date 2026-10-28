import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class AesUtils {
  // AES-GCM 256
  static final _algorithm = AesGcm.with256bits();
  

  // base64 32byte
  static Future<String> generateKey() async {
    var secretKey = await _algorithm.newSecretKey();
    final keyBytes = await secretKey.extractBytes();
    return base64Encode(keyBytes);
  }

  /// 加密文本
  /// [plainText] 明文
  /// [keyBase64] Base64 格式的密钥
  static Future<String> encrypt(String plainText, String keyBase64) async {
    var keyBytes = base64Decode(keyBase64);
    var secretKey = SecretKey(keyBytes);
    var nonce = _algorithm.newNonce();

    SecretBox secretBox = await _algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: secretKey,
      nonce: nonce,
    );

    // base64 = nonce + 密文 + MAC
    Uint8List combined = Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    return base64Encode(combined);
  }

  /// 解密文本
  /// [encryptedBase64] encrypt 返回的组合串
  /// [keyBase64] Base64 格式的密钥
  static Future<String> decrypt(String encryptedBase64, String keyBase64) async {
    var keyBytes = base64Decode(keyBase64);
    var secretKey = SecretKey(keyBytes);

    var combined = base64Decode(encryptedBase64);

    // 根据 GCM 的固定长度拆分
    var nonceLength = 12;
    var macLength = 16;

    var nonce = combined.sublist(0, nonceLength);
    var cipherText = combined.sublist(
      nonceLength,
      combined.length - macLength,
    );
    var macBytes = combined.sublist(combined.length - macLength);

    var secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    var clearBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(clearBytes);
  }
}