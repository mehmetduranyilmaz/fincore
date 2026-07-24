import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthSession> login({required String email, required String password});

  Future<void> logout();
}
