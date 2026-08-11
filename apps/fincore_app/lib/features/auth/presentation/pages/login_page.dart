import 'package:fincore_app/app/state/app_controller.dart';
import 'package:fincore_app/app/state/app_state.dart';
import 'package:fincore_app/core/theme/app_durations.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            width: 400,
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _LoginForm(state: state),
            ),
          ),
        ),
      ),
    );
  }
}

final class _LoginForm extends ConsumerStatefulWidget {
  const _LoginForm({required this.state});

  final AppState state;

  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

final class _LoginFormState extends ConsumerState<_LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = widget.state.errorMessage;
    final isLoading = widget.state.status == AppStatus.initializing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.account_balance_rounded, size: AppSpacing.xxl),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Fincore',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Finansınıza güvenle erişin.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          label: 'E-posta',
          prefixIcon: const Icon(Icons.mail_outline),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _passwordController,
          obscureText: true,
          label: 'Şifre',
          prefixIcon: const Icon(Icons.lock_outline),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Giriş Yap',
            icon: Icons.login,
            isLoading: isLoading,
            onPressed: isLoading
                ? null
                : () async {
                    final controller = ref.read(appControllerProvider.notifier);

                    await controller.login(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );
                  },
          ),
        ),
        AnimatedSwitcher(
          duration: AppDurations.fast,
          child: errorMessage == null
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey(errorMessage),
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
