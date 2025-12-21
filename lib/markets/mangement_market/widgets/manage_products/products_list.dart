import 'package:flutter/material.dart';

import '../../../../theme/app_color.dart';
import '../../../add_product/models/product_models.dart';

class ManageProductsList extends StatelessWidget {
  const ManageProductsList({
    super.key,
    required this.selectedCategory,
    required this.isLoadingProducts,
    required this.products,
    required this.onReorderProducts,
    required this.onEditProduct,
    required this.onDeleteProduct,
  });

  final ProductCategoryModel? selectedCategory;
  final bool isLoadingProducts;
  final List<ProductModel> products;
  final void Function(int oldIndex, int newIndex) onReorderProducts;
  final Future<void> Function(ProductModel product) onEditProduct;
  final Future<void> Function(ProductModel product) onDeleteProduct;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (selectedCategory == null) {
      return const Center(child: Text('اختر فئة لعرض منتجاتها'));
    }

    if (isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      return const Center(child: Text('لا توجد منتجات حالياً'));
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: products.length,
      onReorder: onReorderProducts,
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 48,
            height: 84,
            child: child,
          ),
        );
      },
      itemBuilder: (context, index) {
        final product = products[index];
        final displayIndex = _resolveDisplayIndex(product, index);

        return ReorderableDelayedDragStartListener(
          key: ValueKey('prod-${product.id}'),
          index: index,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ManageProductTile(
              product: product,
              displayIndex: displayIndex,
              onEdit: () => onEditProduct(product),
              onDelete: () => onDeleteProduct(product),
            ),
          ),
        );
      },
    );
  }

  int _resolveDisplayIndex(ProductModel product, int fallbackIndex) {
    if (product.order != 0) return product.order;
    return fallbackIndex + 1;
  }
}

class ManageProductTile extends StatelessWidget {
  const ManageProductTile({
    super.key,
    required this.product,
    required this.displayIndex,
    required this.onEdit,
    required this.onDelete,
  });

  final ProductModel product;
  final int displayIndex;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: _ProductThumbnail(imageUrl: product.image),
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.mainColor,
              child: Text(
                '$displayIndex',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        subtitle: Text(
          'السعر: ${product.price} — ${product.inStock ? 'متاح' : 'غير متاح'}',
          style: TextStyle(
            color: product.inStock ? Colors.green[700] : Colors.red[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: AppColors.mainColor),
              onPressed: onEdit,
              tooltip: 'تعديل',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'حذف',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 52,
        height: 52,
        color: Colors.grey[100],
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(imageUrl!, fit: BoxFit.cover)
            : const Icon(Icons.image_not_supported),
      ),
    );
  }
}
