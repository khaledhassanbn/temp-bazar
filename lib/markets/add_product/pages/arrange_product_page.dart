import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_color.dart';
import '../viewmodels/add_product_viewmodel.dart';

class ArrangeProductPage extends StatelessWidget {
  const ArrangeProductPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backgroundColor = AppColors.mainColor.withOpacity(0.08);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Consumer<AddProductViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoadingProductsForArrange) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = vm.productsInSelectedCategory;
          return SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 72),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.mainColor,
                        AppColors.mainColor.withOpacity(0.82),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ترتيب المنتج داخل الفئة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اسحب العناصر لتحديد ترتيب عرضها للعملاء',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -36),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 24,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFBFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE8EAEC),
                              ),
                            ),
                            child: Text(
                              'اسحب العناصر لترتيبها. الترتيب يبدأ من 1 بالأعلى.',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ReorderableListView.builder(
                              itemCount: items.length,
                              onReorder: (oldIndex, newIndex) {
                                vm.reorderInMemory(oldIndex, newIndex);
                              },
                              buildDefaultDragHandles: true,
                              itemBuilder: (context, index) {
                                final p = items[index];
                                final isTemp = p.id == 'temp_new';
                                return Container(
                                  key: ValueKey(p.id),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE8EAEC),
                                      width: 1.4,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.mainColor
                                          .withOpacity(0.1),
                                      child: Text(
                                        '${p.order}',
                                        style: TextStyle(
                                          color: AppColors.mainColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      isTemp ? '${p.name} (جديد)' : p.name,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'السعر: ${p.price}',
                                      textAlign: TextAlign.right,
                                    ),
                                    trailing: Icon(
                                      Icons.drag_indicator,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.mainColor,
                                    side: BorderSide(
                                      color: AppColors.mainColor,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text('رجوع لتحرير البيانات'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.mainColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: vm.isAddingProduct
                                      ? null
                                      : () async {
                                          try {
                                            await vm
                                                .saveArrangementIncludingNewIfAny();
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'تم الحفظ بنجاح',
                                                  ),
                                                ),
                                              );
                                              final marketId =
                                                  vm.selectedStore?.id;
                                              if (marketId != null &&
                                                  marketId.isNotEmpty) {
                                                context.go(
                                                  '/MyStorePage?marketId=$marketId',
                                                );
                                              } else {
                                                Navigator.of(
                                                  context,
                                                ).popUntil((r) => r.isFirst);
                                              }
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(content: Text('$e')),
                                              );
                                            }
                                          }
                                        },
                                  child: vm.isAddingProduct
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('حفظ الترتيب وإضافة المنتج'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
