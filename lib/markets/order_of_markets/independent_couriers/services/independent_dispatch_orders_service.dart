import 'package:cloud_firestore/cloud_firestore.dart';

class IndependentDispatchOrdersService {
  final FirebaseFirestore _firestore;

  IndependentDispatchOrdersService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> streamOrdersForStore(String storeId) {
    // Keep query simple to avoid composite index requirements
    return _firestore
        .collection('orders')
        .where('storeId', isEqualTo: storeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList(growable: false));
  }
}

