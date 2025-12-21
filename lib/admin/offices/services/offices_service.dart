import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/office_model.dart';

class OfficesService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// إضافة مكتب شحن جديد
  /// ينشئ حساب Firebase Auth ثم يحفظ البيانات في Firestore
  Future<Map<String, dynamic>> createOffice({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    try {
      // التحقق من صحة البيانات
      if (name.trim().isEmpty) {
        return {'success': false, 'message': 'الاسم مطلوب'};
      }
      if (email.trim().isEmpty || !email.contains('@')) {
        return {'success': false, 'message': 'البريد الإلكتروني غير صحيح'};
      }
      if (password.length < 6) {
        return {
          'success': false,
          'message': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
        };
      }
      if (phone.trim().isEmpty) {
        return {'success': false, 'message': 'رقم الهاتف مطلوب'};
      }
      if (address.trim().isEmpty) {
        return {'success': false, 'message': 'العنوان مطلوب'};
      }

      // التحقق من وجود البريد الإلكتروني سيتم تلقائياً عند محاولة إنشاء الحساب

      // إنشاء حساب Firebase Auth
      UserCredential userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          return {
            'success': false,
            'message': 'البريد الإلكتروني مستخدم بالفعل',
          };
        }
        return {
          'success': false,
          'message': 'فشل إنشاء الحساب: ${e.toString()}',
        };
      }

      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'message': 'فشل إنشاء الحساب'};
      }

      // حفظ بيانات المكتب في Firestore
      final officeData = {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'role': 'office',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(user.uid).set(officeData);

      return {
        'success': true,
        'message': 'تم إنشاء مكتب الشحن بنجاح',
        'officeId': user.uid,
      };
    } catch (e) {
      print('خطأ في إنشاء المكتب: $e');
      return {'success': false, 'message': 'حدث خطأ: ${e.toString()}'};
    }
  }

  /// تحديث بيانات المكتب
  Future<Map<String, dynamic>> updateOffice({
    required String officeId,
    String? name,
    String? phone,
    String? address,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null && name.trim().isNotEmpty) {
        updateData['name'] = name.trim();
      }
      if (phone != null && phone.trim().isNotEmpty) {
        updateData['phone'] = phone.trim();
      }
      if (address != null && address.trim().isNotEmpty) {
        updateData['address'] = address.trim();
      }

      if (updateData.length == 1) {
        // فقط updatedAt موجود، لا يوجد بيانات للتحديث
        return {'success': false, 'message': 'لا توجد بيانات للتحديث'};
      }

      await _firestore.collection('users').doc(officeId).update(updateData);

      return {'success': true, 'message': 'تم تحديث بيانات المكتب بنجاح'};
    } catch (e) {
      print('خطأ في تحديث المكتب: $e');
      return {'success': false, 'message': 'حدث خطأ: ${e.toString()}'};
    }
  }

  /// تعطيل مكتب شحن (تغيير status إلى "blocked")
  Future<Map<String, dynamic>> blockOffice(String officeId) async {
    try {
      await _firestore.collection('users').doc(officeId).update({
        'status': 'blocked',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'تم تعطيل المكتب بنجاح'};
    } catch (e) {
      print('خطأ في تعطيل المكتب: $e');
      return {'success': false, 'message': 'حدث خطأ: ${e.toString()}'};
    }
  }

  /// تفعيل مكتب شحن (تغيير status إلى "active")
  Future<Map<String, dynamic>> activateOffice(String officeId) async {
    try {
      await _firestore.collection('users').doc(officeId).update({
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'تم تفعيل المكتب بنجاح'};
    } catch (e) {
      print('خطأ في تفعيل المكتب: $e');
      return {'success': false, 'message': 'حدث خطأ: ${e.toString()}'};
    }
  }

  /// حذف مكتب شحن (حذف من Firestore و Firebase Auth)
  Future<Map<String, dynamic>> deleteOffice(String officeId) async {
    try {
      // حذف من Firestore
      await _firestore.collection('users').doc(officeId).delete();

      // ملاحظة: حذف المستخدم من Firebase Auth يتطلب صلاحيات Admin SDK
      // يمكن تنفيذ ذلك من خلال Cloud Functions
      // هنا نحذف فقط من Firestore

      return {'success': true, 'message': 'تم حذف المكتب بنجاح'};
    } catch (e) {
      print('خطأ في حذف المكتب: $e');
      return {'success': false, 'message': 'حدث خطأ: ${e.toString()}'};
    }
  }

  /// الحصول على stream لقائمة المكاتب
  /// ملاحظة: تم إزالة orderBy لتجنب الحاجة لفهرس مركب
  /// الفرز يتم في ViewModel
  Stream<QuerySnapshot> getOfficesStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'office')
        .snapshots();
  }

  /// الحصول على مكتب واحد
  Future<OfficeModel?> getOffice(String officeId) async {
    try {
      final doc = await _firestore.collection('users').doc(officeId).get();
      if (doc.exists && doc.data()?['role'] == 'office') {
        return OfficeModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('خطأ في جلب المكتب: $e');
      return null;
    }
  }
}
