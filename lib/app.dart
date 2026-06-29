// RetroVerse App Root — GoRouter + Theme setup
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/providers/settings_provider.dart';
import 'router/app_router.dart';

class RetroVerseApp extends ConsumerWidget {
  const RetroVerseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.getTheme(settings.themeMode),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
