import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/app/state/app_controller.dart';
import 'package:fincore_app/app/state/app_state.dart';
import 'package:fincore_app/features/app_shell/presentation/pages/app_shell_page.dart';
import 'package:fincore_app/features/auth/presentation/pages/login_page.dart';
import 'package:fincore_app/features/splash/presentation/pages/splash_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>(AppRouter.create);

abstract final class AppRouter {
  static GoRouter create(Ref ref) {
    final refreshNotifier = ValueNotifier<AppState>(
      ref.read(appControllerProvider),
    );

    ref.listen<AppState>(appControllerProvider, (previous, next) {
      refreshNotifier.value = next;
    });

    final router = GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: refreshNotifier,
      redirect: (context, state) => _redirect(refreshNotifier.value, state),
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const AppShellPage(),
        ),
      ],
    );

    ref.onDispose(() {
      router.dispose();
      refreshNotifier.dispose();
    });

    return router;
  }

  static String? _redirect(AppState appState, GoRouterState routerState) {
    final location = routerState.matchedLocation;
    final isLogin = location == AppRoutes.login;
    final isSplash = location == AppRoutes.splash;

    return switch (appState.status) {
      AppStatus.initializing || AppStatus.failure => null,
      AppStatus.unauthenticated when !isLogin => AppRoutes.login,
      AppStatus.authenticated when isLogin || isSplash => AppRoutes.dashboard,
      _ => null,
    };
  }
}
