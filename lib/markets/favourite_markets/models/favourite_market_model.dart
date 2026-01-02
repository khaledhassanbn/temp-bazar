import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج المتجر المفضل
class FavouriteMarketModel {
  final String id; // document ID في Firestore
  final String marketId; // ID المتجر
  final DateTime addedAt; // تاريخ الإضافة

  FavouriteMarketModel({
    required this.id,
    required this.marketId,
    required this.addedAt,
  });

  factory FavouriteMarketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FavouriteMarketModel(
      id: doc.id,
      marketId: data['marketId'] ?? '',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'marketId': marketId,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }
}


