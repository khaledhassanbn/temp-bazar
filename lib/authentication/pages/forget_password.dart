// lib/authentication/pages/forgot_password_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../viewModel/AuthViewModel.dart';
import '../../widgets/custom_back_button.dart';   // ✅ زر الرجوع الموحد
import '../../widgets/primary_button.dart';      // ✅ زرار أساسي موحد
import '../../authentication/pages/widget/custom_textfield.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

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

              // ✅ زر رجوع ثابت
              const CustomBackButton(),

              const SizedBox(height: 30),

              const Text(
                "استعادة كلمة المرور",
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

              const SizedBox(height: 30),

              // ✅ زر إرسال موحد
              PrimaryButton(
                text: "إرسال رابط الاستعادة",
                isLoading: authVM.isLoading,
                onPressed: () async {
                  if (_emailController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("من فضلك أدخل البريد الإلكتروني"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  await authVM.resetPassword(_emailController.text.trim());

                  if (authVM.errorMessage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("تم إرسال رابط إعادة تعيين كلمة المرور لبريدك"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    context.pop(); // ✅ يرجع لصفحة تسجيل الدخول
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(authVM.errorMessage!),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
