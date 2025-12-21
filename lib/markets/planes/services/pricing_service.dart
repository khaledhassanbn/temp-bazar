import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/package.dart';

class PricingService {
  final _firestore = FirebaseFirestore.instance;

  Future<List<Package>> getPackages() async {
    final snapshot = await _firestore
        .collection("packages")
        .orderBy("orderIndex")
        .get();

    return snapshot.docs.map((doc) {
      return Package.fromMap(doc.id, doc.data());
    }).toList();
  }
}
