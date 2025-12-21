import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_color.dart';
import '../viewmodels/add_product_viewmodel.dart';

class ArrangeProductPage extends StatelessWidget {
  const ArrangeProductPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.mainColor,
        title: const Text('ترتيب المنتج داخل الفئة'),
      ),
      body: Consumer<AddProductViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoadingProductsForArrange) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = vm.productsInSelectedCategory;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'اسحب العناصر لترتيبها. يجب أن تكون الأرقام متسلسلة من 1',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
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
                    return ListTile(
                      key: ValueKey(p.id),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.mainColor.withOpacity(0.1),
                        child: Text('${p.order}'),
                      ),
                      title: Text(isTemp ? '${p.name} (جديد)' : p.name),
                      subtitle: Text('السعر: ${p.price}'),
                      trailing: const Icon(Icons.drag_handle),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('رجوع لتحرير البيانات'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                        ),
                        onPressed: vm.isAddingProduct
                            ? null
                            : () async {
                                try {
                                  await vm.saveArrangementIncludingNewIfAny();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تم الحفظ بنجاح'),
                                      ),
                                    );
                                    final marketId = vm.selectedStore?.id;
                                    if (marketId != null &&
                                        marketId.isNotEmpty) {
                                      context.go(
                                        '/MyStorePage?marketId=' + marketId,
                                      );
                                    } else {
                                      Navigator.of(
                                        context,
                                      ).popUntil((r) => r.isFirst);
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
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
              ),
            ],
          );
        },
      ),
    );
  }
}
