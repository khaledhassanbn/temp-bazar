import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_color.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final authGuard = context.watch<AuthGuard>();

    if (authGuard.userStatus != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('غير مصرح'),
          backgroundColor: AppColors.mainColor,
        ),
        body: const Center(child: Text('غير مصرح لك بالوصول إلى هذه الصفحة')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin/dashboard');
            }
          },
        ),
        title: const Text(
          'إدارة الفئات',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.mainColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => context.push('/admin/create-category'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Container(
            padding: const EdgeInsets.only(bottom: 8),
            child: const Text(
              'اضغط مطولاً على الفئة واسحبها لإعادة الترتيب',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('Categories')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد فئات',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/admin/create-category'),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة فئة جديدة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ReorderableListView(
            padding: const EdgeInsets.all(16),
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              _reorderCategories(docs, oldIndex, newIndex);
            },
            children: docs.asMap().entries.map((entry) {
              final index = entry.key;
              final doc = entry.value;
              final data = doc.data() as Map<String, dynamic>;
              final categoryId = doc.id;
              final name =
                  data['name_ar'] ??
                  data['name'] ??
                  data['name_en'] ??
                  'بدون اسم';
              final icon = data['icon'] ?? '';

              return Card(
                key: ValueKey(categoryId),
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // أيقونة السحب
                      Icon(
                        Icons.drag_handle,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      // صورة الفئة أو الأيقونة الافتراضية
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: icon.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildCategoryImage(icon),
                              )
                            : Icon(
                                Icons.category,
                                size: 40,
                                color: AppColors.mainColor,
                              ),
                      ),
                      const SizedBox(width: 16),
                      // معلومات الفئة
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mainColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'الترتيب: ${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (icon.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'لا توجد صورة',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // أزرار التعديل والحذف
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => context.push(
                              '/admin/edit-category/$categoryId',
                            ),
                            tooltip: 'تعديل',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _deleteCategory(context, categoryId, name),
                            tooltip: 'حذف',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _reorderCategories(
    List<QueryDocumentSnapshot> docs,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      // إنشاء قائمة جديدة بالترتيب المحدث
      final reorderedDocs = List<QueryDocumentSnapshot>.from(docs);
      final item = reorderedDocs.removeAt(oldIndex);
      reorderedDocs.insert(newIndex, item);

      // تحديث ترتيب كل فئة
      final batch = _firestore.batch();
      for (int i = 0; i < reorderedDocs.length; i++) {
        final doc = reorderedDocs[i];
        batch.update(doc.reference, {'order': i});
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث الترتيب بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الترتيب: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory(
    BuildContext context,
    String categoryId,
    String categoryName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف الفئة "$categoryName"؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // حذف الفئة من Firestore
      await _firestore.collection('Categories').doc(categoryId).delete();

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الفئة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحذف: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        errorBuilder: (context, _, __) =>
            Icon(Icons.category, size: 40, color: AppColors.mainColor),
      );
    } else {
      // اسم صورة محلية - استخدم Image.asset
      final imagePath = icon.startsWith('assets/')
          ? icon
          : 'assets/images/categories/$icon';

      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, _, __) =>
            Icon(Icons.category, size: 40, color: AppColors.mainColor),
      );
    }
  }
}
