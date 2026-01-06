import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_color.dart';

class CreateEditCategoryPage extends StatefulWidget {
  final String? categoryId;

  const CreateEditCategoryPage({super.key, this.categoryId});

  @override
  State<CreateEditCategoryPage> createState() => _CreateEditCategoryPageState();
}

class _CreateEditCategoryPageState extends State<CreateEditCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedImageName;
  String? _existingImageName;
  bool _isLoading = false;
  bool _isEditMode = false;
  List<String> _availableImages = [];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.categoryId != null;
    _loadAvailableImages();
    if (_isEditMode) {
      _loadCategoryData();
    }
  }

  Future<void> _loadAvailableImages() async {
    // قائمة ثابتة بأسماء الصور المتاحة
    // يرجى إضافة أسماء الصور هنا عند إضافتها في فولدر assets/images/categories
    // وتحديدها أيضاً في ملف pubspec.yaml
const List<String> staticImages = [
  'accessories.png',
  'animal.png',
  'cars.png',
  'cosmatics.png',
  'clothes.png',
  'electric.png',
  'food.png',
  'furniture.png',
  'laptop.png',
  'nuts.png',
  'perfumes.png',
  'pharmacy.png',
  'phones.png',
  'sebaka.png',
  'school.png',
  'supermarket.png',
];


    setState(() {
      _availableImages = staticImages;
    });
  }

  Future<void> _loadCategoryData() async {
    try {
      final doc = await _firestore
          .collection('Categories')
          .doc(widget.categoryId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text =
            data['name_ar'] ?? data['name'] ?? data['name_en'] ?? '';

        // قراءة اسم الصورة من الحقل icon
        final iconData = data['icon'] ?? '';
        if (iconData != null && iconData.isNotEmpty) {
          // إذا كان رابط Firebase، نحاول استخراج اسم الصورة
          // أو إذا كان اسم الصورة مباشرة
          if (iconData.startsWith('http')) {
            // رابط Firebase - سنتركه فارغاً لأنه قديم
            _existingImageName = null;
          } else {
            // اسم الصورة مباشرة
            _existingImageName = iconData;
            _selectedImageName = iconData;
          }
        }
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e')));
      }
    }
  }

  Future<void> _showImagePicker() async {
    if (_availableImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا توجد صور متاحة. يرجى إضافة صور في فولدر assets/images/categories',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'اختر صورة للفئة',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 300,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: _availableImages.length,
                  itemBuilder: (context, index) {
                    final imageName = _availableImages[index];
                    final isSelected = _selectedImageName == imageName;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImageName = imageName;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? AppColors.mainColor
                                : Colors.grey[300]!,
                            width: isSelected ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.asset(
                            'assets/images/categories/$imageName',
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) => Container(
                              color: Colors.grey[200],
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text(
                                    'غير موجود',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedImageName != null)
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('تأكيد الاختيار'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final authGuard = context.read<AuthGuard>();
    if (authGuard.userStatus != 'admin') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('غير مصرح لك بالوصول')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();

      if (name.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('اسم الفئة مطلوب')));
        setState(() => _isLoading = false);
        return;
      }

      // إعداد البيانات
      final Map<String, dynamic> categoryData = {
        'name_ar': name,
        'name': name, // للتوافق مع البيانات القديمة
      };

      // إضافة اسم الصورة إذا تم اختيارها
      final imageNameToSave = _selectedImageName ?? _existingImageName;
      if (imageNameToSave != null && imageNameToSave.isNotEmpty) {
        categoryData['icon'] = imageNameToSave;
      }

      // إذا كانت فئة جديدة، نضيف ترتيب في النهاية
      if (!_isEditMode) {
        // جلب آخر ترتيب
        final lastDoc = await _firestore
            .collection('Categories')
            .orderBy('order', descending: true)
            .limit(1)
            .get();
        final lastOrder = lastDoc.docs.isNotEmpty
            ? (lastDoc.docs.first.data()['order'] ?? 0) + 1
            : 0;
        categoryData['order'] = lastOrder;
      }

      // حفظ البيانات
      if (_isEditMode) {
        // تحديث الفئة الموجودة
        await _firestore
            .collection('Categories')
            .doc(widget.categoryId)
            .update(categoryData);
      } else {
        // إنشاء فئة جديدة
        await _firestore.collection('Categories').add(categoryData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'تم التعديل بنجاح' : 'تم الإضافة بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _getSelectedImagePath() {
    final imageName = _selectedImageName ?? _existingImageName;
    if (imageName != null && imageName.isNotEmpty) {
      return 'assets/images/categories/$imageName';
    }
    return null;
  }

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

    final selectedImagePath = _getSelectedImagePath();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin/manage-categories');
            }
          },
        ),
        title: Text(
          _isEditMode ? 'تعديل الفئة' : 'إضافة فئة جديدة',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.mainColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // عرض/اختيار الصورة
              Center(
                child: GestureDetector(
                  onTap: _showImagePicker,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.mainColor, width: 2),
                    ),
                    child: selectedImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              selectedImagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, _, __) =>
                                  _buildPlaceholder(),
                            ),
                          )
                        : _buildPlaceholder(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _showImagePicker,
                  icon: const Icon(Icons.image),
                  label: Text(
                    selectedImagePath != null ? 'تغيير الصورة' : 'اختر صورة',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.mainColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // اسم الفئة
              TextFormField(
                controller: _nameController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'اسم الفئة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'اسم الفئة مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // زر الحفظ
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isEditMode ? 'حفظ التعديلات' : 'إضافة الفئة',
                        style: const TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 60, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'اضغط لاختيار صورة',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }
}
