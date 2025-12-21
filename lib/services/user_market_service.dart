import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserMarketService {
  const UserMarketService();

  Future<String?> resolveCurrentUserMarketId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = snap.data();
    if (data == null) return null;

    final directSnake = data['market_id'];
    final directCamel = data['marketId'];
    final nestedMarket = data['market'];
    if (directSnake is String && directSnake.isNotEmpty) return directSnake;
    if (directCamel is String && directCamel.isNotEmpty) return directCamel;
    if (nestedMarket is Map &&
        nestedMarket['id'] is String &&
        (nestedMarket['id'] as String).isNotEmpty) {
      return nestedMarket['id'] as String;
    }
    return null;
  }
}
