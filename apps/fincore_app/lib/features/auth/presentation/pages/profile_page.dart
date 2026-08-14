import 'dart:async';

import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/features/auth/domain/entities/update_user_credentials_input.dart';
import 'package:fincore_app/features/auth/presentation/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

final class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _newPasswordConfirmationController = TextEditingController();
  bool _profileApplied = false;
  bool _obscurePasswords = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileControllerProvider.notifier).load());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _newPasswordConfirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    ref.listen(profileControllerProvider, (previous, next) {
      final message = next.errorMessage ?? next.successMessage;
      if (message == null ||
          message == previous?.errorMessage ||
          message == previous?.successMessage) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: next.errorMessage == null
                ? null
                : Theme.of(context).colorScheme.error,
          ),
        );
      if (next.successMessage != null) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _newPasswordConfirmationController.clear();
      }
    });
    final profile = state.profile;
    if (!_profileApplied && profile != null) {
      _profileApplied = true;
      _emailController.text = profile.email;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil ve Güvenlik')),
      body: switch (state.status) {
        ProfileStatus.initial ||
        ProfileStatus.loading => const AppLoadingView(),
        ProfileStatus.failure when profile == null => AppErrorView(
          message: state.errorMessage ?? 'Profil yüklenemedi.',
          onRetry: () => ref.read(profileControllerProvider.notifier).load(),
        ),
        _ => _buildForm(state),
      },
    );
  }

  Widget _buildForm(ProfileState state) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SizedBox(
          width: 520,
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.manage_accounts_outlined, size: 48),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Giriş Bilgileri',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'E-posta adresinizi veya şifrenizi değiştirmek için '
                    'mevcut şifrenizi doğrulayın.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    key: const Key('profile_email'),
                    controller: _emailController,
                    label: 'E-posta / Kullanıcı Adı',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.mail_outline),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      return RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(email)
                          ? null
                          : 'Geçerli bir e-posta girin.';
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    key: const Key('profile_current_password'),
                    controller: _currentPasswordController,
                    label: 'Mevcut Şifre',
                    obscureText: _obscurePasswords,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => _obscurePasswords = !_obscurePasswords,
                      ),
                      icon: Icon(
                        _obscurePasswords
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    validator: (value) => (value?.isEmpty ?? true)
                        ? 'Mevcut şifrenizi girin.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    key: const Key('profile_new_password'),
                    controller: _newPasswordController,
                    label: 'Yeni Şifre (isteğe bağlı)',
                    hint: 'Değiştirmeyecekseniz boş bırakın',
                    obscureText: _obscurePasswords,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.password_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      return value.length < 8
                          ? 'Yeni şifre en az 8 karakter olmalıdır.'
                          : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    key: const Key('profile_new_password_confirmation'),
                    controller: _newPasswordConfirmationController,
                    label: 'Yeni Şifre Tekrarı',
                    obscureText: _obscurePasswords,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(Icons.password_outlined),
                    validator: (value) => value != _newPasswordController.text
                        ? 'Yeni şifreler eşleşmiyor.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    key: const Key('profile_save'),
                    label: 'Bilgileri Güncelle',
                    icon: Icons.save_outlined,
                    isLoading: state.status == ProfileStatus.saving,
                    onPressed: state.isBusy ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    final newPassword = _newPasswordController.text;
    await ref
        .read(profileControllerProvider.notifier)
        .update(
          UpdateUserCredentialsInput(
            currentPassword: _currentPasswordController.text,
            newEmail: _emailController.text,
            newPassword: newPassword.isEmpty ? null : newPassword,
          ),
        );
  }
}
