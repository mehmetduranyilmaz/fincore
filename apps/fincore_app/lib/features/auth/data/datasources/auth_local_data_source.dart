import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';

abstract interface class AuthLocalDataSource {
  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<bool> hasValidSession();

  Future<void> saveSession(AuthSession session);

  Future<void> clearSession();
}
