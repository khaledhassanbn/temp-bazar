import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<CategoryModel>> getMainCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection('Categories')
          .orderBy('order')
          .get();

      return querySnapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("❌ خطأ أثناء جلب الفئات: $e");
      return [];
    }
  }
}
