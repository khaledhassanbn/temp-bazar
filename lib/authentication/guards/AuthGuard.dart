import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bazar_suez/admin/security/models/admin_permission.dart';
import 'package:bazar_suez/admin/security/models/admin_role.dart';
import 'package:bazar_suez/admin/security/services/admin_permission_service.dart';

/// AuthGuard كلاس لإدارة حالة تسجيل الدخول وحالة المستخدم
class AuthGuard extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final AdminPermissionService _permissionService = AdminPermissionService();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _statusSubscription;

  bool _isDisposed = false;

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
        adminRole = null;
        _hasSetupLocation = false;
        _permissionService.clear();
        _safeNotifyListeners();
        return;
      }

      await loadUserStatus();
      _startStatusListener(user.uid);
    });
  }

  User? get currentUser => _auth.currentUser;
  String? userStatus;
  AdminRoleType? adminRole;
  bool _hasSetupLocation = false;
  String? _marketId;

  String? get marketId => _marketId;
  bool get isAuthenticated => currentUser != null;
  bool get isMarketOwner => userStatus == 'market_owner';
  bool get isAdmin => userStatus == 'admin';
  bool get hasSetupLocation => _hasSetupLocation;
  bool get needsLocationSetup => isAuthenticated && !_hasSetupLocation;
  bool get isSuperAdmin => isAdmin && _permissionService.isSuperAdmin;

  bool hasPermission(AdminPermission permission) {
    if (!isAdmin) return false;
    return _permissionService.hasPermission(permission);
  }

  AdminPermissionService get permissionService => _permissionService;

  Future<void> loadUserStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      userStatus = null;
      adminRole = null;
      _hasSetupLocation = false;
      _permissionService.clear();
      debugPrint('👤 No user logged in');
      return;
    }

    try {
      debugPrint('👤 Loading status for user: ${user.uid}');
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data?['isDeleted'] == true) {
          userStatus = null;
          adminRole = null;
          _permissionService.clear();
          debugPrint('⚠️ User account is soft-deleted');
          _safeNotifyListeners();
          return;
        }
        userStatus = data?['status'] ?? 'user';
        adminRole = AdminRoleType.fromKey(data?['adminRole'] as String?);
        _hasSetupLocation = data?['hasSetupLocation'] ?? false;
        final dynamic mid = data?['market_id'] ?? data?['marketId'];
        _marketId = mid is String && mid.isNotEmpty ? mid : null;

        if (userStatus == 'admin') {
          await _permissionService.loadForUid(user.uid);
        } else {
          _permissionService.clear();
        }

        debugPrint(
          '✅ User status loaded: $userStatus, adminRole: $adminRole',
        );
      } else {
        userStatus = 'user';
        adminRole = null;
        _hasSetupLocation = false;
        _marketId = null;
        _permissionService.clear();
        debugPrint('⚠️ User document not found, defaulting to user');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading user status: $e');
      userStatus = 'user';
      adminRole = null;
      _hasSetupLocation = false;
      _marketId = null;
      _permissionService.clear();
    }

    _safeNotifyListeners();
  }

  void updateLocationSetupStatus(bool hasSetup) {
    _hasSetupLocation = hasSetup;
    _safeNotifyListeners();
  }

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
        .listen((snapshot) async {
          if (snapshot.exists) {
            final data = snapshot.data();
            if (data?['isDeleted'] == true) {
              userStatus = null;
              adminRole = null;
              _permissionService.clear();
              _safeNotifyListeners();
              return;
            }

            final newStatus = data?['status'] ?? 'user';
            final newAdminRole =
                AdminRoleType.fromKey(data?['adminRole'] as String?);
            final newHasSetupLocation = data?['hasSetupLocation'] ?? false;
            final dynamic mid = data?['market_id'] ?? data?['marketId'];
            final String? newMarketId =
                mid is String && mid.isNotEmpty ? mid : null;

            bool changed = false;
            if (newStatus != userStatus) {
              userStatus = newStatus;
              changed = true;
            }
            if (newAdminRole != adminRole) {
              adminRole = newAdminRole;
              changed = true;
            }
            if (newHasSetupLocation != _hasSetupLocation) {
              _hasSetupLocation = newHasSetupLocation;
              changed = true;
            }
            if (newMarketId != _marketId) {
              _marketId = newMarketId;
              changed = true;
            }

            if (newStatus == 'admin') {
              await _permissionService.loadForUid(uid);
            } else {
              _permissionService.clear();
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
