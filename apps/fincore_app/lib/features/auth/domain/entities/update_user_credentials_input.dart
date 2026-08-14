final class UpdateUserCredentialsInput {
  const UpdateUserCredentialsInput({
    required this.currentPassword,
    required this.newEmail,
    required this.newPassword,
  });

  final String currentPassword;
  final String newEmail;
  final String? newPassword;
}
