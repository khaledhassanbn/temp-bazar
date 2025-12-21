import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCategoryModel {
  final String id;
  final String name;
  final int order;

  ProductCategoryModel({
    required this.id,
    required this.name,
    required this.order,
  });

  factory ProductCategoryModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProductCategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'order': order};

  ProductCategoryModel copyWith({String? id, String? name, int? order}) {
    return ProductCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
    );
  }
}

/// عنصر خيار واحد داخل مجموعة الخيارات (اسم + سعر)
class OptionChoiceModel {
  final String name;
  final num price;

  OptionChoiceModel({required this.name, required this.price});

  factory OptionChoiceModel.fromMap(Map<String, dynamic> map) =>
      OptionChoiceModel(
        name: (map['name'] ?? '') as String,
        price: (map['price'] ?? 0) as num,
      );

  Map<String, dynamic> toMap() => {'name': name, 'price': price};

  OptionChoiceModel copyWith({String? name, num? price}) {
    return OptionChoiceModel(
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }
}

/// نموذج مجموعة خيارات المنتج (مطلوبة أو إضافية)
class ProductOptionModel {
  final String id;
  final String title; // عنوان مجموعة الخيار
  final List<OptionChoiceModel> choices; // عناصر الخيار بأسعارها
  final bool isRequired;
  final int order;

  ProductOptionModel({
    required this.id,
    required this.title,
    required this.choices,
    required this.isRequired,
    required this.order,
  });

  factory ProductOptionModel.fromMap(Map<String, dynamic> data) {
    final rawChoices = (data['choices'] as List<dynamic>? ?? []);
    return ProductOptionModel(
      id: (data['id'] ?? '') as String,
      title: (data['title'] ?? data['name'] ?? '') as String,
      choices: rawChoices
          .map(
            (e) =>
                OptionChoiceModel.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      isRequired: (data['isRequired'] ?? false) as bool,
      order: (data['order'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'choices': choices.map((e) => e.toMap()).toList(),
    'isRequired': isRequired,
    'order': order,
  };

  ProductOptionModel copyWith({
    String? id,
    String? title,
    List<OptionChoiceModel>? choices,
    bool? isRequired,
    int? order,
  }) {
    return ProductOptionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      choices: choices ?? this.choices,
      isRequired: isRequired ?? this.isRequired,
      order: order ?? this.order,
    );
  }
}

/// نموذج المنتج المحدث
class ProductModel {
  final String id;
  // معرف عام عشوائي لاستخدامه في مشاركة/فتح صفحة المنتج
  final String? publicId;
  final String name;
  final num price;
  final String? image;
  final String? description;
  final int stock;
  final bool hasStockLimit;
  final bool hasDiscount;
  final num? discountValue;
  final num? finalPrice;
  final List<ProductOptionModel> requiredOptions;
  final List<ProductOptionModel> extraOptions;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int order;
  final DateTime? endAt;
  final bool status;
  final bool inStock;

  ProductModel({
    required this.id,
    this.publicId,
    required this.name,
    required this.price,
    this.image,
    this.description,
    required this.stock,
    this.hasStockLimit = false,
    this.hasDiscount = false,
    this.discountValue,
    this.finalPrice,
    this.requiredOptions = const [],
    this.extraOptions = const [],
    this.createdAt,
    this.updatedAt,
    this.order = 0,
    this.endAt,
    this.status = true,
    this.inStock = true,
  });

  factory ProductModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // تحويل الخيارات المطلوبة
    final requiredOptionsData = data['requiredOptions'] as List<dynamic>? ?? [];
    final requiredOptions = requiredOptionsData
        .map(
          (item) => ProductOptionModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    // تحويل الخيارات الإضافية
    final extraOptionsData = data['extraOptions'] as List<dynamic>? ?? [];
    final extraOptions = extraOptionsData
        .map(
          (item) => ProductOptionModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    return ProductModel(
      id: doc.id,
      publicId: data['publicId'] as String?,
      name: data['name'] ?? '',
      price: data['price'] ?? 0,
      image: data['image'],
      description: data['description'],
      stock: data['stock'] ?? 0,
      hasStockLimit: data['hasStockLimit'] ?? false,
      hasDiscount: data['hasDiscount'] ?? false,
      discountValue: data['discountValue'],
      finalPrice: data['finalPrice'],
      requiredOptions: requiredOptions,
      extraOptions: extraOptions,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      order: data['order'] ?? 0,
      endAt: (data['endAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? true,
      inStock: data['inStock'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'image': image,
    'description': description,
    'publicId': publicId,
    'stock': stock,
    'hasStockLimit': hasStockLimit,
    'hasDiscount': hasDiscount,
    'discountValue': discountValue,
    'finalPrice': finalPrice,
    'requiredOptions': requiredOptions.map((e) => e.toMap()).toList(),
    'extraOptions': extraOptions.map((e) => e.toMap()).toList(),
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'order': order,
    'endAt': endAt,
    'status': status,
    'inStock': inStock,
  };

  /// إنشاء نسخة محدثة من المنتج
  ProductModel copyWith({
    String? id,
    String? publicId,
    String? name,
    num? price,
    String? image,
    String? description,
    int? stock,
    bool? hasStockLimit,
    bool? hasDiscount,
    num? discountValue,
    num? finalPrice,
    List<ProductOptionModel>? requiredOptions,
    List<ProductOptionModel>? extraOptions,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? order,
    DateTime? endAt,
    bool? status,
    bool? inStock,
  }) {
    return ProductModel(
      id: id ?? this.id,
      publicId: publicId ?? this.publicId,
      name: name ?? this.name,
      price: price ?? this.price,
      image: image ?? this.image,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      hasStockLimit: hasStockLimit ?? this.hasStockLimit,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      discountValue: discountValue ?? this.discountValue,
      finalPrice: finalPrice ?? this.finalPrice,
      requiredOptions: requiredOptions ?? this.requiredOptions,
      extraOptions: extraOptions ?? this.extraOptions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      order: order ?? this.order,
      endAt: endAt ?? this.endAt,
      status: status ?? this.status,
      inStock: inStock ?? this.inStock,
    );
  }
}
