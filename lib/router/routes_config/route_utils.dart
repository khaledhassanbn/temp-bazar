import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

Widget resolveMarketRoute(
  GoRouterState state,
  Widget Function(String marketId) builder,
) {
  final requestedMarketId = state.uri.queryParameters['marketId'];

  return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    future: FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
        return const Scaffold(body: Center(child: Text('تعذر تحديد المتجر المرتبط بالحساب')));
      }

      final data = snapshot.data!.data();
      String? resolvedId;
      if (data != null) {
        resolvedId = data['market_id'] ?? data['marketId'] ?? data['market']?['id'];
        
        // التحقق من الحماية: إذا تم طلب متجر محدد عبر الرابط، يجب التأكد أن المستخدم يملكه.
        if (requestedMarketId != null && requestedMarketId.isNotEmpty) {
          if (resolvedId != requestedMarketId) {
            // كطبقة حماية إضافية، نمنع عرض الصفحة إذا كان المعرّف لا يتطابق
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.security, size: 50, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('غير مصرح لك بالوصول لهذا المتجر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      child: const Text('العودة للرئيسية'),
                    )
                  ],
                ),
              ),
            );
          }
          return builder(requestedMarketId);
        }
      }

      if (resolvedId == null || resolvedId.isEmpty) {
        return const Scaffold(body: Center(child: Text('لا يوجد متجر مرتبط بهذا الحساب')));
      }
      return builder(resolvedId);
    },
  );
}
