import 'package:fincore_app/core/di/repositories.dart';
import 'package:fincore_app/features/auth/application/auth_session_manager.dart';
import 'package:fincore_app/features/auth/domain/usecases/initialize_app.dart';
import 'package:fincore_app/features/auth/domain/usecases/login_user.dart';
import 'package:fincore_app/features/auth/domain/usecases/refresh_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final initializeAppProvider = Provider<InitializeApp>(
  (ref) => InitializeApp(ref.watch(authRepositoryProvider)),
);

final loginUserProvider = Provider<LoginUser>(
  (ref) => LoginUser(ref.watch(authRepositoryProvider)),
);

final Provider<AuthSessionManager> authSessionManagerProvider =
    Provider<AuthSessionManager>((ref) {
      final manager = AuthSessionManager(ref.watch(authRepositoryProvider));

      ref.onDispose(manager.dispose);

      return manager;
    });

final Provider<RefreshSession> refreshSessionProvider =
    Provider<RefreshSession>(
      (ref) => RefreshSession(ref.watch(authRepositoryProvider)),
    );
