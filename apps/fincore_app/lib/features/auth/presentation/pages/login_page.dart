import 'package:fincore_app/app/state/app_controller.dart';
import 'package:fincore_app/app/state/app_state.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
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
          child: SizedBox(width: 360, child: _LoginForm(state: state)),
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
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: isLoading
              ? null
              : () async {
                  final controller = ref.read(appControllerProvider.notifier);

                  await controller.login(
                    email: _emailController.text,
                    password: _passwordController.text,
                  );
                },
          child: isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Login'),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(errorMessage),
        ],
      ],
    );
  }
}
