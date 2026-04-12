import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/store_service.dart';
import '../../create_market/models/working_hours.dart';
import '../../create_market/models/store_model.dart';

class StoreAdminProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? avatarUrl;

  const StoreAdminProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  String get initials {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'م';
    final parts = trimmed.split(' ');
    if (parts.length >= 2) {
      return '${parts[0].isNotEmpty ? parts[0][0] : ''}${parts[1].isNotEmpty ? parts[1][0] : ''}'
          .trim()
          .toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }
}

class EditStoreViewModel extends ChangeNotifier {
  final StoreService _service = StoreService();

  String name = '';
  String description = '';
  String link = ''; // لا يمكن تعديله
  String phone = '';
  String facebook = '';
  String instagram = '';
  LatLng? location;
  File? logoFile;
  File? coverFile;
  String? existingLogoUrl;
  String? existingCoverUrl;
  DateTime? createdAt;
  bool loading = false;
  bool showAddress = false;
  bool available = true;

  // حقول الفئات
  String? selectedCategoryId;
  String? selectedCategoryNameAr;
  String? selectedSubCategoryId;
  String? selectedSubCategoryNameAr;

  // مواعيد العمل
  WeeklyWorkingHours? workingHours;

  // بيانات الخطة المختارة
  int numberOfProducts = 0;
  String? selectedDuration;

  // إضافة admin
  String adminEmail = '';
  bool addingAdmin = false;

  /// تحميل بيانات المتجر من Firestore
  Future<void> loadStoreData(String storeId) async {
    loading = true;
    notifyListeners();

    try {
      final doc = await _service.getStore(storeId);
      if (!doc.exists) {
        throw 'المتجر غير موجود';
      }

      final data = doc.data() as Map<String, dynamic>;
      final store = StoreModel.fromMap(doc.id, data);

      // تعبئة البيانات
      name = store.name;
      description = store.description;
      link = store.link;
      phone = store.phone;
      facebook = store.facebook ?? '';
      instagram = store.instagram ?? '';
      existingLogoUrl = store.logoUrl;
      existingCoverUrl = store.coverUrl;
      showAddress = data['show_adress'] ?? false;
      selectedCategoryId = store.storeType == 'online'
          ? null
          : data['categoryId'];
      selectedCategoryNameAr = data['categoryNameAr'];
      selectedSubCategoryId = data['subCategoryId'];
      selectedSubCategoryNameAr = data['subCategoryNameAr'];
      workingHours = store.workingHours;
      numberOfProducts = store.numberOfProducts;
      createdAt = store.createdAt;
      available = data['available'] is bool
          ? data['available'] as bool
          : store.storeStatus;

      if (store.location != null) {
        location = LatLng(store.location!.latitude, store.location!.longitude);
      }
    } catch (e) {
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setName(String v) {
    name = v;
    notifyListeners();
  }

  void setDescription(String v) {
    description = v;
    notifyListeners();
  }

  void setPhone(String v) {
    phone = v;
    notifyListeners();
  }

  void setFacebook(String v) {
    facebook = v;
    notifyListeners();
  }

  void setInstagram(String v) {
    instagram = v;
    notifyListeners();
  }

  void setLogo(File f) {
    logoFile = f;
    notifyListeners();
  }

  void setCover(File f) {
    coverFile = f;
    notifyListeners();
  }

  void setLocation(LatLng? latlng) {
    location = latlng;
    notifyListeners();
  }

  void setShowAddress(bool value) {
    showAddress = value;
    notifyListeners();
  }

  void setAvailable(bool value) {
    available = value;
    notifyListeners();
  }

  void setSelectedCategory(String? categoryId, {String? categoryNameAr}) {
    selectedCategoryId = categoryId;
    selectedCategoryNameAr = categoryNameAr;
    selectedSubCategoryId = null;
    selectedSubCategoryNameAr = null;
    notifyListeners();
  }

  void setSelectedSubCategory(
    String? subCategoryId, {
    String? subCategoryNameAr,
  }) {
    selectedSubCategoryId = subCategoryId;
    selectedSubCategoryNameAr = subCategoryNameAr;
    notifyListeners();
  }

  void setWorkingHours(WeeklyWorkingHours? hours) {
    workingHours = hours;
    notifyListeners();
  }

  void setAdminEmail(String email) {
    adminEmail = email.trim();
    notifyListeners();
  }

  String? validateAll() {
    if (description.isEmpty) return 'وصف المتجر مطلوب';
    if (phone.isEmpty) return 'رقم الهاتف مطلوب';
    if (phone.length != 11) return 'رقم الهاتف يجب أن يكون 11 رقم';
    if (location == null) return 'اختر موقع المتجر';
    return null;
  }

  /// إضافة admin جديد للمتجر
  Future<String> addAdmin(String marketId) async {
    if (adminEmail.isEmpty) {
      throw 'الرجاء إدخال البريد الإلكتروني';
    }

    addingAdmin = true;
    notifyListeners();

    try {
      // البحث عن المستخدم بالبريد الإلكتروني
      final userDoc = await _service.findUserByEmail(adminEmail);

      if (userDoc == null) {
        throw 'البريد الإلكتروني غير موجود في قاعدة البيانات';
      }

      final userData = userDoc.data();
      if (userData == null) {
        throw 'بيانات المستخدم غير موجودة';
      }

      final userStatus = userData['status'] as String? ?? 'user';

      // التحقق من حالة المستخدم
      if (userStatus == 'market_owner') {
        throw 'عذرا هذا الحاسب مالك لمتجر أخر';
      }

      if (userStatus != 'user') {
        throw 'حالة المستخدم غير صالحة';
      }

      // تحديث حالة المستخدم إلى market_owner وإضافة market_id
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .update({'status': 'market_owner', 'market_id': marketId});

      adminEmail = ''; // مسح الحقل بعد النجاح
      addingAdmin = false;
      notifyListeners();
      return 'تم إضافة المدير بنجاح';
    } catch (e) {
      addingAdmin = false;
      notifyListeners();
      rethrow;
    }
  }

  Stream<List<StoreAdminProfile>> watchAdmins(String marketId) {
    final users = FirebaseFirestore.instance.collection('users');
    final primary = users.where('market_id', isEqualTo: marketId).snapshots();

    return primary.asyncMap((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map(_mapAdminDoc).toList();
      }

      final fallback = await users.where('marketId', isEqualTo: marketId).get();
      if (fallback.docs.isNotEmpty) {
        return fallback.docs.map(_mapAdminDoc).toList();
      }

      return <StoreAdminProfile>[];
    });
  }

  Future<void> removeAdmin(String uid, {required int currentCount}) async {
    if (currentCount <= 1) {
      throw 'يجب أن يبقى مدير واحد على الأقل';
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'status': 'user',
      'market_id': FieldValue.delete(),
      'marketId': FieldValue.delete(),
      'market': FieldValue.delete(),
    });
  }

