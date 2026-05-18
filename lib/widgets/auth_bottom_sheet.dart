import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:bazar_suez/authentication/model/userModel.dart';
import 'package:bazar_suez/authentication/viewModel/AuthViewModel.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

enum _AuthMode { login, register }

/// يعرض ورقة تسجيل الدخول / إنشاء الحساب بدلاً من الانتقال لصفحة منفصلة.
///
/// بعد نجاح الدخول: تُغلق الورقة ثم يُنفَّذ [pendingLocation] أو [onAuthenticated].
Future<void> showAuthBottomSheet(
  BuildContext context, {
  String? message,
  String? pendingLocation,
  bool pendingUseGo = false,
  VoidCallback? onAuthenticated,
}) {
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final authGuard = context.read<AuthGuard>();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _AuthBottomSheet(
      message: message,
      onAuthSuccess: (wasRegister) => _completeAuthFlow(
        sheetContext: sheetContext,
        router: router,
        messenger: messenger,
        authGuard: authGuard,
        wasRegister: wasRegister,
        pendingLocation: pendingLocation,
        pendingUseGo: pendingUseGo,
        onAuthenticated: onAuthenticated,
      ),
    ),
  );
}

Future<void> _completeAuthFlow({
  required BuildContext sheetContext,
  required GoRouter router,
  required ScaffoldMessengerState messenger,
  required AuthGuard authGuard,
  required bool wasRegister,
  String? pendingLocation,
  bool pendingUseGo = false,
  VoidCallback? onAuthenticated,
}) async {
  await authGuard.loadUserStatus();

  final navigator = Navigator.of(sheetContext);
  if (navigator.canPop()) {
    navigator.pop();
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final hasPendingRoute =
        pendingLocation != null && pendingLocation.isNotEmpty;
    if (hasPendingRoute) {
      if (pendingUseGo) {
        router.go(pendingLocation!);
      } else {
        router.push(pendingLocation!);
      }
    }
    onAuthenticated?.call();
  });

  messenger.showSnackBar(
    SnackBar(
      content: Text(
        wasRegister ? 'تم إنشاء حسابك بنجاح' : 'تم تسجيل الدخول بنجاح',
      ),
      backgroundColor: AppColors.mainColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

class _AuthBottomSheet extends StatefulWidget {
  const _AuthBottomSheet({
    this.message,
    required this.onAuthSuccess,
  });

  final String? message;
  final Future<void> Function(bool wasRegister) onAuthSuccess;

  @override
  State<_AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<_AuthBottomSheet>
    with SingleTickerProviderStateMixin {
  _AuthMode _mode = _AuthMode.login;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _obscurePassword = true;

  late final AnimationController _modeController;
  late final Animation<double> _modeFade;

  @override
  void initState() {
    super.initState();
    _modeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _modeFade = CurvedAnimation(
      parent: _modeController,
      curve: Curves.easeOutCubic,
    );
    _modeController.value = 1;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _modeController.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    _modeController.forward(from: 0);
  }

  Future<void> _submitEmail(AuthViewModel authVM) async {
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('من فضلك أدخل البريد وكلمة المرور'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_mode == _AuthMode.register) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('من فضلك أدخل اسمك'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final user = await authVM.signUp(email, password, name, '');
      if (!mounted) return;
      if (user != null) {
        await widget.onAuthSuccess(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(authVM.errorMessage ?? 'فشل التسجيل'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final UserModel? user = await authVM.signInWithEmail(email, password);
    if (!mounted) return;
    if (user != null) {
      await widget.onAuthSuccess(false);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(authVM.errorMessage ?? 'فشل تسجيل الدخول'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signInWithGoogle(AuthViewModel authVM) async {
    final messenger = ScaffoldMessenger.of(context);
    final onSuccess = widget.onAuthSuccess;
    final user = await authVM.signInWithGoogle();
    if (user != null) {
      await onSuccess(false);
    } else if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(authVM.errorMessage ?? 'فشل تسجيل الدخول بجوجل'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isLogin = _mode == _AuthMode.login;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _Header(isLogin: isLogin),
              const SizedBox(height: 8),
              Text(
                widget.message ??
                    (isLogin
                        ? 'سجّل دخولك للاستمتاع بجميع مميزات التطبيق'
                        : 'أنشئ حسابك في دقائق وابدأ التسوق'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _modeFade,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isLogin) ...[
                      _AuthField(
                        controller: _nameController,
                        label: 'الاسم الكامل',
                        icon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                    ],
                    _AuthField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    _AuthField(
                      controller: _passwordController,
                      label: 'كلمة المرور',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submitEmail(authVM),
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: Colors.grey[500],
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (isLogin) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      final router = GoRouter.of(context);
                      Navigator.of(context).pop();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        router.push('/forgot-password');
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.mainColor,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'نسيت كلمة المرور؟',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: authVM.isLoading ? null : () => _submitEmail(authVM),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.mainColor.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: authVM.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 22),
              const _OrDivider(),
              const SizedBox(height: 22),
              _GoogleButton(
                isLoading: authVM.isLoading,
                onPressed: () => _signInWithGoogle(authVM),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLogin ? 'ليس لديك حساب؟' : 'لديك حساب بالفعل؟',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () => _switchMode(
                      isLogin ? _AuthMode.register : _AuthMode.login,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.mainColor,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    child: Text(
                      isLogin ? 'سجّل الآن' : 'تسجيل الدخول',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                child: const Text('متابعة التصفح', style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isLogin});

  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.mainColor.withValues(alpha: 0.15),
                AppColors.mainColor.withValues(alpha: 0.05),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isLogin ? Icons.lock_open_rounded : Icons.person_add_alt_1_rounded,
            size: 34,
            color: AppColors.mainColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isLogin ? 'مرحباً بعودتك' : 'إنشاء حساب جديد',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.mainColor, size: 22),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF7F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.mainColor, width: 1.5),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300], height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'أو',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300], height: 1)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDADCE0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE8EAED)),
                ),
                child: const Center(child: _GoogleLogo(size: 22)),
              ),
              const SizedBox(width: 14),
              const Text(
                'المتابعة عبر Google',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3C4043),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شعار Google الرسمي متعدد الألوان (بدون صورة خارجية).
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 2.4, 1.2, true, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 0.9, 1.0, true, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, -0.6, 1.0, true, paint);

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -2.2, 1.3, true, paint);

    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.56, paint);

    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.5, h * 0.4, w * 0.5, h * 0.2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
