import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/markets/cart/viewmodels/cart_view_model.dart';
import 'package:bazar_suez/markets/cart/models/cart_item_model.dart';
import 'package:bazar_suez/markets/create_market/models/working_hours.dart';
import 'package:bazar_suez/theme/app_color.dart';

class ProductDetailsPage extends StatefulWidget {
  final String? marketId;
  final String? categoryId;
  final String? itemId;
  final CartItemModel? editItem;

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

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _noteController = TextEditingController();

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
  bool _storeAvailable = true;
  bool _storeClosedByWorkingHours = false;

  // AppBar opacity based on scroll
  final ValueNotifier<double> _appBarOpacity = ValueNotifier(0.0);

  static const Color _primaryGreen = AppColors.mainColor;
  static const Color _darkGreen = Color(0xFF2A5C6D);
  static const Color _lightGreen = Color(0xFFE0F2F7);
  static const Color _bgGray = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.editItem != null) _preFillEditData();
    _loadProduct();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    // AppBar fully visible after scrolling 180px (image height)
    final opacity = (offset / 180.0).clamp(0.0, 1.0);
    _appBarOpacity.value = opacity;
  }

  void _preFillEditData() {
    final e = widget.editItem!;
    quantity = e.quantity;
    basePrice = e.productPrice;
    additionalPrice = e.additionalPrice;
    _selectedOptions = Map<String, String?>.from(e.selectedOptions);
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

    final marketsRef =
        FirebaseFirestore.instance.collection('markets').doc(marketId);
    final itemRef = marketsRef
        .collection('products')
        .doc(categoryId)
        .collection('items')
        .doc(itemId);

    void applyMarketData(Map<String, dynamic> marketData) {
      _storeAvailable = marketData['available'] is bool
          ? marketData['available'] as bool
          : (marketData['storeStatus'] as bool? ?? true);

      if (marketData['workingHours'] is Map<String, dynamic>) {
        final weekly = WeeklyWorkingHours.fromMap(
          marketData['workingHours'] as Map<String, dynamic>,
        );
        _storeClosedByWorkingHours = !weekly.isOpenAt(DateTime.now());
      }
    }

    void applyItemData(Map<String, dynamic> data) {
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
    }

    try {
      // فتح سريع: حاول الكاش أولًا (تجنّب انتظار السيرفر 10-20 ثانية)
      DocumentSnapshot<Map<String, dynamic>> cacheMarketDoc;
      DocumentSnapshot<Map<String, dynamic>> cacheItemDoc;
      try {
        final cacheResults = await Future.wait<Object?>([
          marketsRef.get(const GetOptions(source: Source.cache)),
          itemRef.get(const GetOptions(source: Source.cache)),
        ]);
        cacheMarketDoc =
            cacheResults[0]! as DocumentSnapshot<Map<String, dynamic>>;
        cacheItemDoc = cacheResults[1]! as DocumentSnapshot<Map<String, dynamic>>;
      } catch (_) {
        cacheMarketDoc =
            await marketsRef.get(const GetOptions(source: Source.cache));
        cacheItemDoc = await itemRef.get(const GetOptions(source: Source.cache));
      }

      if (cacheMarketDoc.exists) applyMarketData(cacheMarketDoc.data() ?? {});
      if (cacheItemDoc.exists) {
        applyItemData(cacheItemDoc.data() ?? {});
        if (mounted) {
          setState(() {
            _loading = false;
            _error = null;
          });
        }
      }

      // تحديث لاحق من السيرفر بدون حجب الـUI
      unawaited(() async {
        try {
          final serverResults = await Future.wait<Object?>([
            marketsRef.get(const GetOptions(source: Source.serverAndCache)),
            itemRef.get(const GetOptions(source: Source.serverAndCache)),
          ]);
          final marketDoc =
              serverResults[0]! as DocumentSnapshot<Map<String, dynamic>>;
          final itemDoc =
              serverResults[1]! as DocumentSnapshot<Map<String, dynamic>>;

          if (!itemDoc.exists) {
            if (!mounted) return;
            setState(() {
              _error = 'لم يتم العثور على المنتج';
              _loading = false;
            });
            return;
          }

          applyMarketData(marketDoc.data() ?? {});
          applyItemData(itemDoc.data() ?? {});
          if (!mounted) return;
          setState(() {
            _loading = false;
            _error = null;
          });
        } catch (_) {
          // تجاهل خطأ التحديث الخلفي
        }
      }());

      // لو مفيش كاش، هنفضل على شاشة التحميل لحد ما السيرفر يرد
      if (!cacheItemDoc.exists && mounted) {
        setState(() => _loading = true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل بيانات المنتج';
        _loading = false;
      });
    }
  }

  double get _totalPrice => (basePrice + additionalPrice) * quantity;

  @override
  void dispose() {
    _scrollController.dispose();
    _noteController.dispose();
    _appBarOpacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoadingScreen();
    if (_error != null) return _buildErrorScreen();

    return Scaffold(
      backgroundColor: _bgGray,
      body: Stack(
        children: [
          // ── Scrollable content ──
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroImage(),
                _buildInfoCard(),
                if (_requiredOptions.isNotEmpty) ...[
                  ..._requiredOptions.map(
                    (opt) => _buildOptionSection(opt, isRequired: true),
                  ),
                ],
                if (_extraOptions.isNotEmpty) ...[
                  ..._extraOptions.map(
                    (opt) => _buildOptionSection(opt, isRequired: false),
                  ),
                ],
                _buildNoteField(),
                const SizedBox(height: 110),
              ],
            ),
          ),
          // ── Transparent → solid AppBar ──
          _buildAnimatedAppBar(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─────────────────────────────────────────────
  // HERO IMAGE
  // ─────────────────────────────────────────────
  Widget _buildHeroImage() {
    return SizedBox(
      height: 270,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image or placeholder with disk cache
          _imageUrl != null && _imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: _imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 270,
                  placeholder: (_, __) => Container(
                    color: _lightGreen,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: _primaryGreen,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => _imagePlaceholder(),
                )
              : _imagePlaceholder(),
          // Bottom gradient fade
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, _bgGray],
                ),
              ),
            ),
          ),
          // Store status badge
          if (!_storeAvailable || _storeClosedByWorkingHours)
            Positioned(
              top: 60,
              right: 16,
              child: _statusBadge(
                _storeClosedByWorkingHours
                    ? 'المتجر مغلق حالياً'
                    : 'المتجر مشغول',
                Colors.red.shade700,
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: _lightGreen,
      child: const Center(
        child: Icon(Icons.fastfood_rounded, size: 80, color: Color(0xFF9FE1CB)),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // INFO CARD
  // ─────────────────────────────────────────────
  Widget _buildInfoCard() {
    // Flutter يمنع margin السالب (بيعمل assertion)،
    // فبنحافظ على نفس التأثير البصري باستخدام Transform.
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Name
              Text(
                _name,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 10),
              // Description
              if (_description.isNotEmpty)
                Text(
                  _description,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888780),
                    height: 1.6,
                  ),
                ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 14),
              // Price + delivery
              Row(
                children: [
                  const SizedBox.shrink(),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${basePrice.toStringAsFixed(0)} جنيه',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _primaryGreen,
                      ),
                    ),
                    const Text(
                      'السعر الأساسي',
                      style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // OPTION SECTION
  // ─────────────────────────────────────────────
  Widget _buildOptionSection(
    Map<String, dynamic> opt, {
    required bool isRequired,
  }) {
    final String title = opt['title'] ?? (isRequired ? 'اختيار' : 'إضافات');
    final List<Map<String, dynamic>> choices = List<Map<String, dynamic>>.from(
      opt['choices'] ?? [],
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Section header
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isRequired)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAECE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'مطلوب',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF993C1D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Choices
            isRequired
                ? _buildRequiredChoices(title, choices)
                : _buildExtraChoices(title, choices),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredChoices(
    String title,
    List<Map<String, dynamic>> choices,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: choices.map((choice) {
        final String name = choice['name'] ?? '';
        final double price = (choice['price'] ?? 0).toDouble();
        final bool selected = _selectedOptions[title] == name;

        return GestureDetector(
          onTap: () => _handleOptionSelection(title, name, price, !selected),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? _lightGreen : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? _primaryGreen : const Color(0xFFE0E0E0),
                width: selected ? 1.5 : 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? _darkGreen : const Color(0xFF1A1A1A),
                  ),
                ),
                if (price > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '+ ${price.toStringAsFixed(0)} ج',
                    style: TextStyle(
                      fontSize: 11,
                      color: selected ? _primaryGreen : const Color(0xFF888780),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExtraChoices(String title, List<Map<String, dynamic>> choices) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: choices.map((choice) {
        final String name = choice['name'] ?? '';
        final double price = (choice['price'] ?? 0).toDouble();
        final selectedList = (_selectedOptions[title] ?? '')
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList();
        final bool selected = selectedList.contains(name);

        return GestureDetector(
          onTap: () => _handleOptionSelection(title, name, price, !selected),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? _lightGreen : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? _primaryGreen : const Color(0xFFE0E0E0),
                width: selected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  price > 0 ? '$name  +${price.toStringAsFixed(0)} ج' : name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected ? _darkGreen : const Color(0xFF1A1A1A),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: _primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────
  // NOTE FIELD
  // ─────────────────────────────────────────────
  Widget _buildNoteField() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'ملاحظة خاصة',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'مثال: بدون بصل، صوص جانبي...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFBBBBBB),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFEEEEEE),
                    width: 0.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFEEEEEE),
                    width: 0.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _primaryGreen, width: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ANIMATED APP BAR
  // ─────────────────────────────────────────────
  Widget _buildAnimatedAppBar() {
    return ValueListenableBuilder<double>(
      valueListenable: _appBarOpacity,
      builder: (context, opacity, _) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.white.withOpacity(opacity),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    // Back button
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Material(
                        color: Colors.white.withOpacity(
                          opacity < 0.5 ? 0.85 : 0,
                        ),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 20,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Title (visible when scrolled)
                    Expanded(
                      child: Opacity(
                        opacity: opacity,
                        child: Text(
                          _name,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM BAR
  // ─────────────────────────────────────────────
  Widget _buildBottomBar() {
    final bool canAdd = _storeAvailable && !_storeClosedByWorkingHours;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5)),
      ),
      child: Row(
        children: [
          // Quantity control
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDDDDDD), width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _qtyButton(
                  icon: Icons.remove,
                  onTap: () => setState(() => quantity > 1 ? quantity-- : null),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _qtyButton(
                  icon: Icons.add,
                  onTap: () => setState(() => quantity++),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Add to cart button
          Expanded(
            child: GestureDetector(
              onTap: canAdd
                  ? _addToCart
                  : () => _showErrorSnackBar(
                      _storeClosedByWorkingHours
                          ? 'المتجر مغلق حالياً حسب مواعيد العمل'
                          : 'المتجر مشغول حالياً',
                    ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  color: canAdd ? _primaryGreen : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_bag_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'أضف للسلة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_totalPrice.toStringAsFixed(2)} ج',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Icon(icon, size: 18, color: _primaryGreen),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LOADING / ERROR
  // ─────────────────────────────────────────────
  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Center(
        child: CircularProgressIndicator(
          color: _primaryGreen,
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Color(0xFF1A1A1A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Color(0xFFDDDDDD),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'حدث خطأ',
              style: const TextStyle(fontSize: 15, color: Color(0xFF888780)),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadProduct();
              },
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(color: _primaryGreen, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // OPTION LOGIC
  // ─────────────────────────────────────────────
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
            final prevPrice = (opt['choices'] as List).firstWhere(
              (c) => c['name'] == prevName,
            )['price'];
            additionalPrice -= (prevPrice as num).toDouble();
          }
          _selectedOptions[title] = name;
          additionalPrice += price;
        } else {
          _selectedOptions.remove(title);
          additionalPrice -= price;
        }
      } else {
        final selectedList = (_selectedOptions[title] ?? '')
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList();
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

  bool _validateRequiredOptions() {
    for (final option in _requiredOptions) {
      final title = option['title'] ?? '';
      if (!_selectedOptions.containsKey(title) ||
          _selectedOptions[title] == null ||
          _selectedOptions[title]!.isEmpty) {
        return false;
      }
    }
    return true;
  }

  // ─────────────────────────────────────────────
  // CART LOGIC
  // ─────────────────────────────────────────────
  Future<void> _addToCart() async {
    if (!_storeAvailable || _storeClosedByWorkingHours) {
      _showErrorSnackBar(
        _storeClosedByWorkingHours
            ? 'المتجر مغلق حالياً حسب مواعيد العمل'
            : 'المتجر مشغول حالياً، لا يمكن الإضافة',
      );
      return;
    }

    if (!_validateRequiredOptions()) {
      _showErrorSnackBar('يرجى اختيار الخيارات المطلوبة');
      return;
    }

    final cartViewModel = context.read<CartViewModel>();

    try {
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

      final success = await cartViewModel.addItem(cartItem);

      if (!success) {
        await _showMarketReplacementDialog(cartViewModel, cartItem);
      } else {
        // _showSuccessSnackBar('تم إضافة المنتج للسلة بنجاح');
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء إضافة المنتج للسلة');
      debugPrint('Add to cart error: $e');
    }
  }

  Future<void> _showMarketReplacementDialog(
    CartViewModel cartViewModel,
    CartItemModel cartItem,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'استبدال منتجات السلة',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'سلة مشترياتك تحتوي على منتجات من متجر آخر. هل تريد استبدالها بهذا المنتج؟',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 14, color: Color(0xFF888780)),
        ),
        actionsAlignment: MainAxisAlignment.start,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'استبدال',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Color(0xFF888780)),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await cartViewModel.addItemWithMarketReplacement(cartItem);
      _showSuccessSnackBar('تم استبدال السلة وإضافة المنتج الجديد');
      Navigator.pop(context);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: _primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
