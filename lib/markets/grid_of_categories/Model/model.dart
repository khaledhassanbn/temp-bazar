class CategoryModel {
  final String id;
  final String name;
  final int order;
  final String icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.order,
    required this.icon,
  });

  factory CategoryModel.fromFirestore(Map<String, dynamic> data, String docId) {
    // Prefer Arabic name per current schema; gracefully fallback to other keys
    final String resolvedName =
        (data['name_ar'] ?? data['name'] ?? data['name_en'] ?? '') as String;

    return CategoryModel(
      id: docId,
      name: resolvedName,
      order: (data['order'] ?? 0) as int,
      icon: (data['icon'] ?? '') as String,
    );
  }
}
