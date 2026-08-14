import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/auth/domain/entities/update_user_credentials_input.dart';
import 'package:fincore_app/features/auth/domain/entities/user_credentials_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ProfileStatus { initial, loading, loaded, saving, failure }

final class ProfileState {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
    this.successMessage,
  });

  final ProfileStatus status;
  final UserCredentialsProfile? profile;
  final String? errorMessage;
  final String? successMessage;

  bool get isBusy =>
      status == ProfileStatus.loading || status == ProfileStatus.saving;
}

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

final class ProfileController extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState();

  Future<void> load() async {
    state = const ProfileState(status: ProfileStatus.loading);
    try {
      final profile = await ref
          .read(getUserCredentialsProfileProvider)
          .execute();
      state = ProfileState(status: ProfileStatus.loaded, profile: profile);
    } on Object catch (error) {
      state = ProfileState(
        status: ProfileStatus.failure,
        errorMessage: ErrorMapper.map(error),
      );
    }
  }

  Future<bool> update(UpdateUserCredentialsInput input) async {
    final currentProfile = state.profile;
    state = ProfileState(status: ProfileStatus.saving, profile: currentProfile);
    try {
      final profile = await ref
          .read(updateUserCredentialsProvider)
          .execute(input);
      state = ProfileState(
        status: ProfileStatus.loaded,
        profile: profile,
        successMessage:
            'Kullanıcı bilgileriniz güncellendi. Sonraki girişte yeni '
            'bilgilerinizi kullanın.',
      );
      return true;
    } on Object catch (error) {
      state = ProfileState(
        status: ProfileStatus.loaded,
        profile: currentProfile,
        errorMessage: ErrorMapper.map(error),
      );
      return false;
    }
  }
}
