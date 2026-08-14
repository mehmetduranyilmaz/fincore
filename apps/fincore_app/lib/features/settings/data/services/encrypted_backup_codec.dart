import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:fincore_app/features/settings/domain/errors/backup_exception.dart';
import 'package:fincore_app/features/settings/domain/services/backup_codec.dart';

final class EncryptedBackupCodec implements BackupCodec {
  EncryptedBackupCodec({AesGcm? cipher, Pbkdf2? keyDerivation})
    : _cipher = cipher ?? AesGcm.with256bits(),
      _keyDerivation =
          keyDerivation ??
          Pbkdf2.hmacSha256(iterations: _iterations, bits: 256);

  static const String _format = 'fincore-encrypted-backup';
  static const int _formatVersion = 1;
  static const int _payloadVersion = 1;
  static const int _iterations = 210000;

  final AesGcm _cipher;
  final Pbkdf2 _keyDerivation;

  @override
  Future<List<int>> encrypt({
    required Map<String, String?> data,
    required String password,
    required DateTime createdAt,
  }) async {
    final salt = await SecretKeyData.random(length: 16).extractBytes();
    final nonce = _cipher.newNonce();
    final key = await _deriveKey(password, salt);
    final clearText = utf8.encode(
      jsonEncode({
        'schemaVersion': _payloadVersion,
        'createdAtUtc': createdAt.toUtc().toIso8601String(),
        'data': data,
      }),
    );
    final secretBox = await _cipher.encrypt(
      clearText,
      secretKey: key,
      nonce: nonce,
    );
    return utf8.encode(
      jsonEncode({
        'format': _format,
        'version': _formatVersion,
        'kdf': {
          'name': 'PBKDF2-HMAC-SHA256',
          'iterations': _iterations,
          'salt': base64Encode(salt),
        },
        'cipher': {
          'name': 'AES-256-GCM',
          'nonce': base64Encode(secretBox.nonce),
          'cipherText': base64Encode(secretBox.cipherText),
          'mac': base64Encode(secretBox.mac.bytes),
        },
      }),
    );
  }

  @override
  Future<Map<String, String?>> decrypt({
    required List<int> bytes,
    required String password,
  }) async {
    try {
      final envelope = _asMap(jsonDecode(utf8.decode(bytes)));
      if (envelope['format'] != _format ||
          envelope['version'] != _formatVersion) {
        throw const FormatException('Unsupported backup format.');
      }
      final kdf = _asMap(envelope['kdf']);
      final cipherData = _asMap(envelope['cipher']);
      if (kdf['name'] != 'PBKDF2-HMAC-SHA256' ||
          kdf['iterations'] != _iterations ||
          cipherData['name'] != 'AES-256-GCM') {
        throw const FormatException('Unsupported encryption parameters.');
      }
      final salt = base64Decode(kdf['salt']! as String);
      final secretBox = SecretBox(
        base64Decode(cipherData['cipherText']! as String),
        nonce: base64Decode(cipherData['nonce']! as String),
        mac: Mac(base64Decode(cipherData['mac']! as String)),
      );
      final clearText = await _cipher.decrypt(
        secretBox,
        secretKey: await _deriveKey(password, salt),
      );
      final payload = _asMap(jsonDecode(utf8.decode(clearText)));
      if (payload['schemaVersion'] != _payloadVersion) {
        throw const FormatException('Unsupported payload version.');
      }
      final rawData = _asMap(payload['data']);
      return rawData.map((key, value) {
        if (value != null && value is! String) {
          throw const FormatException('Invalid backup value.');
        }
        return MapEntry(key, value as String?);
      });
    } on SecretBoxAuthenticationError {
      throw const BackupException('Yedek parolası yanlış veya dosya bozuk.');
    } on BackupException {
      rethrow;
    } on Object {
      throw const BackupException('Geçerli bir Fincore yedek dosyası seçin.');
    }
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) {
    return _keyDerivation.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  static Map<String, Object?> _asMap(Object? value) {
    if (value is! Map) throw const FormatException('Expected object.');
    return value.map((key, item) {
      if (key is! String) throw const FormatException('Invalid object key.');
      return MapEntry(key, item);
    });
  }
}
