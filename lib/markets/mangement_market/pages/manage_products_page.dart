import 'package:flutter/material.dart';
import 'package:bazar_suez/theme/app_color.dart';

import '../../add_product/models/product_models.dart';
import '../viewmodels/manage_products_viewmodel.dart';
import 'edit_product_page.dart';
import '../widgets/manage_products/categories_bar.dart';
import '../widgets/manage_products/products_list.dart';

class ManageProductsPage extends StatefulWidget {
  final String marketId;
  const ManageProductsPage({super.key, required this.marketId});

  @override
  State<ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  late final ManageProductsViewModel viewModel;

  // أبعاد مقيدة للبروكسي أثناء السحب (تغيّر لو تحب)
  static const double _barHeight = 66;
  static const double _proxyHeight = 56;
  static const double _proxyMaxWidth = 140;

  // أسماء الفئات التي تريدها غير قابلة لإعادة الترتيب
  final List<String> _fixedNames = ['الأكثر مبيعاً', 'العروض'];

  @override
  void initState() {
    super.initState();
    viewModel = ManageProductsViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await viewModel.loadCategories(widget.marketId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '💡 اضغط مطولًا على أيقونة السحب للعناصر المسموح سحبها فقط',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    });
  }

  bool _isFixedCategoryByName(String name) {
    return _fixedNames.contains(name);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: viewModel,
        builder: (context, _) {
          _handleMessages(context);
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text('إدارة المنتجات'),
              backgroundColor: AppColors.mainColor,
              foregroundColor: Colors.white,
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: "حفظ الترتيب",
                  onPressed: viewModel.isSavingOrder
                      ? null
                      : () => viewModel.saveCategoriesOrder(widget.marketId),
                  icon: viewModel.isSavingOrder
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: _barHeight,
                    child: ManageProductsCategoriesBar(
                      categories: viewModel.categories,
                      isLoading: viewModel.isLoadingCategories,
                      selectedCategory: viewModel.selectedCategory,
                      onCategorySelected: (category) async {
                        await viewModel.selectCategory(category);
                        await viewModel.loadProducts(
                          widget.marketId,
                          category.id,
                        );
                      },
                      onReorderRequested: (oldIndex, newIndex) =>
                          viewModel.onReorderCategories(
                            widget.marketId,
                            oldIndex,
                            newIndex,
                          ),
                      isFixedCategory: (category) =>
                          _isFixedCategoryByName(category.name),
                      proxyHeight: _proxyHeight,
                      proxyMaxWidth: _proxyMaxWidth,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ManageProductsList(
                      selectedCategory: viewModel.selectedCategory,
                      isLoadingProducts: viewModel.isLoadingProducts,
                      products: viewModel.filteredProducts,
                      onReorderProducts: (oldIndex, newIndex) {
                        final category = viewModel.selectedCategory;
                        if (category == null) return;
                        viewModel.onReorderProducts(
                          widget.marketId,
                          category.id,
                          oldIndex,
                          newIndex,
                        );
                      },
                      onEditProduct: _openEditProductPage,
                      onDeleteProduct: _confirmDelete,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleMessages(BuildContext context) {
    final error = viewModel.errorMessage;
    final success = viewModel.successMessage;

    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        viewModel.errorMessage = null;
      });
    }

    if (success != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
        viewModel.successMessage = null;
      });
    }
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل تريد حذف المنتج "${product.name}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      final categoryId = viewModel.selectedCategory!.id;
      await viewModel.deleteProduct(widget.marketId, categoryId, product.id);
    }
  }

  Future<void> _openEditProductPage(ProductModel product) async {
    final category = viewModel.selectedCategory;
    if (category == null) return;
    final updated = await Navigator.push<ProductModel>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductModernPage(
          marketId: widget.marketId,
          category: category,
          product: product,
        ),
      ),
    );
    if (updated != null) {
      viewModel.updateProductLocally(updated);
    }
  }
}
