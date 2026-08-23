import 'dart:async';

import 'package:fincore_app/app/router/app_router.dart';
import 'package:fincore_app/app/state/app_controller.dart';
import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class FincoreApp extends ConsumerStatefulWidget {
  const FincoreApp({super.key});

  @override
  ConsumerState<FincoreApp> createState() => _FincoreAppState();
}

final class _FincoreAppState extends ConsumerState<FincoreApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref.read(appControllerProvider.notifier).realizeDueRecurringExpenses(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Fincore',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
