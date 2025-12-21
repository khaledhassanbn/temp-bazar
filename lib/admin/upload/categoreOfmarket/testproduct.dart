import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج المنتج
class MarketItemModel {
  final String id;
  final String name;
  final num? price;
  final String? imageUrl;

  MarketItemModel({
    required this.id,
    required this.name,
    this.price,
    this.imageUrl,
  });

  factory MarketItemModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MarketItemModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      price: data['price'] as num?,
      imageUrl: data['image']?.toString(),
    );
  }
}

/// نموذج الفئة
class MarketCategoryModel {
  final String id;
  final String name;
  final List<MarketItemModel> items;

  MarketCategoryModel({
    required this.id,
    required this.name,
    this.items = const [],
  });
}

/// صفحة عرض منتجات المتجر
class MarketProductsPage extends StatefulWidget {
  final String marketId; // 👈 اسم المتجر (kb مثلاً)
  const MarketProductsPage({super.key, required this.marketId});

  @override
  State<MarketProductsPage> createState() => _MarketProductsPageState();
}

class _MarketProductsPageState extends State<MarketProductsPage> {
  bool _loading = true;
  String? _error;
  List<MarketCategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadMarketData();
  }

  Future<void> _loadMarketData() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final productsCollection = firestore
          .collection('markets')
          .doc(widget.marketId)
          .collection('products');

      final categoriesSnapshot = await productsCollection.get();
      List<MarketCategoryModel> tempCategories = [];

      for (var categoryDoc in categoriesSnapshot.docs) {
        final itemsSnap = await productsCollection
            .doc(categoryDoc.id)
            .collection('items')
            .get();

        final items = itemsSnap.docs.map(MarketItemModel.fromDoc).toList();

        // تجاهل الفئة لو فاضية
        if (items.isNotEmpty) {
          tempCategories.add(MarketCategoryModel(
            id: categoryDoc.id,
            name: categoryDoc.id, // لأن الاسم هو ID
            items: items,
          ));
        }
      }

      // ترتيب خاص
      tempCategories.sort((a, b) {
        if (a.name == "الأكثر مبيعا") return -1;
        if (b.name == "الأكثر مبيعا") return 1;
        if (a.name == "العروض") return -1;
        if (b.name == "العروض") return 1;
        return 0;
      });

      setState(() {
        _categories = tempCategories;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "حدث خطأ أثناء تحميل البيانات: $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("منتجات المتجر"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _categories.isEmpty
                  ? const Center(child: Text("لا توجد منتجات متاحة"))
                  : ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];

                        // لو "الأكثر مبيعاً"
                        if (category.name == "الأكثر مبيعا") {
                          return _buildBestSellers(category);
                        }

                        // لو "العروض"
                        if (category.name == "العروض") {
                          return _buildOffers(category);
                        }

                        // باقي الفئات
                        return _buildRegularCategory(category);
                      },
                    ),
    );
  }

  Widget _buildBestSellers(MarketCategoryModel category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "اختياراتك",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: category.items.length,
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final item = category.items[index];
            return _buildItemCard(item);
          },
        ),
      ],
    );
  }

  Widget _buildOffers(MarketCategoryModel category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "العروض",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: category.items.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              final item = category.items[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildItemCard(item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRegularCategory(MarketCategoryModel category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            category.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ...category.items.map(_buildListItem).toList(),
      ],
    );
  }

  Widget _buildItemCard(MarketItemModel item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                item.imageUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(item.name,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  "${item.price ?? 0} ج.م",
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(MarketItemModel item) {
    return ListTile(
      leading: item.imageUrl != null
          ? Image.network(item.imageUrl!, width: 60, height: 60, fit: BoxFit.cover)
          : const Icon(Icons.image),
      title: Text(item.name, textAlign: TextAlign.right),
      subtitle: Text("${item.price ?? 0} ج.م", textAlign: TextAlign.right),
    );
  }
}
