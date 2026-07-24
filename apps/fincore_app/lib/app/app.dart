import 'package:fincore_app/app/router/app_router.dart';
import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class FincoreApp extends StatelessWidget {
  const FincoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Fincore',
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
