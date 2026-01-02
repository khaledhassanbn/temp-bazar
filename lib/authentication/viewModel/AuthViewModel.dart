// lib/authentication/viewmodel/authViewModel.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/userModel.dart';
import '../service/service.dart';
import 'package:bazar_suez/services/fcm_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  // ====== Sign Up ======
  Future<UserModel?> signUp(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    _setLoading(true);
    errorMessage = null;
    try {
      currentUser = await _authService.signUp(
        email,
        password,
        firstName,
        lastName,
      );
      // حفظ FCM token للمستخدم الجديد
      await FcmService().saveTokenForCurrentUser();
      return currentUser;
    } catch (e) {
      errorMessage = _handleError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ====== Sign In بالبريد ======
  Future<UserModel?> signInWithEmail(String email, String password) async {
    _setLoading(true);
    errorMessage = null;
    try {
      currentUser = await _authService.signInWithEmail(email, password);
      // حفظ FCM token للمستخدم
      await FcmService().saveTokenForCurrentUser();
      return currentUser;
    } catch (e) {
      errorMessage = _handleError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ====== Sign In بجوجل ======
  Future<UserModel?> signInWithGoogle() async {
    _setLoading(true);
    errorMessage = null;
    try {
      currentUser = await _authService.signInWithGoogle();
      // حفظ FCM token للمستخدم
      await FcmService().saveTokenForCurrentUser();
      return currentUser;
    } catch (e) {
      errorMessage = _handleError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ====== Sign In بالفيسبوك ======
  // ملاحظة: دالة تسجيل الدخول بالفيسبوك غير متوفرة حالياً في AuthService
  Future<UserModel?> signInWithFacebook() async {
    _setLoading(true);
    errorMessage = null;
    try {
      // TODO: إضافة دالة signInWithFacebook في AuthService
      errorMessage = "تسجيل الدخول بالفيسبوك غير متوفر حالياً";
      return null;
    } catch (e) {
      errorMessage = _handleError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ====== Reset Password ======
  Future<void> resetPassword(String email) async {
    _setLoading(true);
    errorMessage = null;
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      errorMessage = _handleError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ====== Sign Out ======
  Future<void> signOut() async {
    await _authService.signOut();
    currentUser = null;
    notifyListeners();
  }

  // ====== تحميل حالة المستخدم من Firestore ======
  Future<String?> getUserStatus() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data()?['status'] ?? 'user';
      }
      return 'user';
    } catch (e) {
      debugPrint('⚠️ Error loading user status: $e');
      return 'user';
    }
  }

  // ====== Helpers ======
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // فلتر الأخطاء عشان الرسالة تطلع أوضح للمستخدم
  String _handleError(String error) {
    if (error.contains("البريد الإلكتروني غير مسجل")) {
      return "البريد الإلكتروني غير مسجل";
    } else if (error.contains("كلمة المرور غير صحيحة")) {
      return "كلمة المرور غير صحيحة";
    } else if (error.contains("صيغة البريد الإلكتروني غير صحيحة")) {
      return "صيغة البريد الإلكتروني غير صحيحة";
    } else if (error.contains("weak-password")) {
      return "كلمة المرور ضعيفة جدًا";
    } else if (error.contains("email-already-in-use")) {
      return "هذا البريد مسجل بالفعل";
    } else {
      return "حدث خطأ غير متوقع";
    }
  }
}
