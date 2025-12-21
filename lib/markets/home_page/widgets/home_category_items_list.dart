import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/markets/Markets_after_category/viewmodel/category_filter_viewmodel.dart';

class HomeCategoryItemsList extends StatelessWidget {
  const HomeCategoryItemsList({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryFilterViewModel>();

    if (vm.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final items = vm.stores;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final store = items[index];

        return InkWell(
          onTap: () {
            final link = store.link;
            context.push('/HomeMarketPage?marketLink=$link');
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                // ---------- الصورة بدون أي خلفية أو حدود ----------
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: store.logoUrl != null && store.logoUrl!.isNotEmpty
                        ? Image.network(store.logoUrl!, fit: BoxFit.cover)
                        : Image.asset(
                            'assets/images/egypt.jpg',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // ---------- النص ----------
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        store.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
