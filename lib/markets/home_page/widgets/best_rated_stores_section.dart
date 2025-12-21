import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../theme/app_color.dart';
import 'home_best_restaurants_section.dart';
import 'home_restaurant_card.dart';
import '../../create_market/models/store_model.dart';

class BestRatedStoresSection extends StatefulWidget {
  const BestRatedStoresSection({super.key});

  @override
  State<BestRatedStoresSection> createState() => _BestRatedStoresSectionState();
}

class _BestRatedStoresSectionState extends State<BestRatedStoresSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<StoreModel> stores = [];
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _fetchStores();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchStores() async {
    try {
      if (!mounted) return;
      setState(() => isLoading = true);

      // جلب أول 12 متجر من Firebase
      final querySnapshot = await _firestore
          .collection('markets')
          .where('isVisible', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .limit(12)
          .get();

      final fetchedStores = querySnapshot.docs
          .map((doc) => StoreModel.fromMap(doc.id, doc.data()))
          .toList();

      if (!mounted) return;
      setState(() {
        stores = fetchedStores;
        isLoading = false;
      });
    } catch (e) {
      print('خطأ في جلب المتاجر: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  // 🔹 تحويل المتاجر إلى أعمدة (كل عمود يحتوي على متجرين)
  List<List<HomeRestaurantCard>> _convertStoresToColumns() {
    if (stores.isEmpty) return [];

    List<List<HomeRestaurantCard>> columns = [];
    List<HomeRestaurantCard> currentColumn = [];

    for (int i = 0; i < stores.length; i++) {
      final store = stores[i];

      // معلومات افتراضية (يمكن تحديثها لاحقاً من قاعدة البيانات)
      final rating = '4.3 ⭐'; // يمكن جلبها من قاعدة البيانات
      final info = '30-45 دقيقة • 6.99 ج.م'; // يمكن جلبها من قاعدة البيانات

      currentColumn.add(
        HomeRestaurantCard(
          name: store.name,
          rating: rating,
          info: info,
          imageUrl: store.logoUrl,
          storeLink: store.link,
        ),
      );

      // كل عمود يحتوي على متجرين
      if (currentColumn.length == 2 || i == stores.length - 1) {
        columns.add(List.from(currentColumn));
        currentColumn.clear();
      }
    }

    return columns;
  }

  // 🔹 بدء التمرير التلقائي
  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      // إضافة listener للكشف عن تمرير المستخدم
      _scrollController.addListener(_onScroll);

      // بدء التمرير التلقائي
      _autoScroll();
    });
  }

  // 🔹 معالج التمرير
  void _onScroll() {
    if (_scrollController.position.userScrollDirection !=
        ScrollDirection.idle) {
      _isScrolling = true;
      // إعادة تفعيل التمرير التلقائي بعد 3 ثواني
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _isScrolling = false;
        }
      });
    }
  }

  // 🔹 التمرير التلقائي
  void _autoScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    if (!_isScrolling) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      if (maxScroll <= 0) {
        // لا يوجد محتوى للتمرير
        Future.delayed(const Duration(seconds: 1), () => _autoScroll());
        return;
      }

      if (currentScroll >= maxScroll - 10) {
        // الوصول للنهاية - العودة للبداية
        _scrollController
            .animateTo(
              0,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            )
            .then((_) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) _autoScroll();
              });
            });
      } else {
        // التمرير للأمام
        _scrollController
            .animateTo(
              currentScroll + 0.5,
              duration: const Duration(milliseconds: 30),
              curve: Curves.linear,
            )
            .then((_) {
              Future.delayed(const Duration(milliseconds: 30), () {
                if (mounted) _autoScroll();
              });
            });
      }
    } else {
      // المستخدم يقوم بالتمرير - المحاولة مرة أخرى بعد ثانية
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _autoScroll();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ClipPath(
        clipper: HomeWaveClipper(),
        child: Container(
          width: double.infinity,
          height: 410,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.mainColor,
                AppColors.mainColor.withOpacity(0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (stores.isEmpty) {
      return const SizedBox.shrink();
    }

    final columns = _convertStoresToColumns();

    return HomeBestRestaurantsSection(
      title: 'أفضل المطاعم تصنيفاً',
      data: columns,
      scrollController: _scrollController,
    );
  }
}
