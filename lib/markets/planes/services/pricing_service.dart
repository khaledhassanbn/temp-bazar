import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/package.dart';

class PricingService {
  final _firestore = FirebaseFirestore.instance;

  // كاش في الذاكرة للباقات (نادراً ما تتغير) لتسريع التحميلات المتكررة
  static List<Package>? _cachedPackages;
  static DateTime? _cachedAt;
  static const Duration _cacheTtl = Duration(minutes: 5);

  Future<List<Package>> getPackages({bool forceRefresh = false}) async {
    final cached = _cachedPackages;
    final cachedAt = _cachedAt;
    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    final snapshot = await _firestore
        .collection("packages")
        .orderBy("orderIndex")
        .get();

    final packages = snapshot.docs.map((doc) {
      return Package.fromMap(doc.id, doc.data());
    }).toList();

    _cachedPackages = packages;
    _cachedAt = DateTime.now();
    return packages;
  }
}
