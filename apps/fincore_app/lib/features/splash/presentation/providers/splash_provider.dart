import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/auth/domain/usecases/initialize_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final splashInitializationProvider = FutureProvider<InitializationResult>(
  (ref) => ref.watch(initializeAppProvider).execute(),
);
