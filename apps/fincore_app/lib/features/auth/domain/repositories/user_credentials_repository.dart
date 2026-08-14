import 'package:fincore_app/features/auth/domain/entities/update_user_credentials_input.dart';
import 'package:fincore_app/features/auth/domain/entities/user_credentials_profile.dart';

abstract interface class UserCredentialsRepository {
  Future<UserCredentialsProfile> getProfile();

  Future<UserCredentialsProfile> update(UpdateUserCredentialsInput input);
}
