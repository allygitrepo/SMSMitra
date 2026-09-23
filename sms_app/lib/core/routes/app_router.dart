import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/storage_service.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/main_navigation.dart';
import '../../shared/widgets/gradient_button.dart';
import '../utils/logger.dart';

/// Custom route observer that logs route transitions for observability.
class AppRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    logger.d('Navigation PUSH: ${route.settings.name ?? route.settings}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    logger.d('Navigation POP: ${route.settings.name ?? route.settings}');
  }
}

/// Centralized routing configuration using GoRouter with Auth Guards and 404 handler.
class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String settings = '/settings';
  static const String setupSim = '/setup-sim';
  static const String home = '/home';

  static final router = GoRouter(
    initialLocation: splash,
    observers: [AppRouteObserver()],
    redirect: (BuildContext context, GoRouterState state) {
      final location = state.uri.path;

      // Allow splash screen to perform animated onboarding
      if (location == splash) return null;

      final bool isLoggedIn = StorageService.isLoggedIn();
      final bool isRegistered = StorageService.isUserRegistered();
      final bool isSimConfigured = StorageService.isSimConfigured();

      final bool isAuthRoute = location == login || location == register;

      // 1. Unauthenticated users trying to access protected routes
      if (!isLoggedIn) {
        if (!isAuthRoute) {
          return isRegistered ? login : register;
        }
        return null;
      }

      // 2. Authenticated users trying to access login/register
      if (isAuthRoute) {
        return isSimConfigured ? home : setupSim;
      }

      // 3. Authenticated user accessing home or settings without SIM configured
      if ((location == home || location == settings) && !isSimConfigured) {
        return setupSim;
      }

      return null;
    },
    errorBuilder: (context, state) => NotFoundScreen(path: state.uri.path),
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const MainNavigation(),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: setupSim,
        builder: (context, state) => const SettingsScreen(isFirstTime: true),
      ),
    ],
  );
}

/// Branded 404 / Route Not Found Screen
class NotFoundScreen extends StatelessWidget {
  final String path;
  const NotFoundScreen({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.explore_off_outlined,
                  size: 72,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '404 - Page Not Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The requested path "$path" does not exist or has been moved.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: 'Return Home',
                onPressed: () {
                  final isLoggedIn = StorageService.isLoggedIn();
                  context.go(isLoggedIn ? AppRouter.home : AppRouter.login);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
