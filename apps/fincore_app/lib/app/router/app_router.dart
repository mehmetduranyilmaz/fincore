import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/features/splash/presentation/pages/splash_page.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
    ],
  );
}
