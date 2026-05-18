import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bazar_suez/widgets/auth_bottom_sheet.dart';

export 'package:bazar_suez/widgets/auth_bottom_sheet.dart' show showAuthBottomSheet;

/// تحقق ما إذا كان المستخدم مسجل الدخول.
/// إذا لم يكن مسجلاً، يعرض ورقة تسجيل الدخول ويرجع `false`.
bool requireAuth(
  BuildContext context, {
  String? message,
  String? pendingLocation,
  bool pendingUseGo = false,
  VoidCallback? onAuthenticated,
}) {
  if (FirebaseAuth.instance.currentUser != null) return true;

  showAuthBottomSheet(
    context,
    message: message,
    pendingLocation: pendingLocation,
    pendingUseGo: pendingUseGo,
    onAuthenticated: onAuthenticated,
  );
  return false;
}

/// يعرض ورقة تسجيل الدخول / إنشاء الحساب.
void showLoginRequiredSheet(
  BuildContext context, {
  String? message,
  String? pendingLocation,
  bool pendingUseGo = false,
  VoidCallback? onAuthenticated,
}) {
  showAuthBottomSheet(
    context,
    message: message,
    pendingLocation: pendingLocation,
    pendingUseGo: pendingUseGo,
    onAuthenticated: onAuthenticated,
  );
}

/// يفتح مساراً محمياً بعد التحقق من تسجيل الدخول.
void pushIfAuthed(
  BuildContext context,
  String location, {
  String? message,
  Object? extra,
}) {
  if (FirebaseAuth.instance.currentUser != null) {
    context.push(location, extra: extra);
    return;
  }
  showAuthBottomSheet(
    context,
    message: message,
    pendingLocation: location,
  );
}

/// يذهب لمسار محمي بعد التحقق من تسجيل الدخول.
void goIfAuthed(
  BuildContext context,
  String location, {
  String? message,
  Object? extra,
}) {
  if (FirebaseAuth.instance.currentUser != null) {
    context.go(location, extra: extra);
    return;
  }
  showAuthBottomSheet(
    context,
    message: message,
    pendingLocation: location,
    pendingUseGo: true,
  );
}
