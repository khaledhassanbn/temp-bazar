import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../model/userModel.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ====== إنشاء حساب بالبريد + الباسورد ======
  Future<UserModel?> signUp(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user == null) return null;

      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? "",
        firstName: firstName,
        lastName: lastName,
      );

      await _firestore
          .collection("users")
          .doc(user.uid)
          .set(userModel.toJson());

      return userModel;
    } catch (e) {
      throw Exception("فشل إنشاء الحساب: $e");
    }
  }

  // ====== تسجيل الدخول بالبريد + الباسورد ======
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user == null) return null;

      final doc = await _firestore.collection("users").doc(user.uid).get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      } else {
        return UserModel(
          uid: user.uid,
          email: user.email ?? "",
          firstName: "",
          lastName: "",
        );
      }
    } catch (e) {
      throw Exception("فشل تسجيل الدخول: $e");
    }
  }

  // ====== تسجيل الدخول بجوجل ======
  Future<UserModel?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider provider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        final googleSignIn = GoogleSignIn();

        // تأكد من فصل أي جلسة سابقة حتى يَطلب التطبيق اختيار البريد في كل مرة
        try {
          await googleSignIn.signOut();
          await googleSignIn.disconnect();
        } catch (_) {
          // تجاهل الأخطاء في حالة عدم وجود جلسة سابقة
        }

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          throw Exception("تم إلغاء تسجيل الدخول");
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user == null) return null;

      final doc = await _firestore.collection("users").doc(user.uid).get();

      if (!doc.exists) {
        final displayName = user.displayName ?? "";
        final parts = displayName.split(" ");
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? "",
          firstName: parts.isNotEmpty ? parts.first : "",
          lastName: parts.length > 1 ? parts.last : "",
        );

        await _firestore
            .collection("users")
            .doc(user.uid)
            .set(userModel.toJson());

        return userModel;
      }

      return UserModel.fromJson(doc.data()!);
    } on FirebaseAuthException catch (e) {
      print(
        'Google sign-in failed: code=${e.code}, message=${e.message ?? ''}',
      );
      if (e.code == 'sign_in_canceled') {
        throw Exception("تم إلغاء تسجيل الدخول");
      }
      throw Exception("فشل تسجيل الدخول بجوجل: ${e.code}");
    } catch (e) {
      if (e.toString().contains("تم إلغاء تسجيل الدخول")) {
        rethrow;
      }
      throw Exception("فشل تسجيل الدخول بجوجل: $e");
    }
  }

  // ====== إعادة تعيين كلمة المرور ======
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception("فشل إرسال رابط إعادة تعيين كلمة المرور: $e");
    }
  }

  // ====== تسجيل الخروج ======
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        final googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      }
    } catch (e) {
      throw Exception("فشل تسجيل الخروج: $e");
    }
  }

  // ====== المستخدم الحالي ======
  User? get currentUser => _auth.currentUser;
}
