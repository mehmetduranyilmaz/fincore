import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';
import 'package:fincore_app/features/auth/domain/entities/user.dart';

abstract interface class AuthRepository {
  Future<User?> getCurrentUser();

  Future<bool> hasValidSession();

  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession> refresh();

  Future<void> logout();
}
