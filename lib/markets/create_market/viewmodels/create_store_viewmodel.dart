import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/store_service.dart';
// Removed global CategoriesService linking. Categories now live under each market.
import '../models/working_hours.dart';
import '../../../services/time_service.dart';
import '../services/categories_service.dart';
import '../../planes/services/pending_payment_service.dart';

class CreateStoreViewModel extends ChangeNotifier {
  final StoreService _service = StoreService();
  final PendingPaymentService _pendingPaymentService = PendingPaymentService();

  String name = '';
  String description = '';
  String link = '';
  String phone = '';
  String facebook = '';
  String instagram = '';
  LatLng? location; // ← نخزن الإحداثيات فقط
  File? logoFile;
  File? coverFile;
  bool loading = false;
  bool showAddress = false;
  bool autoRenewEnabled = true;

  // حقول الفئات
  String? selectedCategoryId;
  String? selectedCategoryNameAr;
  String? selectedSubCategoryId;
  String? selectedSubCategoryNameAr;

  // مواعيد العمل
  WeeklyWorkingHours? workingHours;

  // بيانات الخطة المختارة
  int numberOfProducts = 0;
  String? selectedDuration; // المدة المختارة (1m, 3m, 6m, 12m)
  String? packageId; // معرف الباقة من Paymob
  int? packageDays; // عدد أيام الباقة

  void setName(String v) {
    name = v;
    notifyListeners();
  }

  void setDescription(String v) {
    description = v;
    notifyListeners();
  }

