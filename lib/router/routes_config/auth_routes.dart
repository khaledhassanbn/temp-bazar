import 'package:go_router/go_router.dart';
import 'package:bazar_suez/authentication/pages/forget_password.dart';
import 'package:bazar_suez/authentication/pages/onboarding_screen.dart';

final authRoutes = [
  GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
  GoRoute(path: '/login', redirect: (_, __) => '/'),
  GoRoute(path: '/login-email', redirect: (_, __) => '/'),
  GoRoute(path: '/register', redirect: (_, __) => '/'),
  GoRoute(
    path: '/forgot-password',
    builder: (_, __) => const ForgotPasswordPage(),
  ),
];
