final class UserCredentialsException implements Exception {
  const UserCredentialsException(this.message);

  final String message;

  @override
  String toString() => message;
}
