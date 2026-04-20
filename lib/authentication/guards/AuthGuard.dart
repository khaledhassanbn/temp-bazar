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
  
  /// Flag to track if this ChangeNotifier has been disposed
  bool _isDisposed = false;
  
  /// Safe wrapper for notifyListeners that checks disposal state
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  AuthGuard() {
    _authSubscription = _auth.authStateChanges().listen((user) async {
      _statusSubscription?.cancel();
      _statusSubscription = null;

      if (user == null) {
        userStatus = null;
        _hasSetupLocation = false;
        _safeNotifyListeners();
        return;
      }

      await loadUserStatus();
      _startStatusListener(user.uid);
    });
  }

  User? get currentUser => _auth.currentUser;
  String? userStatus; // user | market_owner
  bool _hasSetupLocation = false;
  String? _marketId;

  /// ✅ معرّف متجر المستخدم (إن وُجد)
  String? get marketId => _marketId;

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
        final dynamic mid = data?['market_id'] ?? data?['marketId'];
        _marketId = mid is String && mid.isNotEmpty ? mid : null;
        debugPrint('✅ User status loaded: $userStatus, hasSetupLocation: $_hasSetupLocation');
      } else {
        userStatus = 'user';
        _hasSetupLocation = false;
        _marketId = null;
        debugPrint('⚠️ User document not found, defaulting to user');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading user status: $e');
      userStatus = 'user';
      _hasSetupLocation = false;
      _marketId = null;
    }

    _safeNotifyListeners();
  }

  /// 🔹 تحديث حالة إعداد الموقع
  void updateLocationSetupStatus(bool hasSetup) {
    _hasSetupLocation = hasSetup;
    _safeNotifyListeners();
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
            final dynamic mid = data?['market_id'] ?? data?['marketId'];
            final String? newMarketId =
                mid is String && mid.isNotEmpty ? mid : null;
            
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
            if (newMarketId != _marketId) {
              _marketId = newMarketId;
              debugPrint('🔄 marketId updated: $_marketId');
              changed = true;
            }
            
            if (changed) {
              _safeNotifyListeners();
            }
          }
        });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}

