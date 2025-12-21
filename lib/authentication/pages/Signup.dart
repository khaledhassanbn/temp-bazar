// lib/authentication/pages/register_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../viewModel/AuthViewModel.dart';
import '../../widgets/custom_back_button.dart';
import '../../widgets/primary_button.dart';
import '../../authentication/pages/widget/custom_textfield.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50),

              // ✅ زر الرجوع
              const CustomBackButton(),

              const SizedBox(height: 30),

              const Text(
                "تسجيل مستخدم جديد",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // ✅ الاسم
              CustomTextField(
                controller: _nameController,
                label: "الاسم",
                prefixIcon: const Icon(Icons.person, color: Colors.black),
              ),

              const SizedBox(height: 20),

              // ✅ البريد الإلكتروني
              CustomTextField(
                controller: _emailController,
                label: "البريد الإلكتروني",
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email, color: Colors.black),
              ),

              const SizedBox(height: 20),

              // ✅ كلمة المرور
              CustomTextField(
                controller: _passwordController,
                label: "كلمة المرور",
                obscureText: true,
                prefixIcon: const Icon(Icons.lock, color: Colors.black),
              ),

              const SizedBox(height: 30),

              // ✅ زر التسجيل
              PrimaryButton(
                text: "تسجيل",
                isLoading: authVM.isLoading,
                onPressed: () async {
                  if (_nameController.text.trim().isEmpty ||
                      _emailController.text.trim().isEmpty ||
                      _passwordController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("من فضلك املأ جميع الحقول"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  await authVM.signUp(
                    _emailController.text.trim(),
                    _passwordController.text.trim(),
                    _nameController.text.trim(),
                    "", // ممكن تخليها لقب أو سيبها فاضية
                  );

                  if (authVM.errorMessage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("تم التسجيل بنجاح 🎉"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    context.pop(); // يرجع لصفحة تسجيل الدخول
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
