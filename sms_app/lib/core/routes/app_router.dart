import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/main_navigation.dart';
import '../../features/profile/api_integration_screen.dart';
import '../../features/profile/app_logs_screen.dart';

/// Centralized routing configuration using GoRouter.
class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String settings = '/settings';
  static const String setupSim = '/setup-sim'; // first-time SIM setup gate
  static const String home = '/home';
  static const String apiIntegration = '/api-integration';
  static const String appLogs = '/app-logs';

  static final router = GoRouter(
    initialLocation: splash,
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
      GoRoute(
        path: apiIntegration,
        builder: (context, state) => const ApiIntegrationScreen(),
      ),
      GoRoute(
        path: appLogs,
        builder: (context, state) => const AppLogsScreen(),
      ),
    ],
  );
}
