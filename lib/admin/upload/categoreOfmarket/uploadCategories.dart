import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> uploadCategories() async {
  final firestore = FirebaseFirestore.instance;
  final categoriesCollection = firestore.collection('Categories');

  final List<Map<String, dynamic>> categories = [
    {
      "id": "food",
      "name_ar": "طعام",
      "name_en": "Food",
      "order": 1,
      "icon": "",
      "stores": [],
      "storesCount": 0,
      "subcategories": [
        {"id": "home_food", "name_ar": "أكل بيتي", "name_en": "Home Food", "order": 1, "icon": "", "stores": [], "storesCount": 0},
        {"id": "burger", "name_ar": "برجر", "name_en": "Burger", "order": 2, "icon": "", "stores": [], "storesCount": 0},
        {"id": "pizza", "name_ar": "بيتزا", "name_en": "Pizza", "order": 3, "icon": "", "stores": [], "storesCount": 0},
        {"id": "desserts", "name_ar": "حلويات", "name_en": "Desserts", "order": 4, "icon": "", "stores": [], "storesCount": 0},
        {"id": "juices", "name_ar": "عصائر", "name_en": "Juices", "order": 5, "icon": "", "stores": [], "storesCount": 0},
        {"id": "koshary", "name_ar": "كشري", "name_en": "Koshary", "order": 6, "icon": "", "stores": [], "storesCount": 0},
        {"id": "bakery", "name_ar": "مخبوزات", "name_en": "Bakery", "order": 7, "icon": "", "stores": [], "storesCount": 0},
        {"id": "grills", "name_ar": "مشويات", "name_en": "Grills", "order": 8, "icon": "", "stores": [], "storesCount": 0},
        {"id": "waffle", "name_ar": "وافل", "name_en": "Waffle", "order": 9, "icon": "", "stores": [], "storesCount": 0},
      ],
    },
    {
      "id": "clothes",
      "name_ar": "ملابس",
      "name_en": "Clothes",
      "order": 2,
      "icon": "",
      "stores": [],
      "storesCount": 0,
      "subcategories": [
        {"id": "men", "name_ar": "رجالي", "name_en": "Men", "order": 1, "icon": "", "stores": [], "storesCount": 0},
        {"id": "women", "name_ar": "حريمي", "name_en": "Women", "order": 2, "icon": "", "stores": [], "storesCount": 0},
        {"id": "kids", "name_ar": "أطفالي", "name_en": "Kids", "order": 3, "icon": "", "stores": [], "storesCount": 0},
      ],
    },
    {"id": "supermarket", "name_ar": "سوبر ماركت", "name_en": "Supermarket", "order": 3, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "library", "name_ar": "مكتبة", "name_en": "Library", "order": 4, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "home_tools", "name_ar": "أدوات منزلية", "name_en": "Home Tools", "order": 5, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "cosmetics", "name_ar": "مستحضرات تجميل", "name_en": "Cosmetics", "order": 6, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "pharmacy", "name_ar": "صيدليات", "name_en": "Pharmacy", "order": 7, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "electronics", "name_ar": "أدوات كهربائية", "name_en": "Electronics", "order": 8, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "furniture", "name_ar": "أثاث", "name_en": "Furniture", "order": 9, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "decor", "name_ar": "ديكور", "name_en": "Decor", "order": 10, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "pets", "name_ar": "حيوانات أليفة ومستلزماتها", "name_en": "Pets & Supplies", "order": 11, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "sanitary", "name_ar": "أدوات صحية", "name_en": "Sanitary Tools", "order": 12, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "pans", "name_ar": "مقلات", "name_en": "Pans", "order": 13, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "mobiles", "name_ar": "موبيلات", "name_en": "Mobiles", "order": 14, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "cars", "name_ar": "سيارات وقطع غيار", "name_en": "Cars & Spare Parts", "order": 15, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "perfumes", "name_ar": "عطور", "name_en": "Perfumes", "order": 16, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "accessories", "name_ar": "اكسسورات", "name_en": "Accessories", "order": 17, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "computers", "name_ar": "كمبيوتر ولابتوب", "name_en": "Computers & Laptops", "order": 18, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "textiles", "name_ar": "منسوجات", "name_en": "Textiles", "order": 19, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "services", "name_ar": "خدمات", "name_en": "Services", "order": 20, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "flowers", "name_ar": "ورود", "name_en": "Flowers", "order": 21, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "medical_supplies", "name_ar": "مستلزمات طبيه", "name_en": "Medical Supplies", "order": 22, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
    {"id": "travel", "name_ar": "سياحة والسفر", "name_en": "Travel & Tourism", "order": 23, "icon": "", "stores": [], "storesCount": 0, "subcategories": []},
  ];

  try {
    print('🚀 بدء رفع الفئات إلى Firebase...');

    for (final category in categories) {
      final catDoc = categoriesCollection.doc(category['id']);

      await catDoc.set({
        "id": category['id'],
        "name_ar": category['name_ar'],
        "name_en": category['name_en'],
        "order": category['order'],
        "icon": category['icon'],
        "stores": category['stores'],
        "storesCount": category['storesCount'],
      }, SetOptions(merge: true));

      final List<dynamic> subcategories = category['subcategories'] ?? [];
      final subCollection = catDoc.collection('subCategories');

      for (final sub in subcategories) {
        await subCollection.doc(sub['id']).set({
          "id": sub['id'],
          "name_ar": sub['name_ar'],
          "name_en": sub['name_en'],
          "order": sub['order'],
          "icon": sub['icon'],
          "stores": sub['stores'],
          "storesCount": sub['storesCount'],
        }, SetOptions(merge: true));
      }

      print('✅ تم رفع الفئة: ${category['name_ar']} (${category['name_en']})');
    }

    print('🎉 تم رفع جميع الفئات والفئات الفرعية بنجاح.');
  } catch (e) {
    print('❌ خطأ أثناء رفع البيانات: $e');
  }
}
