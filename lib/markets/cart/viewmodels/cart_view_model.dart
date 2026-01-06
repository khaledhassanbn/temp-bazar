import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item_model.dart';

/// ViewModel for managing cart operations using MVVM pattern
/// Handles all cart-related business logic and Hive local storage
class CartViewModel extends ChangeNotifier {
  static const String _cartBoxName = 'cart_box';
  late Box<CartItemModel> _cartBox;

  List<CartItemModel> _cartItems = [];
  bool _isLoading = false;
  String? _error;
  
  /// Flag to track if this ChangeNotifier has been disposed
  bool _isDisposed = false;
  
  /// Safe wrapper for notifyListeners that checks disposal state
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _cartBox.close(); // Moving close here to ensure it happens on dispose
    super.dispose();
  }

  /// Getter for cart items list
  List<CartItemModel> get cartItems => List.unmodifiable(_cartItems);

  /// Getter for loading state
  bool get isLoading => _isLoading;

  /// Getter for error state
  String? get error => _error;

  /// Getter for cart items count
  int get itemCount => _cartItems.length;

  /// Getter for total items quantity
  int get totalQuantity =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  /// Getter for cart subtotal
  double get subtotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Getter for delivery fee (can be customized)
  double get deliveryFee => 6.99;

  /// Getter for service fee (can be customized)
  double get serviceFee => 3.99;

  /// Getter for total amount
  double get totalAmount => subtotal + deliveryFee + serviceFee;

  /// Getter for current market ID (from first item if cart is not empty)
  String? get currentMarketId =>
      _cartItems.isNotEmpty ? _cartItems.first.marketId : null;

  /// Getter for current market name (placeholder - can be enhanced)
  String get currentMarketName =>
      _cartItems.isNotEmpty ? "المتجر الحالي" : "لا يوجد منتجات";

  /// Initialize the cart ViewModel and load existing cart data
  Future<void> initialize() async {
    try {
      _isLoading = true;
      _error = null;
      _safeNotifyListeners();

      // Open the cart box
      _cartBox = await Hive.openBox<CartItemModel>(_cartBoxName);

      // Load existing cart items
      await _loadCartItems();
    } catch (e) {
      _error = 'فشل في تحميل بيانات السلة: ${e.toString()}';
      debugPrint('CartViewModel initialization error: $e');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Load cart items from Hive storage
  Future<void> _loadCartItems() async {
    try {
      _cartItems = _cartBox.values.toList();
      _safeNotifyListeners();
    } catch (e) {
      _error = 'فشل في تحميل عناصر السلة';
      debugPrint('Load cart items error: $e');
    }
  }

  /// Add a new item to the cart
  /// Returns true if successful, false if user cancelled market replacement dialog
  Future<bool> addItem(CartItemModel newItem) async {
    try {
      _error = null;

      // Check if cart is empty
      if (_cartItems.isEmpty) {
        await _addItemToCart(newItem);
        return true;
      }

      // Check if new item is from different market
      if (newItem.marketId != currentMarketId) {
        // Show confirmation dialog - this will be handled by UI
        return false; // UI should handle the dialog and call addItemWithMarketReplacement
      }

      // Check if item already exists with same options
      final existingIndex = _findExistingItemIndex(newItem);
      if (existingIndex != -1) {
        // Update quantity of existing item
        await updateItemQuantity(
          existingIndex,
          _cartItems[existingIndex].quantity + newItem.quantity,
        );
      } else {
        // Add new item
        await _addItemToCart(newItem);
      }

      return true;
    } catch (e) {
      _error = 'فشل في إضافة المنتج للسلة';
      debugPrint('Add item error: $e');
      _safeNotifyListeners();
      return false;
    }
  }

  /// Add item with market replacement (after user confirmation)
  Future<void> addItemWithMarketReplacement(CartItemModel newItem) async {
    try {
      _error = null;

      // Clear existing cart
      await clearCart();

      // Add new item
      await _addItemToCart(newItem);
    } catch (e) {
      _error = 'فشل في استبدال منتجات السلة';
      debugPrint('Add item with market replacement error: $e');
      _safeNotifyListeners();
    }
  }

  /// Internal method to add item to cart and storage
  Future<void> _addItemToCart(CartItemModel item) async {
    try {
      await _cartBox.add(item);
      _cartItems.add(item);
      _safeNotifyListeners();
    } catch (e) {
      throw Exception('فشل في حفظ المنتج في السلة');
    }
  }

  /// Find index of existing item with same product and options
  int _findExistingItemIndex(CartItemModel item) {
    for (int i = 0; i < _cartItems.length; i++) {
      if (_cartItems[i] == item) {
        return i;
      }
    }
    return -1;
  }

  /// Update item quantity by index
  Future<void> updateItemQuantity(int index, int newQuantity) async {
    if (index < 0 || index >= _cartItems.length) return;
    if (newQuantity <= 0) {
      await removeItem(index);
      return;
    }

    try {
      final updatedItem = _cartItems[index].copyWith(quantity: newQuantity);
      await _cartBox.putAt(index, updatedItem);
      _cartItems[index] = updatedItem;
      _safeNotifyListeners();
    } catch (e) {
      _error = 'فشل في تحديث كمية المنتج';
      debugPrint('Update quantity error: $e');
      _safeNotifyListeners();
    }
  }

  /// Update item by index with new data
  Future<void> updateItem(int index, CartItemModel updatedItem) async {
    if (index < 0 || index >= _cartItems.length) return;

    try {
      await _cartBox.putAt(index, updatedItem);
      _cartItems[index] = updatedItem;
      _safeNotifyListeners();
    } catch (e) {
      _error = 'فشل في تحديث المنتج';
      debugPrint('Update item error: $e');
      _safeNotifyListeners();
    }
  }

  /// Remove item from cart by index
  Future<void> removeItem(int index) async {
    if (index < 0 || index >= _cartItems.length) return;

    try {
      await _cartBox.deleteAt(index);
      _cartItems.removeAt(index);
      _safeNotifyListeners();
    } catch (e) {
      _error = 'فشل في حذف المنتج من السلة';
      debugPrint('Remove item error: $e');
      _safeNotifyListeners();
    }
  }

  /// Remove item by CartItemModel object
  Future<void> removeItemByModel(CartItemModel item) async {
    final index = _cartItems.indexOf(item);
    if (index != -1) {
      await removeItem(index);
    }
  }

  /// Clear all items from cart
  Future<void> clearCart() async {
    try {
      await _cartBox.clear();
      _cartItems.clear();
      _safeNotifyListeners();
    } catch (e) {
      _error = 'فشل في مسح السلة';
      debugPrint('Clear cart error: $e');
      _safeNotifyListeners();
    }
  }

  /// Get cart item by index
  CartItemModel? getItem(int index) {
    if (index < 0 || index >= _cartItems.length) return null;
    return _cartItems[index];
  }

  /// Check if cart is empty
  bool get isEmpty => _cartItems.isEmpty;

  /// Check if cart has items from a specific market
  bool hasItemsFromMarket(String marketId) {
    return _cartItems.any((item) => item.marketId == marketId);
  }

  /// Get items from a specific market
  List<CartItemModel> getItemsFromMarket(String marketId) {
    return _cartItems.where((item) => item.marketId == marketId).toList();
  }

  /// Refresh cart data from storage
  Future<void> refreshCart() async {
    await _loadCartItems();
  }



  /// Create a cart item from product details
  static CartItemModel createCartItem({
    required String productId,
    required String productName,
    String? productImage,
    required double productPrice,
    required Map<String, dynamic> selectedOptions,
    required int quantity,
    required String marketId,
    required String categoryId,
    double additionalPrice = 0.0,
  }) {
    return CartItemModel(
      productId: productId,
      productName: productName,
      productImage: productImage,
      productPrice: productPrice,
      selectedOptions: selectedOptions,
      quantity: quantity,
      marketId: marketId,
      categoryId: categoryId,
      additionalPrice: additionalPrice,
    );
  }

  /// Convert cart items to list of maps for UI compatibility
  List<Map<String, dynamic>> getCartItemsAsMap() {
    return _cartItems
        .map(
          (item) => {
            'name': item.productName,
            'price': item.unitPrice,
            'quantity': item.quantity,
            'image': item.productImage,
            'productId': item.productId,
            'marketId': item.marketId,
            'categoryId': item.categoryId,
            'selectedOptions': item.selectedOptions,
            'additionalPrice': item.additionalPrice,
            'addedAt': item.addedAt,
          },
        )
        .toList();
  }
}
