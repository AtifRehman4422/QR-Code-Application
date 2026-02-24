import 'dart:convert';
import 'package:encrypt/encrypt.dart';

class EncryptionUtil {
  static const _keyLength = 32;
  static const _ivLength = 16;

  static String _getOrCreateKey(String seed) {
    final key = seed.padRight(_keyLength).substring(0, _keyLength);
    return key;
  }

  static String encrypt(String plainText, String secretKey) {
    try {
      final key = Key(utf8.encode(_getOrCreateKey(secretKey)));
      final iv = IV.fromLength(_ivLength);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      return plainText;
    }
  }

  static String decrypt(String cipherText, String secretKey) {
    try {
      final parts = cipherText.split(':');
      if (parts.length != 2) return cipherText;
      final key = Key(utf8.encode(_getOrCreateKey(secretKey)));
      final iv = IV(base64.decode(parts[0]));
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (e) {
      return cipherText;
    }
  }
}
