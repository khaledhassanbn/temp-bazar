import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_color.dart';

class CreatePackagePage extends StatefulWidget {
  const CreatePackagePage({super.key});

  @override
  State<CreatePackagePage> createState() => _CreatePackagePageState();
}

class _CreatePackagePageState extends State<CreatePackagePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _orderIndexController = TextEditingController();

  final List<TextEditingController> _featureControllers = [
    TextEditingController(),
  ];

  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _daysController.dispose();
    _priceController.dispose();
    _orderIndexController.dispose();
    for (var controller in _featureControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addFeatureField() {
    setState(() {
      _featureControllers.add(TextEditingController());
    });
  }

  void _removeFeatureField(int index) {
    if (_featureControllers.length > 1) {
      setState(() {
        _featureControllers[index].dispose();
        _featureControllers.removeAt(index);
      });
    }
  }

  Future<void> _createPackage() async {
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
      final features = _featureControllers
          .map((c) => c.text.trim())
          .where((f) => f.isNotEmpty)
          .toList();

      if (features.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب إضافة مميزة واحدة على الأقل')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final price = double.tryParse(_priceController.text);
      if (price == null || price < 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('يجب إدخال سعر صحيح')));
        setState(() => _isLoading = false);
        return;
      }

      final orderIndex = int.tryParse(_orderIndexController.text) ?? 0;

      // إنشاء الباقة مباشرة في Firestore
      await _firestore.collection('packages').add({
        'name': _nameController.text.trim(),
        'days': int.parse(_daysController.text),
        'price': price,
        'features': features,
        'orderIndex': orderIndex,
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إنشاء الباقة بنجاح')));
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
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'إنشاء باقة جديدة',
          style: TextStyle(color: Colors.white),
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الباقة',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'اسم الباقة مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _daysController,
                decoration: const InputDecoration(
                  labelText: 'عدد الأيام',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'عدد الأيام مطلوب';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'يجب أن يكون عدد الأيام رقماً صحيحاً أكبر من صفر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'السعر (جنيه)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'السعر مطلوب';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price < 0) {
                    return 'يجب أن يكون السعر رقماً صحيحاً أكبر من أو يساوي صفر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _orderIndexController,
                decoration: const InputDecoration(
                  labelText: 'ترتيب الظهور (اختياري)',
                  hintText: '0',
                  border: OutlineInputBorder(),
                  helperText: 'رقم أقل = يظهر أولاً في صفحة الأسعار',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final orderIndex = int.tryParse(value);
                    if (orderIndex == null || orderIndex < 0) {
                      return 'يجب أن يكون ترتيب الظهور رقماً صحيحاً أكبر من أو يساوي صفر';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'المميزات',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addFeatureField,
                    color: AppColors.mainColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(_featureControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.mainColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _featureControllers[index],
                          decoration: InputDecoration(
                            labelText: 'مميزة ${index + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      if (_featureControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeFeatureField(index),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createPackage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'إنشاء الباقة',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
