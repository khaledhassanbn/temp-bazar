import 'package:flutter/material.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'package:bazar_suez/models/review_model.dart';
import 'package:bazar_suez/services/review_service.dart';
import '../widgets/review_card.dart';
import '../widgets/rating_bar_chart.dart';

/// صفحة عرض تقييمات المتجر
class StoreReviewsPage extends StatefulWidget {
  final String storeId;
  final String storeName;

  const StoreReviewsPage({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<StoreReviewsPage> createState() => _StoreReviewsPageState();
}

class _StoreReviewsPageState extends State<StoreReviewsPage> {
  final ReviewService _reviewService = ReviewService();
  int? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'تقييمات ${widget.storeName}',
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.mainColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // إحصائيات التقييم
            FutureBuilder<RatingStatistics>(
              future: _reviewService.getStoreRatingStatistics(widget.storeId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final stats = snapshot.data!;
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // المتوسط العام
                      Column(
                        children: [
                          Text(
                            stats.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < stats.averageRating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${stats.totalReviews} تقييم',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      // توزيع النجوم
                      Expanded(
                        child: RatingBarChart(statistics: stats),
                      ),
                    ],
                  ),
                );
              },
            ),

            // فلاتر النجوم
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip(null, 'الكل'),
                  for (int i = 5; i >= 1; i--)
                    _buildFilterChip(i, '$i نجوم'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // قائمة التقييمات
            Expanded(
              child: StreamBuilder<List<ReviewModel>>(
                stream: _reviewService.getStoreReviews(widget.storeId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'لا توجد تقييمات بعد',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  var reviews = snapshot.data!;

                  // تطبيق الفلتر
                  if (_selectedFilter != null) {
                    reviews = reviews
                        .where((r) => r.rating == _selectedFilter)
                        .toList();
                  }

                  if (reviews.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد تقييمات بهذا التصنيف',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      return ReviewCard(review: reviews[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(int? filter, String label) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? filter : null;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.mainColor.withOpacity(0.2),
        checkmarkColor: AppColors.mainColor,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.mainColor : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
