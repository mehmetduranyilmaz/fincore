import 'package:fincore_app/core/di/repositories.dart';
import 'package:fincore_app/features/auth/domain/usecases/initialize_app.dart';
import 'package:fincore_app/features/auth/domain/usecases/login_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final initializeAppProvider = Provider<InitializeApp>(
  (ref) => InitializeApp(ref.watch(authRepositoryProvider)),
);

final loginUserProvider = Provider<LoginUser>(
  (ref) => LoginUser(ref.watch(authRepositoryProvider)),
);
