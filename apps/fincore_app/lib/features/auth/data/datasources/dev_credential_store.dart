import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/features/auth/domain/errors/user_credentials_exception.dart';

abstract interface class CredentialKeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

final class SecureCredentialKeyValueStore implements CredentialKeyValueStore {
  const SecureCredentialKeyValueStore(this._storage);

  final SecureStorageService _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

final class DevCredentialRecord {
  const DevCredentialRecord({
    required this.email,
    required this.salt,
    required this.passwordHash,
  });

  final String email;
  final List<int> salt;
  final List<int> passwordHash;
}

final class DevCredentialStore {
  DevCredentialStore(this._storage, {Pbkdf2? passwordHasher})
    : _passwordHasher =
          passwordHasher ?? Pbkdf2.hmacSha256(iterations: 210000, bits: 256);

  static const String defaultEmail = 'dev@fincore.app';
  static const String defaultPassword = '123456';
  static const String _storageKey = 'dev_user_credentials_v1';

  final CredentialKeyValueStore _storage;
  final Pbkdf2 _passwordHasher;

  Future<DevCredentialRecord> getOrCreate() async {
    final stored = await _storage.read(_storageKey);
    if (stored != null) return _decode(stored);
    final record = await _createRecord(defaultEmail, defaultPassword);
    await _write(record);
    return record;
  }

  Future<bool> authenticate(String email, String password) async {
    final record = await getOrCreate();
    if (record.email != email.trim().toLowerCase()) return false;
    final attemptedHash = await _hash(password, record.salt);
    return _constantTimeEquals(attemptedHash, record.passwordHash);
  }

  Future<DevCredentialRecord> update({
    required String currentPassword,
    required String newEmail,
    required String? newPassword,
  }) async {
    final current = await getOrCreate();
    final currentHash = await _hash(currentPassword, current.salt);
    if (!_constantTimeEquals(currentHash, current.passwordHash)) {
      throw const UserCredentialsException('Mevcut şifre yanlış.');
    }
    final next = newPassword == null
        ? DevCredentialRecord(
            email: newEmail,
            salt: current.salt,
            passwordHash: current.passwordHash,
          )
        : await _createRecord(newEmail, newPassword);
    await _write(next);
    return next;
  }

  Future<DevCredentialRecord> _createRecord(
    String email,
    String password,
  ) async {
    final salt = await SecretKeyData.random(length: 16).extractBytes();
    return DevCredentialRecord(
      email: email.trim().toLowerCase(),
      salt: salt,
      passwordHash: await _hash(password, salt),
    );
  }

  Future<List<int>> _hash(String password, List<int> salt) async {
    final key = await _passwordHasher.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return key.extractBytes();
  }

  Future<void> _write(DevCredentialRecord record) {
    return _storage.write(
      _storageKey,
      jsonEncode({
        'version': 1,
        'email': record.email,
        'salt': base64Encode(record.salt),
        'passwordHash': base64Encode(record.passwordHash),
      }),
    );
  }

  static DevCredentialRecord _decode(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map || decoded['version'] != 1) {
        throw const FormatException('Invalid credentials.');
      }
      return DevCredentialRecord(
        email: decoded['email']! as String,
        salt: base64Decode(decoded['salt']! as String),
        passwordHash: base64Decode(decoded['passwordHash']! as String),
      );
    } on Object {
      throw const UserCredentialsException('Kullanıcı bilgileri okunamadı.');
    }
  }

  static bool _constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }
}
