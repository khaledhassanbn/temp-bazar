import 'package:flutter/material.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'package:bazar_suez/markets/Markets_after_category/widget/custom_back_icon.dart';
import 'package:bazar_suez/markets/Markets_after_category/widget/search_bar_widget.dart';

class OrderCollapsibleHeader extends StatelessWidget {
  final String title;
  final bool showHeader;
  final List<String> suggestions;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;

  const OrderCollapsibleHeader({
    super.key,
    required this.title,
    required this.showHeader,
    required this.suggestions,
    required this.searchHint,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.mainColor.withOpacity(0.9),
            AppColors.mainColor.withOpacity(0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 🔹 العنوان مع زر الرجوع (يظهر فقط عند showHeader = true)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: showHeader ? 1.0 : 0.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: showHeader ? 48 : 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CustomBackIcon(onTap: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
            ),

            // 🔍 شريط البحث
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              margin: EdgeInsets.only(
                top: showHeader ? 4 : 8,
                left: 16,
                right: 16,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SearchBarWidget(suggestions: suggestions),
            ),
          ],
        ),
      ),
    );
  }
}
