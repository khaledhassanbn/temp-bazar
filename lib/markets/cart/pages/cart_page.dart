import 'package:bazar_suez/markets/cart/widgets/cart_bottom_buttons.dart';
import 'package:bazar_suez/markets/cart/widgets/cart_coupon_section.dart';
import 'package:bazar_suez/markets/cart/widgets/cart_item_card.dart';
import 'package:bazar_suez/markets/cart/widgets/cart_notes_section.dart';
import 'package:bazar_suez/markets/cart/widgets/cart_summary_section.dart';
import 'package:bazar_suez/markets/cart/widgets/cart_user_info_section.dart';
import 'package:bazar_suez/markets/cart/viewmodels/cart_view_model.dart';
import 'package:bazar_suez/markets/home_market/pages/ProductDetails.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

/// توليد ID للطلب بصيغة سهلة للقراءة
String generateOrderId(String marketId) {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0'); // الشهر
  final day = now.day.toString().padLeft(2, '0'); // اليوم
  final hour = now.hour.toString().padLeft(2, '0'); // الساعة
  final minute = now.minute.toString().padLeft(2, '0'); // الدقيقة

  // جزء التاريخ: شهر + يوم + ساعة + دقيقة
  final datePart = '$month$day$hour$minute';

  // جزء عشوائي أرقام فقط
  final random = Random();
  final randomPart = List.generate(
    3, // تقدر تزوده لو عايز تفرد أكتر
    (_) => random.nextInt(10).toString(),
  ).join();

  // ID النهائي
  return '$datePart$randomPart';
}

class _CartPageState extends State<CartPage> {
  String? _marketName;
  int _cartItemCount = 0;
  final GlobalKey<CartUserInfoSectionState> _userInfoKey =
      GlobalKey<CartUserInfoSectionState>();

  @override
  void initState() {
    super.initState();
    _fetchMarketName();
  }

