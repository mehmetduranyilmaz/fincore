import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';
import 'package:fincore_app/features/auth/domain/usecases/login_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);

final class LoginState {
  const LoginState({this.isLoading = false, this.session, this.errorMessage});

  final bool isLoading;
  final AuthSession? session;
  final String? errorMessage;
}

final class LoginController extends Notifier<LoginState> {
  late LoginUser _loginUser;

  @override
  LoginState build() {
    _loginUser = ref.watch(loginUserProvider);
    return const LoginState();
  }

  Future<void> login({required String email, required String password}) async {
    state = const LoginState(isLoading: true);

    try {
      final session = await _loginUser.execute(
        email: email,
        password: password,
      );

      state = LoginState(session: session);
    } on Object catch (error) {
      state = LoginState(errorMessage: error.toString());
    }
  }
}
