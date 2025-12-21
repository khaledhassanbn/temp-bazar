import 'package:hive/hive.dart';

part 'cart_item_model.g.dart';

/// Model class representing a cart item with Hive local storage support
/// This model stores all necessary information for a product in the cart
@HiveType(typeId: 0)
class CartItemModel extends HiveObject {
  @HiveField(0)
  String productId;

  @HiveField(1)
  String productName;

  @HiveField(2)
  String? productImage;

  @HiveField(3)
  double productPrice;

  @HiveField(4)
  Map<String, dynamic> selectedOptions;

  @HiveField(5)
  int quantity;

  @HiveField(6)
  String marketId;

  @HiveField(7)
  String categoryId;

  @HiveField(8)
  double additionalPrice; // Price from selected options

  @HiveField(9)
  DateTime addedAt; // Timestamp when item was added
  

  CartItemModel({
    required this.productId,
    required this.productName,
    this.productImage,
    required this.productPrice,
    required this.selectedOptions,
    required this.quantity,
    required this.marketId,
    required this.categoryId,
    this.additionalPrice = 0.0,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Calculate the total price for this item (base price + options) * quantity
  double get totalPrice => (productPrice + additionalPrice) * quantity;

  /// Get the price per unit including options
  double get unitPrice => productPrice + additionalPrice;

  /// Create a copy of this cart item with updated values
  CartItemModel copyWith({
    String? productId,
    String? productName,
    String? productImage,
    double? productPrice,
    Map<String, dynamic>? selectedOptions,
    int? quantity,
    String? marketId,
    String? categoryId,
    double? additionalPrice,
    DateTime? addedAt,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      productPrice: productPrice ?? this.productPrice,
      selectedOptions: selectedOptions ?? Map.from(this.selectedOptions),
      quantity: quantity ?? this.quantity,
      marketId: marketId ?? this.marketId,
      categoryId: categoryId ?? this.categoryId,
      additionalPrice: additionalPrice ?? this.additionalPrice,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Convert to Map for easy serialization
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'productPrice': productPrice,
      'selectedOptions': selectedOptions,
      'quantity': quantity,
      'marketId': marketId,
      'categoryId': categoryId,
      'additionalPrice': additionalPrice,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }

  /// Create from Map for easy deserialization
  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'],
      productPrice: (map['productPrice'] ?? 0.0).toDouble(),
      selectedOptions: Map<String, dynamic>.from(map['selectedOptions'] ?? {}),
      quantity: map['quantity'] ?? 1,
      marketId: map['marketId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      additionalPrice: (map['additionalPrice'] ?? 0.0).toDouble(),
      addedAt: map['addedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['addedAt'])
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'CartItemModel(productId: $productId, productName: $productName, quantity: $quantity, totalPrice: $totalPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CartItemModel &&
        other.productId == productId &&
        other.marketId == marketId &&
        _mapEquals(other.selectedOptions, selectedOptions);
  }

  @override
  int get hashCode {
    return productId.hashCode ^ marketId.hashCode ^ selectedOptions.hashCode;
  }

  /// Helper method to compare two maps for equality
  bool _mapEquals(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }
}
