import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/app_color.dart'; // ← تأكد إن ده مسار ملف AppColors
import '../ViewModel/ViewModel.dart';
import '../Model/model.dart';

class CategoriesGridPage extends StatefulWidget {
  const CategoriesGridPage({super.key});

  @override
  State<CategoriesGridPage> createState() => _CategoriesGridPageState();
}

class _CategoriesGridPageState extends State<CategoriesGridPage> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<CategoryViewModel>(
        context,
        listen: false,
      ).fetchCategories(),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CategoryViewModel>(context);

    final filteredCategories = vm.categories
        .where((cat) => cat.name.contains(searchQuery))
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,

        // ----------------------- 🔹 AppBar مع العربة على اليسار والثلاث شرط على اليمين
        appBar: AppBar(
          backgroundColor: AppColors.mainColor,
          elevation: 0,
          toolbarHeight: 55,
          leading: IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () {
              context.go('/CartPage');
            },
          ),
          title: Image.asset('assets/images/logo.png', height: 32),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                context.go('/AccountPage');
              },
            ),
          ],
        ),

        // ----------------------- 🔹 محتوى الصفحة
        body: SafeArea(
          child: Column(
            children: [
              // ----------------------- 🔹 شريط البحث بخلفية بيضاء ناصعة
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: TextField(
                  controller: searchController,
                  textDirection: TextDirection.rtl,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "ابحث عن متجر...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: AppColors.mainColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              // ----------------------- 🔹 شبكة الفئات
              Expanded(
                child: vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.75,
                            ),
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final CategoryModel category =
                              filteredCategories[index];
                          return GestureDetector(
                            onTap: () {
                              context.push(
                                '/FoodHomePage?categoryId=${category.id}',
                              );
                            },
                            child:
                                Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // المربع - يحتوي فقط على الصورة
                                        Expanded(
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.08),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: category.icon.isNotEmpty
                                                  ? _buildCategoryImage(
                                                      category.icon,
                                                    )
                                                  : Container(
                                                      color: Colors.grey[100],
                                                      child: Icon(
                                                        Icons.category,
                                                        size: 50,
                                                        color:
                                                            AppColors.mainColor,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                        // اسم الفئة خارج المربع
                                        const SizedBox(height: 8),
                                        Text(
                                          category.name,
                                          style: const TextStyle(
                                            color: Color(0xFF2C3E50),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    )
                                    .animate()
                                    .scale(
                                      duration: 400.ms,
                                      curve: Curves.easeOut,
                                    )
                                    .fadeIn(duration: 400.ms),
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

  // دالة مساعدة لعرض الصورة - تدعم الصور المحلية وروابط Firebase
  Widget _buildCategoryImage(String icon) {
    // التحقق من نوع الصورة: إذا كانت رابط Firebase (يبدأ بـ http)
    // أو إذا كانت اسم صورة محلية
    if (icon.startsWith('http://') || icon.startsWith('https://')) {
      // رابط Firebase - استخدم Image.network
      return Image.network(
        icon,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, _, __) => Container(
          color: Colors.grey[100],
          child: Icon(Icons.category, size: 50, color: AppColors.mainColor),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[100],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: AppColors.mainColor,
              ),
            ),
          );
        },
      );
    } else {
      // اسم صورة محلية - استخدم Image.asset
      final imagePath = icon.startsWith('assets/')
          ? icon
          : 'assets/images/categories/$icon';

      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, _, __) => Container(
          color: Colors.grey[100],
          child: Icon(Icons.category, size: 50, color: AppColors.mainColor),
        ),
      );
    }
  }
}
