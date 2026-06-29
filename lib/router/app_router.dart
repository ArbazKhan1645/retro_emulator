import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/library/library_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/theme_settings_screen.dart';
import '../features/settings/controller_settings_screen.dart';
import '../features/settings/controller_layout_editor_screen.dart';
import '../features/game_detail/game_detail_screen.dart';
import '../features/emulator/emulator_screen.dart';
import '../features/save_states/save_states_screen.dart';
import '../features/achievements/achievements_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) => _router);

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const SplashScreen(),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    ),
    GoRoute(
      path: '/library',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const LibraryScreen(),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const SettingsScreen(),
        transitionsBuilder: (ctx, anim, _, child) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),
    GoRoute(
      path: '/game/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CustomTransitionPage(
          child: GameDetailScreen(gameId: id),
          transitionsBuilder: (ctx, anim, _, child) {
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 420),
        );
      },
    ),
    GoRoute(
      path: '/emulator/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final saveStatePath = state.uri.queryParameters['saveStatePath'];
        return CustomTransitionPage(
          child: EmulatorScreen(
            gameId: id,
            initialSaveStatePath: saveStatePath,
          ),
          transitionsBuilder: (ctx, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        );
      },
    ),
    GoRoute(
      path: '/save-states/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CustomTransitionPage(
          child: SaveStatesScreen(gameId: id),
          transitionsBuilder: (ctx, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        );
      },
    ),
    GoRoute(
      path: '/achievements',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const AchievementsScreen(),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    ),
    GoRoute(
      path: '/settings/themes',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const ThemeSettingsScreen(),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    ),
    GoRoute(
      path: '/settings/controller',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const ControllerSettingsScreen(),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    ),
    GoRoute(
      path: '/settings/controller/layout-editor',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const ControllerLayoutEditorScreen(),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    ),
  ],
);
