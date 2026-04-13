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
    required this.onToggleStatus,
  });

  final ProductCategoryModel? selectedCategory;
  final bool isLoadingProducts;
  final List<ProductModel> products;
  final void Function(int oldIndex, int newIndex) onReorderProducts;
  final Future<void> Function(ProductModel product) onEditProduct;
  final Future<void> Function(ProductModel product) onDeleteProduct;
  final Future<void> Function(ProductModel product) onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (selectedCategory == null) {
      return _EmptyState(
        icon: Icons.category_outlined,
        message: 'اختر فئة لعرض منتجاتها',
      );
    }

    if (isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      return _EmptyState(
        icon: Icons.inventory_2_outlined,
        message: 'لا توجد منتجات حالياً',
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: products.length,
      onReorder: onReorderProducts,
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(14),
          shadowColor: AppColors.mainColor.withOpacity(0.3),
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 48,
            child: child,
          ),
        );
      },
      itemBuilder: (context, index) {
        final product = products[index];
        final displayIndex = product.order != 0 ? product.order : index + 1;

        return Padding(
          key: ValueKey('prod-${product.id}'),
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: ReorderableDelayedDragStartListener(
            index: index,
            child: ManageProductTile(
              product: product,
              displayIndex: displayIndex,
              onEdit: () => onEditProduct(product),
              onDelete: () => onDeleteProduct(product),
              onToggleStatus: () => onToggleStatus(product),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class ManageProductTile extends StatelessWidget {
  const ManageProductTile({
    super.key,
    required this.product,
    required this.displayIndex,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  final ProductModel product;
  final int displayIndex;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Drag handle indicator (subtle) ──
            Icon(Icons.drag_indicator, color: Colors.grey.shade300, size: 20),
            const SizedBox(width: 6),

            // ── Thumbnail ──
            _ProductThumbnail(imageUrl: product.image),
            const SizedBox(width: 10),

            // ── Info section ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Order badge
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.mainColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$displayIndex',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Price badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.mainColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${product.price} ج',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainColor,
                          ),
                        ),
                      ),
                      // Stock limit badge — يظهر فقط لو التاجر حدد كمية
                      if (product.hasStockLimit) ...[
                        Builder(builder: (context) {
                          final remaining = product.stock - product.soldCount;
                          final isOut = remaining <= 0;
                          final badgeColor = isOut
                              ? Colors.red
                              : remaining <= 3
                                  ? Colors.orange
                                  : Colors.teal;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isOut
                                  ? '⛔ نفدت الكمية'
                                  : '📦 متبقي $remaining/${product.stock}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: badgeColor.shade700,
                              ),
                            ),
                          );
                        }),
                      ],
                      // Expiry date badge — يظهر لو التاجر حدد تاريخ إزالة
                      if (product.endAt != null) ...[
                        Builder(builder: (context) {
                          final now = DateTime.now();
                          final isExpired = now.isAfter(product.endAt!);
                          final d = product.endAt!;
                          final label =
                              '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isExpired
                                  ? Colors.red.withOpacity(0.12)
                                  : Colors.amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isExpired
                                  ? '⏰ انتهى: $label'
                                  : '⏳ ينتهي: $label',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isExpired
                                    ? Colors.red.shade700
                                    : Colors.amber.shade800,
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Actions ──
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Toggle switch (compact)
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: product.status,
                    onChanged: (_) => onToggleStatus(),
                    activeColor: AppColors.mainColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit button
                    _ActionIconBtn(
                      icon: Icons.edit_outlined,
                      color: AppColors.mainColor,
                      onPressed: onEdit,
                      tooltip: 'تعديل',
                    ),
                    const SizedBox(width: 4),
                    // Delete button
                    _ActionIconBtn(
                      icon: Icons.delete_outline,
                      color: Colors.red.shade400,
                      onPressed: onDelete,
                      tooltip: 'حذف',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIconBtn extends StatelessWidget {
  const _ActionIconBtn({
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 56,
        height: 56,
        color: Colors.grey[100],
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.broken_image, color: Colors.grey.shade400),
              )
            : Icon(Icons.image_not_supported,
                color: Colors.grey.shade400, size: 28),
      ),
    );
  }
}