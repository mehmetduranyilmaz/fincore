final class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
    required this.userId,
    required this.email,
    required this.fullName,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;
  final String userId;
  final String email;
  final String fullName;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthSession &&
            accessToken == other.accessToken &&
            refreshToken == other.refreshToken &&
            expiresIn == other.expiresIn &&
            tokenType == other.tokenType &&
            userId == other.userId &&
            email == other.email &&
            fullName == other.fullName;
  }

  @override
  int get hashCode => Object.hash(
    accessToken,
    refreshToken,
    expiresIn,
    tokenType,
    userId,
    email,
    fullName,
  );
}
