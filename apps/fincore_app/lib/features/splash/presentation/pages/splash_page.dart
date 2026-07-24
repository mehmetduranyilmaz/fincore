import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/features/auth/domain/usecases/initialize_app.dart';
import 'package:fincore_app/features/splash/presentation/providers/splash_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(splashInitializationProvider, (previous, next) {
      next.whenData((result) {
        if (!context.mounted) {
          return;
        }

        final location = switch (result) {
          InitializationResult.authenticated => AppRoutes.dashboard,
          InitializationResult.unauthenticated => AppRoutes.login,
        };

        context.go(location);
      });
    });

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
