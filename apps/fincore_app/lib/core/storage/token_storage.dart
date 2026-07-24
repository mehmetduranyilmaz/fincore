import 'package:fincore_app/core/storage/access_token_reader.dart';
import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(secureStorageServiceProvider)),
);

final class TokenStorage implements AccessTokenReader {
  const TokenStorage(this._secureStorageService);

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  final SecureStorageService _secureStorageService;

  Future<void> saveAccessToken(String token) {
    return _secureStorageService.write(key: _accessTokenKey, value: token);
  }

  Future<void> saveRefreshToken(String token) {
    return _secureStorageService.write(key: _refreshTokenKey, value: token);
  }

  @override
  Future<String?> getAccessToken() {
    return _secureStorageService.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() {
    return _secureStorageService.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorageService.delete(key: _accessTokenKey),
      _secureStorageService.delete(key: _refreshTokenKey),
    ]);
  }
}