  /// جلب اسم المتجر من Firestore
  Future<void> _fetchMarketName() async {
    final cartViewModel = Provider.of<CartViewModel>(context, listen: false);
    if (cartViewModel.isEmpty) {
      return;
    }

    final marketId = cartViewModel.currentMarketId;
    if (marketId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('markets')
          .doc(marketId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _marketName = data?['name'] ?? 'المتجر';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _marketName = 'المتجر';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartViewModel>(
      builder: (context, cartViewModel, child) {
        // تحديث اسم المتجر عند تغيير السلة
        if (cartViewModel.itemCount != _cartItemCount) {
          _fetchMarketName();
        }
        _cartItemCount = cartViewModel.itemCount;

        if (cartViewModel.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F7FA),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (cartViewModel.error != null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: _buildAppBar(),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('خطأ: ${cartViewModel.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => cartViewModel.refreshCart(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E99B4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (cartViewModel.isEmpty) {
          return _buildEmptyCart();
        }

        return _buildCartWithItems(cartViewModel);
      },
    );
  }

  /// واجهة السلة الفارغة
  Widget _buildEmptyCart() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4E99B4).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: Color(0xFF4E99B4),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "سلة المشتريات فارغة",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "أضف بعض المنتجات لتبدأ التسوق",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// واجهة السلة مع المنتجات
  Widget _buildCartWithItems(CartViewModel cartViewModel) {
    final cartItems = cartViewModel.getCartItemsAsMap();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Store Name Header
                  _buildStoreHeader(),
                  const SizedBox(height: 16),

                  // المنتجات في السلة
                  ListView.builder(
                    itemCount: cartItems.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) => CartItemCard(
                      item: cartItems[index],
                      onIncrease: () => _increaseQuantity(cartViewModel, index),
                      onDecrease: () => _decreaseQuantity(cartViewModel, index),
                      onEdit: () => _editItem(cartViewModel, index),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// الملاحظات
                  const CartNotesSection(),
                  const SizedBox(height: 16),

                  /// القسيمة
                  const CartCouponSection(),
                  const SizedBox(height: 16),

                  /// بيانات المستخدم
                  CartUserInfoSection(key: _userInfoKey),
                  const SizedBox(height: 24),

                  /// الفاتورة
                  CartSummarySection(
                    subtotal: cartViewModel.subtotal,
                    delivery: cartViewModel.deliveryFee,
                    service: cartViewModel.serviceFee,
                    total: cartViewModel.totalAmount,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Buttons
          CartBottomButtons(
            onProceedToCheckout: _proceedToCheckout,
            onAddMore: () => _addMoreItems(cartViewModel),
          ),
        ],
      ),
    );
  }

  /// Store Header
  Widget _buildStoreHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF4E99B4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.store_outlined,
              color: Color(0xFF4E99B4),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _marketName ?? 'المتجر',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'متجرك المفضل',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// AppBar الجديد
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: const [
              Icon(Icons.shopping_cart_outlined, color: Color(0xFF4E99B4)),
              SizedBox(width: 8),
              Text(
                'سلة المشتريات',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          centerTitle: false,
        ),
      ),
    );
  }

  /// زيادة الكمية
  void _increaseQuantity(CartViewModel cartViewModel, int index) {
    cartViewModel.updateItemQuantity(
      index,
      cartViewModel.cartItems[index].quantity + 1,
    );
  }

  /// تقليل الكمية أو حذف العنصر
  void _decreaseQuantity(CartViewModel cartViewModel, int index) {
    final currentQuantity = cartViewModel.cartItems[index].quantity;
    if (currentQuantity > 1) {
      cartViewModel.updateItemQuantity(index, currentQuantity - 1);
    } else {
      cartViewModel.removeItem(index);
    }
  }

  /// تعديل العنصر (يفتح صفحة التفاصيل)
  void _editItem(CartViewModel cartViewModel, int index) {
    final cartItem = cartViewModel.cartItems[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(
          marketId: cartItem.marketId,
          categoryId: cartItem.categoryId,
          itemId: cartItem.productId,
          editItem: cartItem,
        ),
      ),
    );
  }

  /// متابعة للدفع
  Future<void> _proceedToCheckout() async {
    // التحقق من صحة البيانات
    final userInfoState = _userInfoKey.currentState;
    if (userInfoState != null && !userInfoState.isValid) {
      // هز الكارت لإظهار أن الحقول مطلوبة
      userInfoState.shake();

      // تحديد رسالة الخطأ المناسبة
      String errorMessage = 'يرجى إدخال رقم الهاتف (11 رقم) وتحديد العنوان';
      if (userInfoState.phoneController.text.trim().isEmpty) {
        errorMessage = 'يرجى إدخال رقم الهاتف (11 رقم)';
      } else if (userInfoState.phoneController.text.trim().length != 11) {
        errorMessage = 'رقم الهاتف يجب أن يكون 11 رقم بالضبط';
      } else if (userInfoState.selectedAddress == null) {
        errorMessage = 'يرجى تحديد العنوان من الخريطة';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // في حالة نجاح التحقق - حفظ الطلب في Firebase
    await _saveOrderToFirestore(userInfoState!);
  }

  /// حفظ الطلب في Firebase
  Future<void> _saveOrderToFirestore(CartUserInfoSectionState userInfo) async {
    try {
      // إظهار loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final cartViewModel = Provider.of<CartViewModel>(context, listen: false);
      final marketId = cartViewModel.currentMarketId;

      if (marketId == null) {
        Navigator.pop(context); // إغلاق loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن تحديد المتجر'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // جلب بيانات المستخدم الحالي
      String customerName = 'عميل';
      String customerEmail = '';
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            final firstName = userData?['firstName'] ?? '';
            final lastName = userData?['lastName'] ?? '';
            customerName = '$firstName $lastName'.trim();
            customerEmail = userData?['email'] ?? '';
          }
        } catch (e) {
          debugPrint('خطأ في جلب بيانات المستخدم: $e');
        }
      }

      // توليد ID للطلب
      final orderId = generateOrderId(marketId);

      // إعداد بيانات الطلب
      final orderData = {
        'orderId': orderId,
        'userId':
            currentUser?.uid ?? '', // إضافة معرف المستخدم في المستوى العلوي
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // حالة الطلب
        'customerInfo': {
          'userId': currentUser?.uid ?? '',
          'name': customerName,
          'email': customerEmail,
          'phone': userInfo.phoneNumber,
          'address': userInfo.selectedAddress,
          'location':
              userInfo.selectedLocationValue, // الآن GeoPoint مباشر وليس نص
        },
        'items': cartViewModel.cartItems
            .map(
              (item) => {
                'productId': item.productId,
                'productName': item.productName,
                'productImage': item.productImage,
                'productPrice': item.productPrice,
                'additionalPrice': item.additionalPrice,
                'unitPrice': item.unitPrice,
                'totalPrice': item.totalPrice,
                'quantity': item.quantity,
                'selectedOptions': item.selectedOptions,
                'categoryId': item.categoryId,
              },
            )
            .toList(),
        'subtotal': cartViewModel.subtotal,
        'deliveryFee': cartViewModel.deliveryFee,
        'serviceFee': cartViewModel.serviceFee,
        'totalAmount': cartViewModel.totalAmount,
      };

      // حفظ الطلب في Firebase - في قاعدة بيانات المتجر
      await FirebaseFirestore.instance
          .collection('markets')
          .doc(marketId)
          .collection('present_order')
          .doc(orderId)
          .set(orderData);

      // حفظ الطلب في قاعدة بيانات العميل أيضاً
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('orders')
            .doc(orderId)
            .set(orderData);
      }

      Navigator.pop(context); // إغلاق loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال الطلب بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );

      // مسح السلة بعد حفظ الطلب
      await cartViewModel.clearCart();

      // العودة للصفحة السابقة
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      Navigator.pop(context); // إغلاق loading في حالة الخطأ

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في إرسال الطلب: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// أضف المزيد من نفس المتجر
  void _addMoreItems(CartViewModel cartViewModel) {
    final marketId = cartViewModel.currentMarketId;
    if (marketId != null) {
      context.push('/HomeMarketPage?marketLink=$marketId');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن تحديد المتجر'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
