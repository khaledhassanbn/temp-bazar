import 'package:flutter/material.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'package:bazar_suez/markets/Markets_after_category/widget/custom_back_icon.dart';
import 'package:go_router/go_router.dart';

class OrderCollapsibleHeader extends StatelessWidget {
  final String title;
  final bool showHeader;
  final List<String> suggestions;
  final String searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String> onSearchChanged;

  const OrderCollapsibleHeader({
    super.key,
    required this.title,
    required this.showHeader,
    required this.suggestions,
    required this.searchHint,
    this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mainColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 🔹 العنوان مع زر الرجوع
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: showHeader
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CustomBackIcon(onTap: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              } else {
                                context.go('/HomePage');
                              }
                            }),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),

            // 🔍 شريط البحث
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.search_rounded,
                        color: AppColors.mainColor,
                        size: 26,
                      ),
                    ),
                    suffixIcon: searchController != null && searchController!.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                            onPressed: () {
                              searchController!.clear();
                              onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    hintText: searchHint,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
