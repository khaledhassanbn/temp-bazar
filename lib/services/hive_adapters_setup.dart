import 'package:hive_flutter/hive_flutter.dart';
import '../markets/cart/models/cart_item_model.dart';

/// Service class for setting up Hive adapters and initializing local storage
/// This class handles the registration of all Hive type adapters used in the app
class HiveAdaptersSetup {
  static const String _cartBoxName = 'cart_box';

  /// Initialize Hive and register all adapters
  /// Call this method in main() before running the app
  static Future<void> initializeHive() async {
    try {
      // Initialize Hive Flutter
      await Hive.initFlutter();

      // Register all adapters
      await _registerAdapters();

      // Open boxes
      await _openBoxes();

      print('✅ Hive initialized successfully');
    } catch (e) {
      print('❌ Error initializing Hive: $e');
      rethrow;
    }
  }

  /// Register all Hive type adapters
  static Future<void> _registerAdapters() async {
    // Register CartItemModel adapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CartItemModelAdapter());
      print('✅ CartItemModel adapter registered');
    }

    // Add more adapters here as needed
    // Example:
    // if (!Hive.isAdapterRegistered(1)) {
    //   Hive.registerAdapter(AnotherModelAdapter());
    // }
  }

  /// Open all required Hive boxes
  static Future<void> _openBoxes() async {
    try {
      // Open cart box
      await Hive.openBox<CartItemModel>(_cartBoxName);
      print('✅ Cart box opened successfully');

      // Add more boxes here as needed
      // Example:
      // await Hive.openBox<AnotherModel>('another_box_name');
    } catch (e) {
      print('❌ Error opening boxes: $e');
      rethrow;
    }
  }

  /// Get cart box instance
  static Box<CartItemModel> get cartBox {
    return Hive.box<CartItemModel>(_cartBoxName);
  }

  /// Clear all data from cart box (useful for testing or reset)
  static Future<void> clearCartData() async {
    try {
      await cartBox.clear();
      print('✅ Cart data cleared successfully');
    } catch (e) {
      print('❌ Error clearing cart data: $e');
      rethrow;
    }
  }

  /// Get cart box size (number of items)
  static int getCartSize() {
    try {
      return cartBox.length;
    } catch (e) {
      print('❌ Error getting cart size: $e');
      return 0;
    }
  }

  /// Check if Hive is properly initialized
  static bool isInitialized() {
    try {
      return Hive.isBoxOpen(_cartBoxName);
    } catch (e) {
      return false;
    }
  }

  /// Close all boxes and cleanup (call this when app is disposed)
  static Future<void> dispose() async {
    try {
      await Hive.close();
      print('✅ Hive disposed successfully');
    } catch (e) {
      print('❌ Error disposing Hive: $e');
    }
  }

  /// Get storage info for debugging
  static Map<String, dynamic> getStorageInfo() {
    try {
      return {
        'isInitialized': isInitialized(),
        'cartSize': getCartSize(),
        'cartBoxPath': cartBox.path,
        'hiveDirectory': 'Hive storage directory',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
