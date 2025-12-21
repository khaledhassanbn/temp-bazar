// lib/authentication/pages/signin_with_mail.dart
import 'package:bazar_suez/authentication/model/userModel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewModel/AuthViewModel.dart';
import '../guards/AuthGuard.dart';
import '../../authentication/pages/widget/custom_password_field.dart';
import '../../authentication/pages/widget/custom_textfield.dart';
import '../../widgets/custom_back_button.dart'; // ✅ زر الرجوع الموحد
import '../../widgets/primary_button.dart'; // ✅ زرار أساسي موحد

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50),

              // ✅ زرار الرجوع ثابت على الشمال
              const CustomBackButton(),

              const SizedBox(height: 30),

              const Text(
                "تسجيل الدخول عبر البريد الإلكتروني",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // حقل البريد الإلكتروني
              CustomTextField(
                controller: _emailController,
                label: "البريد الإلكتروني",
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email, color: Colors.black),
              ),

              const SizedBox(height: 20),

              // حقل كلمة المرور
              CustomPasswordField(
                controller: _passwordController,
                label: "كلمة المرور",
              ),

              const SizedBox(height: 30),

              // ✅ زر تسجيل الدخول موحد
              PrimaryButton(
                text: "تسجيل الدخول",
                isLoading: authVM.isLoading,
                onPressed: () async {
                  if (_emailController.text.trim().isEmpty ||
                      _passwordController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("من فضلك أدخل البريد وكلمة المرور"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final UserModel? user = await authVM.signInWithEmail(
                    _emailController.text.trim(),
                    _passwordController.text.trim(),
                  );

                  if (user != null) {
                    // تحميل حالة المستخدم من Firestore
                    final authGuard = Provider.of<AuthGuard>(
                      context,
                      listen: false,
                    );
                    await authGuard.loadUserStatus();

                    // ✅ إعادة التوجيه إلى صفحة الفئات بعد تسجيل الدخول
                    context.go('/CategoriesGrid');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(authVM.errorMessage ?? "خطأ غير متوقع"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 15),

              // روابط أسفل
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLinkButton("نسيت كلمة المرور؟", () {
                    context.push('/forgot-password');
                  }),
                  const SizedBox(width: 20),
                  _buildLinkButton("تسجيل مستخدم جديد", () {
                    context.push('/register');
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkButton(String text, VoidCallback onPressed) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.black12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 0),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.black),
      ),
    );
  }
}