  StoreAdminProfile _mapAdminDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final firstName = (data['firstName'] as String?) ?? '';
    final lastName = (data['lastName'] as String?) ?? '';
    final displayName = [
      firstName,
      lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    final fallbackName = (data['displayName'] as String?) ?? 'مدير';

    return StoreAdminProfile(
      uid: doc.id,
      email: (data['email'] as String?) ?? '',
      displayName: displayName.isNotEmpty ? displayName : fallbackName,
      avatarUrl: data['avatarUrl'] as String?,
    );
  }

  Future<void> updateAvailability(String storeId, bool value) async {
    available = value;
    notifyListeners();
    await FirebaseFirestore.instance.collection('markets').doc(storeId).update({
      'available': value,
      'storeStatus': value,
    });
  }

  /// تحديث بيانات المتجر
  Future<void> updateStore(String storeId) async {
    final error = validateAll();
    if (error != null) throw error;
    loading = true;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'description': description,
        'phone': phone,
        'facebook': facebook.isNotEmpty ? facebook : null,
        'instagram': instagram.isNotEmpty ? instagram : null,
        'location': location != null
            ? GeoPoint(location!.latitude, location!.longitude)
            : null,
        'show_adress': showAddress,
        'available': available,
        'storeStatus': available,
        'workingHours': workingHours?.toMap(),
      };

      await _service.updateStoreDocument(
        storeId,
        payload,
        logo: logoFile,
        cover: coverFile,
      );

      // تحديث الفئات إذا تغيرت
      // يمكن إضافة منطق تحديث الفئات هنا إذا لزم الأمر

      loading = false;
      notifyListeners();
    } catch (e) {
      loading = false;
      notifyListeners();
      rethrow;
    }
  }
}
