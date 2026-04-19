import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/markets/search_in_market/viewmodels/search_in_market_viewmodel.dart';
import 'package:bazar_suez/markets/search_in_market/models/search_in_market_product_entry.dart';

const String _kImagePlaceholder =
    'https://images.pexels.com/photos/70497/pexels-photo-70497.jpeg?auto=compress&cs=tinysrgb&w=400';

/// شاشة بحث منتجات المتجر (MVVM — الـ ViewModel يُمرَّر من الخارج عبر [ChangeNotifierProvider])
class SearchInMarketPage extends StatelessWidget {
  const SearchInMarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(
                        side: BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(Icons.arrow_back, color: Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Consumer<SearchInMarketViewModel>(
                        builder: (context, vm, _) {
                          return TextField(
                            controller: vm.searchController,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'بحث في القائمة',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 15,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF2F2F2),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey.shade600,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<SearchInMarketViewModel>(
                  builder: (context, vm, _) {
                    final list = vm.filteredEntries;
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          vm.searchController.text.trim().isEmpty
                              ? 'لا توجد منتجات في هذا المتجر'
                              : 'لا توجد نتائج مطابقة',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade300,
                        indent: 12,
                        endIndent: 12,
                      ),
                      itemBuilder: (context, index) {
                        return _SearchProductTile(
                          entry: list[index],
                          marketId: vm.marketId,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchProductTile extends StatelessWidget {
  const _SearchProductTile({
    required this.entry,
    required this.marketId,
  });

  final SearchInMarketProductEntry entry;
  final String marketId;

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final original = item.price?.toDouble();
    final discounted = item.finalPrice?.toDouble();
    final hasDiscount =
        original != null &&
        discounted != null &&
        discounted < original;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push(
            '/productdetails?marketId=$marketId&categoryId=${entry.categoryId}&itemId=${item.id}',
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.name,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description?.trim().isNotEmpty == true
                            ? item.description!.trim()
                            : ' ',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.25,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      _PriceBlock(
                        original: original,
                        discounted: discounted,
                        hasDiscount: hasDiscount,
                      ),
                    ],
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl ?? '',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey.shade200,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.original,
    required this.discounted,
    required this.hasDiscount,
  });

  final double? original;
  final double? discounted;
  final bool hasDiscount;

  static const Color _discountPurple = Color(0xFF6B4CE6);

  @override
  Widget build(BuildContext context) {
    if (hasDiscount && original != null && discounted != null) {
      final o = original!;
      final d = discounted!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${o.toStringAsFixed(2)} ج.م',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _discountPurple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${d.toStringAsFixed(2)} ج.م',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }

    final display = discounted ?? original;
    return Text(
      '${display?.toStringAsFixed(2) ?? '—'} ج.م',
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    );
  }
}
