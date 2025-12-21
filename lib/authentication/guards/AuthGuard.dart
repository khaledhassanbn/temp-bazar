import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// AuthGuard كلاس لإدارة حالة تسجيل الدخول وحالة المستخدم
class AuthGuard extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _statusSubscription;

  AuthGuard() {
    _authSubscription = _auth.authStateChanges().listen((user) async {
      _statusSubscription?.cancel();
      _statusSubscription = null;

      if (user == null) {
        userStatus = null;
        _hasSetupLocation = false;
        notifyListeners();
        return;
      }

      await loadUserStatus();
      _startStatusListener(user.uid);
    });
  }

  User? get currentUser => _auth.currentUser;
  String? userStatus; // user | market_owner
  bool _hasSetupLocation = false;

  /// ✅ هل المستخدم داخل التطبيق؟
  bool get isAuthenticated => currentUser != null;

  /// ✅ هل المستخدم صاحب متجر؟
  bool get isMarketOwner => userStatus == 'market_owner';

  /// ✅ هل المستخدم أعد الموقع؟
  bool get hasSetupLocation => _hasSetupLocation;

  /// ✅ هل يحتاج المستخدم لإعداد الموقع؟
  bool get needsLocationSetup => isAuthenticated && !_hasSetupLocation;

  /// 🔹 تحميل حالة المستخدم عند التشغيل
  Future<void> loadUserStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      userStatus = null;
      _hasSetupLocation = false;
      debugPrint('👤 No user logged in');
      return;
    }

    try {
      debugPrint('👤 Loading status for user: ${user.uid}');
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        userStatus = data?['status'] ?? 'user';
        _hasSetupLocation = data?['hasSetupLocation'] ?? false;
        debugPrint('✅ User status loaded: $userStatus, hasSetupLocation: $_hasSetupLocation');
      } else {
        userStatus = 'user';
        _hasSetupLocation = false;
        debugPrint('⚠️ User document not found, defaulting to user');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading user status: $e');
      userStatus = 'user';
      _hasSetupLocation = false;
    }

    notifyListeners();
  }

  /// 🔹 تحديث حالة إعداد الموقع
  void updateLocationSetupStatus(bool hasSetup) {
    _hasSetupLocation = hasSetup;
    notifyListeners();
  }

  /// 🔹 متابعة التغييرات في حالة المستخدم من Firestore لحظيًا
  void startStatusListener() {
    final user = _auth.currentUser;
    if (user == null) return;
    _startStatusListener(user.uid);
  }

  void _startStatusListener(String uid) {
    _statusSubscription?.cancel();
    _statusSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data();
            final newStatus = data?['status'] ?? 'user';
            final newHasSetupLocation = data?['hasSetupLocation'] ?? false;
            
            bool changed = false;
            if (newStatus != userStatus) {
              userStatus = newStatus;
              debugPrint('🔄 User status updated: $userStatus');
              changed = true;
            }
            if (newHasSetupLocation != _hasSetupLocation) {
              _hasSetupLocation = newHasSetupLocation;
              debugPrint('🔄 Location setup status updated: $_hasSetupLocation');
              changed = true;
            }
            
            if (changed) {
              notifyListeners();
            }
          }
        });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}

