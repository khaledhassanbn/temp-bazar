import 'package:bazar_suez/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'choice_product_card.dart';
import 'offer_product_card.dart';
import 'regular_product_card.dart';
import 'package:bazar_suez/markets/home_market/viewmodels/market_details_viewmodel.dart';

class MarketProductSection extends StatelessWidget {
  final Map<String, GlobalKey> sectionKeys;
  final List<MarketCategoryModel> categories;
  final String marketId;

  const MarketProductSection({
    super.key,
    required this.sectionKeys,
    required this.categories,
    required this.marketId,
  });

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];

    for (final category in categories) {
      final String nameTrim = category.name.trim();
      String normalizeArabic(String input) {
        final diacritics = RegExp('[\u064B-\u0652]');
        return input
            .replaceAll(diacritics, '')
            .replaceAll('أ', 'ا')
            .replaceAll('إ', 'ا')
            .replaceAll('آ', 'ا')
            .replaceAll('ى', 'ي')
            .replaceAll('ة', 'ه')
            .replaceAll('اً', 'ا')
            .trim();
      }

      final String normalizedName = normalizeArabic(nameTrim);

      // ✅ عنوان القسم
      sections.add(
        Container(
          key: sectionKeys[category.name],
          color: Colors.white,
          padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 0),
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 10),
              Text(
                category.name,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (normalizedName == 'الاكثر مبيعا') ...[
                const SizedBox(
                  height: 10,
                ), // مسافة مريحة قبل المنتجات للأكثر مبيعاً
              ] else
                const SizedBox(height: 16), // مسافة احترافية للفئات الأخرى
            ],
          ),
        ),
      );

      // ✅ قسم "الأكثر مبيعا"
      // ✅ قسم "الأكثر مبيعا"
      if (normalizedName == 'الاكثر مبيعا') {
        sections.add(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: category.items.map((item) {
                      final String catId = category.id;
                      final String itemId = item.id;
                      final double? originalPrice = item.price?.toDouble();
                      final double? finalPrice = item.finalPrice?.toDouble();
                      final bool hasDiscount =
                          finalPrice != null &&
                          originalPrice != null &&
                          finalPrice < originalPrice;
                      return SizedBox(
                        width:
                            (constraints.maxWidth - 12) / 2, // نفس شبكة 2 أعمدة
                        child: ChoiceProductCard(
                          title: item.name,
                          imageUrl: item.imageUrl,
                          price: hasDiscount
                              ? finalPrice
                              : (originalPrice ?? finalPrice),
                          originalPrice: hasDiscount ? originalPrice : null,
                          onAdd: () {},
                          onTap: () {
                            context.push(
                              '/productdetails?marketId=$marketId&categoryId=$catId&itemId=$itemId',
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        );
      }
      // ✅ قسم "العروض"
      else if (normalizedName == 'العروض') {
        sections.add(
          Container(
            color: AppColors.mainColor, // ✅ استخدم اللون الأساسي كخلفية
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: category.items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final item = category.items[index];
                    final double? originalPrice = item.price?.toDouble();
                    final double? finalPrice = item.finalPrice?.toDouble();
                    final bool hasDiscount =
                        finalPrice != null &&
                        originalPrice != null &&
                        finalPrice < originalPrice;
                    return OfferProductCard(
                      title: item.name,
                      imageUrl: item.imageUrl,
                      price: hasDiscount
                          ? finalPrice
                          : (finalPrice ?? originalPrice),
                      originalPrice: hasDiscount ? originalPrice : null,
                      discountText: null,
                      onAdd: () {},
                      onTap: () {
                        final String catId = category.id;
                        final String itemId = item.id;
                        context.push(
                          '/productdetails?marketId=$marketId&categoryId=$catId&itemId=$itemId',
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }
      // ✅ باقي الفئات (قائمة بشكل Talabat)
      else {
        sections.add(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: category.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final double? originalPrice = item.price?.toDouble();
                final double? finalPrice = item.finalPrice?.toDouble();
                final bool hasDiscount =
                    finalPrice != null &&
                    originalPrice != null &&
                    finalPrice < originalPrice;
                return RegularProductCard(
                  productName: item.name,
                  productDescription: item.description ?? '',
                  imageUrl: item.imageUrl,
                  price: originalPrice ?? finalPrice,
                  discountPrice: hasDiscount ? finalPrice : null,
                  onAdd: () {},
                  topMargin: index == 0 ? 0 : 6,
                  onTap: () {
                    final String catId = category.id;
                    final String itemId = item.id;
                    context.push(
                      '/productdetails?marketId=$marketId&categoryId=$catId&itemId=$itemId',
                    );
                  },
                );
              }).toList(),
            ),
          ),
        );
      }
    }

    return Column(children: sections);
  }
}
