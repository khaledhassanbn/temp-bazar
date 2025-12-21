import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

Widget resolveMarketRoute(
  GoRouterState state,
  Widget Function(String marketId) builder,
) {
  final marketId = state.uri.queryParameters['marketId'];
  if (marketId != null && marketId.isNotEmpty) {
    return builder(marketId);
  }

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
      }
      if (resolvedId == null || resolvedId.isEmpty) {
        return const Scaffold(body: Center(child: Text('لا يوجد متجر مرتبط بهذا الحساب')));
      }
      return builder(resolvedId);
    },
  );
}
