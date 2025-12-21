// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:bazar_suez/markets/cart/viewmodels/cart_view_model.dart';
// import 'package:bazar_suez/markets/cart/models/cart_item_model.dart';
// import 'floating_cart_bar.dart';

// /// مثال لاختبار شريط السلة العائم
// /// يمكن استخدام هذا الملف لاختبار الوظائف المختلفة
// class FloatingCartBarExample extends StatelessWidget {
//   const FloatingCartBarExample({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('مثال شريط السلة العائم')),
//       body: Stack(
//         children: [
//           // محتوى الصفحة
//           Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text(
//                   'اضغط على الأزرار أدناه لإضافة منتجات للسلة',
//                   style: TextStyle(fontSize: 18),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 30),

//                 // أزرار لاختبار إضافة المنتجات
//                 ElevatedButton(
//                   onPressed: () => _addTestItem(context, 1),
//                   child: const Text('إضافة منتج 1'),
//                 ),
//                 const SizedBox(height: 10),

//                 ElevatedButton(
//                   onPressed: () => _addTestItem(context, 2),
//                   child: const Text('إضافة منتج 2'),
//                 ),
//                 const SizedBox(height: 10),

//                 ElevatedButton(
//                   onPressed: () => _clearCart(context),
//                   child: const Text('مسح السلة'),
//                 ),
//               ],
//             ),
//           ),

//           // شريط السلة العائم
//           const FloatingCartBar(),
//         ],
//       ),
//     );
//   }

//   /// إضافة منتج تجريبي للسلة
//   void _addTestItem(BuildContext context, int itemNumber) {
//     final cartViewModel = context.read<CartViewModel>();

//     final testItem = CartItemModel(
//       productId: 'test_product_$itemNumber',
//       productName: 'منتج تجريبي $itemNumber',
//       productImage: 'https://via.placeholder.com/150',
//       productPrice: 50.0 + (itemNumber * 25.0),
//       selectedOptions: {'size': 'medium', 'color': 'blue'},
//       quantity: 1,
//       marketId: 'test_market',
//       categoryId: 'test_category',
//       additionalPrice: 5.0,
//     );

//     cartViewModel.addItem(testItem);

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('تم إضافة المنتج $itemNumber للسلة'),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   /// مسح السلة
//   void _clearCart(BuildContext context) {
//     final cartViewModel = context.read<CartViewModel>();
//     cartViewModel.clearCart();

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('تم مسح السلة'),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
// }
