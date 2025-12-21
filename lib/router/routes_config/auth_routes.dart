import 'package:go_router/go_router.dart';
import 'package:bazar_suez/authentication/pages/signin_with_social.dart';
import 'package:bazar_suez/authentication/pages/signin_with_mail.dart';
import 'package:bazar_suez/authentication/pages/Signup.dart';
import 'package:bazar_suez/authentication/pages/forget_password.dart';

final authRoutes = [
  GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
  GoRoute(path: '/login-email', builder: (_, __) => const EmailLoginPage()),
  GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
  GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordPage()),
];
