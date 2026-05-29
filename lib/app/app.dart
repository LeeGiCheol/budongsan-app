import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:budongsan_app/features/settings/providers/theme_provider.dart';
import 'package:budongsan_app/app/router.dart';
import 'package:budongsan_app/app/theme/app_theme.dart';

class BudongsanApp extends StatelessWidget {
  const BudongsanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: '부동산 계산기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