  void setLink(String v) {
    link = v
        .trim()
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r"[^A-Za-z0-9\-]"), '')
        .toLowerCase();
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

  void setSelectedCategory(String? categoryId, {String? categoryNameAr}) {
    selectedCategoryId = categoryId;
    selectedCategoryNameAr = categoryNameAr;
    // إعادة تعيين التصنيف الفرعي عند تغيير الفئة الرئيسية
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

  // تعيين بيانات الخطة المختارة
  void setPlanData(int products, String duration) {
    numberOfProducts = products;
    selectedDuration = duration;
    notifyListeners();
  }

  /// يعين حالة التجديد التلقائي (تستخدم في صفحات الترخيص/المحفظة)
  void setAutoRenewEnabled(bool value) {
    autoRenewEnabled = value;
    notifyListeners();
  }

  int _resolveDurationDays() {
    if (packageDays != null && packageDays! > 0) {
      return packageDays!;
    }

    switch (selectedDuration) {
      case 'شهر':
        return 30;
      case '3 شهور':
        return 90;
      case '6 شهور':
        return 180;
      case 'سنة':
        return 365;
      default:
        return 30; // fallback شهر واحد
    }
  }

  DateTime _calculateLicenseEnd(DateTime startAt) {
    final durationDays = _resolveDurationDays();
    return startAt.add(Duration(days: durationDays));
  }

  // التحقق من صحة رابط المتجر
  Future<String?> validateStoreLink(String linkValue) async {
    if (linkValue.isEmpty) return null;

    try {
      final linkExists = await _service.isStoreLinkExists(linkValue);
      if (linkExists) {
        return 'رابط المتجر "$linkValue" موجود بالفعل';
      }
    } catch (e) {
      return 'خطأ في التحقق من الرابط';
    }

    return null;
  }

  String? validateAll() {
    if (name.isEmpty) return 'اسم المتجر مطلوب';
    if (description.isEmpty) return 'وصف المتجر مطلوب';
    if (link.isEmpty) return 'لينك المتجر مطلوب';
    if (phone.isEmpty) return 'رقم الهاتف مطلوب';
    if (phone.length != 11) return 'رقم الهاتف يجب أن يكون 11 رقم';
    if (selectedCategoryId == null || selectedCategoryId!.isEmpty) {
      return 'اختر الفئة الرئيسية';
    }
    if (location == null) return 'اختر موقع المتجر';
    return null;
  }

  Future<String> createStore(DateTime created) async {
    final error = validateAll();
    if (error != null) throw error;
    loading = true;
    notifyListeners();

    try {
      // الحصول على الوقت من السيرفر
      final serverTime = await TimeService.getValidatedTime();

      // التحقق من وجود رابط المتجر قبل الإنشاء
      final linkExists = await _service.isStoreLinkExists(link);
      if (linkExists) {
        loading = false;
        notifyListeners();
        throw 'رابط المتجر "$link" موجود بالفعل. يرجى اختيار رابط آخر.';
      }

      // Get current user email
      final currentUser = FirebaseAuth.instance.currentUser;
      final userEmail = currentUser?.email ?? '';

      // جلب بيانات الدفع المعلق أولاً قبل حساب تاريخ انتهاء الترخيص
      // حتى نستخدم عدد الأيام الصحيح من الباقة
      dynamic cachedPendingPayment;
      if (currentUser != null) {
        try {
          cachedPendingPayment = await _pendingPaymentService.getPendingPayment(
            currentUser.uid,
          );
          if (cachedPendingPayment != null && cachedPendingPayment.isValid) {
            // تحديث بيانات الباقة في ViewModel
            packageId = cachedPendingPayment.packageId;
            packageDays = cachedPendingPayment.days;
          }
        } catch (e) {
          print('خطأ في جلب بيانات الدفع المعلق: $e');
        }
      }

      final now = serverTime;
      // الآن سيتم استخدام packageDays الصحيح من الباقة
      final licenseEndAt = _calculateLicenseEnd(now);
      final durationDays = _resolveDurationDays();

      final payload = {
        'name': name,
        'description': description,
        'link': link,
        'phone': phone,
        'email': userEmail, // Use current user's email
        'facebook': facebook.isNotEmpty ? facebook : null,
        'instagram': instagram.isNotEmpty ? instagram : null,
        'location': location != null
            ? GeoPoint(location!.latitude, location!.longitude)
            : null,
        'show_adress': showAddress,
        'storeStatus': true, // حالة المتجر - افتراضياً true
        'status': 'active', // حالة العرض - افتراضياً active
        'isVisible': true, // إظهار المتجر - افتراضياً true
        'expiredAt': Timestamp.fromDate(licenseEndAt), // الحقل القديم للتوافق
        'renewedAt': null, // تاريخ التجديد - افتراضياً null (قديم للتوافق)
        'createdAt': Timestamp.fromDate(now), // استخدام وقت السيرفر
        // حقول الترخيص الجديدة
        'ownerId': FirebaseAuth.instance.currentUser?.uid,
        'licenseStartAt': Timestamp.fromDate(now),
        'licenseEndAt': Timestamp.fromDate(licenseEndAt),
        'licenseDurationDays': durationDays,
        'licenseAutoRenew': autoRenewEnabled,
        'licenseLastRenewedAt': null,
        'currentPackageId': packageId,
        'isActive': true,
        'canAddProducts': true,
        'canReceiveOrders': true,
        'subscription': {
          'packageName': null,
          'startDate': Timestamp.fromDate(now),
          'endDate': Timestamp.fromDate(licenseEndAt),
          'durationDays': durationDays,
        },
        'expiryDate': Timestamp.fromDate(licenseEndAt), // لتوافق وظائف السحابة الحالية
        'numberOfProducts': numberOfProducts, // عدد المنتجات المسموح بها
        // معلومات الفئات
        'categoryId': selectedCategoryId,
        'categoryNameAr': selectedCategoryNameAr,
        'subCategoryId': selectedSubCategoryId,
        'subCategoryNameAr': selectedSubCategoryNameAr,
        // مواعيد العمل
        'workingHours': workingHours?.toMap(),
      };

      final docId = await _service.createStoreDocument(
        payload,
        logo: logoFile,
        cover: coverFile,
      );

      // ربط الدفع المعلق بالمتجر إذا كان موجوداً
      if (currentUser != null && cachedPendingPayment != null && cachedPendingPayment.isValid) {
        try {
          await _pendingPaymentService.linkPaymentToStore(
            cachedPendingPayment.id,
            docId,
          );
          await FirebaseFirestore.instance
              .collection('markets')
              .doc(docId)
              .set({
            'currentPackageId': cachedPendingPayment.packageId,
            'currentPackageName': cachedPendingPayment.packageName,
            'licenseDurationDays': cachedPendingPayment.days,
            'subscription': {
              'packageId': cachedPendingPayment.packageId,
              'packageName': cachedPendingPayment.packageName,
              'startDate': Timestamp.fromDate(now),
              'endDate': Timestamp.fromDate(licenseEndAt),
              'durationDays': cachedPendingPayment.days,
            },
          }, SetOptions(merge: true));
        } catch (e) {
          // لا نفشل إنشاء المتجر لو فشل ربط الدفع
          print('خطأ في ربط الدفع المعلق: $e');
        }
      }

      // تحديث مستند المستخدم ليحوي بيانات المتجر الجديد
      if (currentUser != null) {
        final userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid);
        await userDocRef.set({
          'market_id': link,
          'status': 'market_owner',
        }, SetOptions(merge: true));
      }

      // بعد إنشاء المتجر: أضف الرابط إلى الفئة والتصنيف الفرعي وزِد العداد
      try {
        if (selectedCategoryId != null && selectedCategoryId!.isNotEmpty) {
          await CategoriesService.pushStoreLinkToCategoryAndIncrement(
            selectedCategoryId!,
            link,
          );
        }
        if (selectedCategoryId != null &&
            selectedCategoryId!.isNotEmpty &&
            selectedSubCategoryId != null &&
            selectedSubCategoryId!.isNotEmpty) {
          await CategoriesService.pushStoreLinkToSubCategoryAndIncrement(
            selectedCategoryId!,
            selectedSubCategoryId!,
            link,
          );
        }
      } catch (e) {
        // لا نفشل إنشاء المتجر لو فشل التحديث داخل الفئات
      }

      // لم نعد نضيف روابط المتاجر داخل مجموعة فئات عامة.
      // الفئات أصبحت فرعية لكل متجر ضمن markets/{marketId}/categories.

      loading = false;
      notifyListeners();
      return docId;
    } catch (e) {
      loading = false;
      notifyListeners();
      rethrow;
    }
  }
}
