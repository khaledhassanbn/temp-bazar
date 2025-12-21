// lib/authentication/pages/signin_with_social.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/authentication/viewModel/AuthViewModel.dart';
import 'package:bazar_suez/authentication/model/userModel.dart';
import 'package:bazar_suez/authentication/guards/AuthGuard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool showEmail = false;

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // الجزء العلوي المموج
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: 220,
                width: double.infinity,
                color: const Color(0xFFFFF6E9),
                child: const Center(child: FlutterLogo(size: 100)),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "مرحباً!",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "قم بتسجيل الدخول أو الاشتراك واحصل على تجربة طلب مخصصة لك.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 30),

            // زر جوجل
            _buildButton(
              text: "إستمرار عبر جوجل",
              icon: FontAwesomeIcons.google,
              color: Colors.red,
              onPressed: () async {
                final UserModel? user = await authVM.signInWithGoogle();
                if (user != null) {
                  // تحميل حالة المستخدم لضمان بناء الواجهة الصحيحة
                  final authGuard = Provider.of<AuthGuard>(
                    context,
                    listen: false,
                  );
                  await authGuard.loadUserStatus();

                  // ✅ إعادة التوجيه إلى صفحة الفئات بعد تسجيل الدخول
                  context.go('/CategoriesGrid');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("فشل تسجيل الدخول بجوجل")),
                  );
                }
              },
            ),

            const SizedBox(height: 12),

            // زر فيسبوك
            _buildButton(
              text: "إستمرار عبر الفيسبوك",
              icon: FontAwesomeIcons.facebook,
              color: Colors.blue,
              onPressed: () async {
                final UserModel? user = await authVM.signInWithFacebook();
                if (user != null) {
                  // تحميل حالة المستخدم لضمان بناء الواجهة الصحيحة
                  final authGuard = Provider.of<AuthGuard>(
                    context,
                    listen: false,
                  );
                  await authGuard.loadUserStatus();

                  // ✅ إعادة التوجيه إلى صفحة الفئات بعد تسجيل الدخول
                  context.go('/CategoriesGrid');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("فشل تسجيل الدخول بالفيسبوك")),
                  );
                }
              },
            ),

            const SizedBox(height: 12),

            if (showEmail)
              Column(
                children: [
                  _buildButton(
                    text: "إستمرار عبر الإيميل",
                    icon: Icons.email,
                    color: Colors.grey.shade800,
                    onPressed: () {
                      context.push('/login-email');
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),

            if (!showEmail)
              GestureDetector(
                onTap: () {
                  setState(() {
                    showEmail = true;
                  });
                },
                child: const Text(
                  "المزيد",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            side: const BorderSide(color: Colors.black12),
          ),
          onPressed: onPressed,
          icon: Icon(icon, color: color, size: 20),
          label: Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      ),
    );
  }
}

// كليبـر يعمل الموجة
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 40);

    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 80);
    var secondEndPoint = Offset(size.width, size.height - 40);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
