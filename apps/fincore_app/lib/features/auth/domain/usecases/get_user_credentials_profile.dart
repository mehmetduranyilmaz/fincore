import 'package:fincore_app/features/auth/domain/entities/user_credentials_profile.dart';
import 'package:fincore_app/features/auth/domain/repositories/user_credentials_repository.dart';

final class GetUserCredentialsProfile {
  const GetUserCredentialsProfile(this._repository);

  final UserCredentialsRepository _repository;

  Future<UserCredentialsProfile> execute() => _repository.getProfile();
}
