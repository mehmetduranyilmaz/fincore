import 'package:fincore_app/features/auth/domain/entities/user.dart';

final class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final User user;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthSession &&
            accessToken == other.accessToken &&
            refreshToken == other.refreshToken &&
            user == other.user;
  }

  @override
  int get hashCode => Object.hash(accessToken, refreshToken, user);
}
