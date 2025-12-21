import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/markets/home_market/widgets/market_appbar.dart';
import 'package:bazar_suez/markets/home_market/widget_details/product_header_section.dart';
import 'package:bazar_suez/markets/home_market/widget_details/product_option_section.dart';
import 'package:bazar_suez/markets/home_market/widget_details/product_bottom_bar.dart';
import 'package:bazar_suez/markets/home_market/widget_details/product_loading_error.dart';
import 'package:bazar_suez/markets/cart/viewmodels/cart_view_model.dart';
import 'package:bazar_suez/markets/cart/models/cart_item_model.dart';

class ProductDetailsPage extends StatefulWidget {
  final String? marketId;
  final String? categoryId;
  final String? itemId;
  final CartItemModel? editItem; // For editing existing cart item

  const ProductDetailsPage({
    super.key,
    this.marketId,
    this.categoryId,
    this.itemId,
    this.editItem,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late TabController _tabController;

  double _scrollOffset = 0;
  int quantity = 1;
  double basePrice = 0.0;
  double additionalPrice = 0.0;

  Map<String, String?> _selectedOptions = {};
  String _name = '';
  String? _imageUrl;
  String _description = '';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _requiredOptions = [];
  List<Map<String, dynamic>> _extraOptions = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(
        () => setState(() => _scrollOffset = _scrollController.offset),
      );
    _tabController = TabController(length: 0, vsync: this);

    // If editing existing item, pre-fill the data
    if (widget.editItem != null) {
      _preFillEditData();
    }

    _loadProduct();
  }

  /// Pre-fill form data when editing an existing cart item
  void _preFillEditData() {
    final editItem = widget.editItem!;
    quantity = editItem.quantity;
    basePrice = editItem.productPrice;
    additionalPrice = editItem.additionalPrice;
    _selectedOptions = Map<String, String?>.from(editItem.selectedOptions);
  }

  Future<void> _loadProduct() async {
    final String marketId = widget.marketId ?? 'kb';
    final String? categoryId = widget.categoryId;
    final String? itemId = widget.itemId;
    if (categoryId == null || itemId == null) {
      setState(() {
        _error = 'مسار المنتج غير مكتمل';
        _loading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('markets')
          .doc(marketId)
          .collection('products')
          .doc(categoryId)
          .collection('items')
          .doc(itemId)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'لم يتم العثور على المنتج';
          _loading = false;
        });
        return;
      }

      final data = doc.data() ?? {};
      _name = data['name'] ?? '';
      _imageUrl = data['image'];
      _description = data['description'] ?? '';
      basePrice = (data['price'] ?? data['finalPrice'] ?? 0).toDouble();

      _requiredOptions = List<Map<String, dynamic>>.from(
        data['requiredOptions'] ?? [],
      );
      _extraOptions = List<Map<String, dynamic>>.from(
        data['extraOptions'] ?? [],
      );

      debugPrint('Product loaded: $_name');
      debugPrint('Required options: ${_requiredOptions.length}');
      debugPrint('Extra options: ${_extraOptions.length}');

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'تعذر تحميل بيانات المنتج';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _error != null) {
      return ProductLoadingError(loading: _loading, error: _error);
    }

    double totalPrice = (basePrice + additionalPrice) * quantity;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ProductHeaderSection(
                  name: _name,
                  imageUrl: _imageUrl,
                  description: _description,
                ),
                ..._requiredOptions.map(
                  (opt) => ProductOptionSection(
                    title: opt['title'] ?? 'اختيار',
                    options: List<Map<String, dynamic>>.from(opt['choices']),
                    isRequired: true,
                    selectedOptions: _selectedOptions,
                    onSelect: _handleOptionSelection,
                  ),
                ),
                ..._extraOptions.map(
                  (opt) => ProductOptionSection(
                    title: opt['title'] ?? 'إضافات',
                    options: List<Map<String, dynamic>>.from(opt['choices']),
                    isRequired: false,
                    selectedOptions: _selectedOptions,
                    onSelect: _handleOptionSelection,
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          MarketAppBar(
            scrollOffset: _scrollOffset,
            isMerged: false,
            tabController: _tabController,
            tabBarHeight: 0,
            onTabSelected: (_) {},
            tabs: const [],
            storeName: _name,
          ),
        ],
      ),
      bottomNavigationBar: ProductBottomBar(
        quantity: quantity,
        totalPrice: totalPrice,
        onAdd: _addToCart,
        onIncrease: () => setState(() => quantity++),
        onDecrease: () => setState(() => quantity > 1 ? quantity-- : quantity),
      ),
    );
  }

  void _handleOptionSelection(
    String title,
    String name,
    double price,
    bool selected,
  ) {
    setState(() {
      final allOptions = [..._requiredOptions, ..._extraOptions];
      final opt = allOptions.firstWhere((o) => o['title'] == title);
      final isRequired = _requiredOptions.contains(opt);

      if (isRequired) {
        if (selected) {
          if (_selectedOptions.containsKey(title)) {
            final prevName = _selectedOptions[title];
            final prevPrice = opt['choices'].firstWhere(
              (c) => c['name'] == prevName,
            )['price'];
            additionalPrice -= prevPrice;
          }
          _selectedOptions[title] = name;
          additionalPrice += price;
        } else {
          _selectedOptions.remove(title);
          additionalPrice -= price;
        }
      } else {
        final selectedList = _selectedOptions[title]?.split(',') ?? [];
        if (selected) {
          selectedList.add(name);
          additionalPrice += price;
        } else {
          selectedList.remove(name);
          additionalPrice -= price;
        }
        _selectedOptions[title] = selectedList.join(',');
      }
    });
  }

  /// Add item to cart with market validation
  Future<void> _addToCart() async {
    final cartViewModel = context.read<CartViewModel>();

    // Validate required options are selected
    if (!_validateRequiredOptions()) {
      _showErrorSnackBar('يرجى اختيار الخيارات المطلوبة');
      return;
    }

    try {
      // Create cart item
      final cartItem = CartItemModel(
        productId: widget.itemId ?? '',
        productName: _name,
        productImage: _imageUrl,
        productPrice: basePrice,
        selectedOptions: Map<String, dynamic>.from(_selectedOptions),
        quantity: quantity,
        marketId: widget.marketId ?? 'kb',
        categoryId: widget.categoryId ?? '',
        additionalPrice: additionalPrice,
      );

      // Try to add item to cart
      final success = await cartViewModel.addItem(cartItem);

      if (!success) {
        // Different market detected - show confirmation dialog
        await _showMarketReplacementDialog(cartViewModel, cartItem);
      } else {
        // Successfully added
        _showSuccessSnackBar('تم إضافة المنتج للسلة بنجاح');
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء إضافة المنتج للسلة');
      debugPrint('Add to cart error: $e');
    }
  }

  /// Validate that all required options are selected
  bool _validateRequiredOptions() {
    for (final option in _requiredOptions) {
      final title = option['title'] ?? '';
      if (!_selectedOptions.containsKey(title) ||
          _selectedOptions[title] == null) {
        return false;
      }
    }
    return true;
  }

  /// Show market replacement confirmation dialog
  Future<void> _showMarketReplacementDialog(
    CartViewModel cartViewModel,
    CartItemModel cartItem,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استبدال منتجات السلة'),
        content: const Text(
          'تحتوي سلة المشتريات الحالية على منتجات من متجر آخر. هل تريد استبدالها؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('استبدال'),
          ),
        ],
      ),
    );

    if (result == true) {
      // User confirmed replacement
      await cartViewModel.addItemWithMarketReplacement(cartItem);
      _showSuccessSnackBar('تم استبدال منتجات السلة وإضافة المنتج الجديد');
      Navigator.pop(context);
    }
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
