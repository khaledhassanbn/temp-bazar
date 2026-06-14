import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bazar_suez/craftsmen/data/craftsman_categories.dart';
import 'package:bazar_suez/craftsmen/services/craftsman_service.dart';
import 'package:bazar_suez/markets/create_market/pages/map_picker_page.dart';
import 'package:bazar_suez/theme/app_color.dart';

class CraftsmanRegisterPage extends StatefulWidget {
  final bool isEdit;

  const CraftsmanRegisterPage({super.key, this.isEdit = false});

  @override
  State<CraftsmanRegisterPage> createState() => _CraftsmanRegisterPageState();
}

class _CraftsmanRegisterPageState extends State<CraftsmanRegisterPage> {
  final _service = CraftsmanService();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _desc = TextEditingController();
  final _area = TextEditingController();

  String? _professionId;
  GeoPoint? _location;
  File? _photoFile;
  File? _coverFile;
  File? _idFile;
  final List<File> _portfolioFiles = [];
  final List<Map<String, dynamic>> _priceList = [];
  bool _saving = false;
  bool _loading = true;
  
  // لحفظ الروابط القديمة للصور
  String? _existingPhotoUrl;
  String? _existingCoverUrl;
  String? _existingIdUrl;
  final List<String> _existingPortfolioUrls = [];

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _loadExistingData();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadExistingData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final craftsman = await _service.getById(uid);
      if (craftsman != null && mounted) {
        setState(() {
          _name.text = craftsman.name;
          _phone.text = craftsman.phone;
          _whatsapp.text = craftsman.whatsapp;
          _desc.text = craftsman.description;
          _area.text = craftsman.areaName;
          _professionId = craftsman.professionId;
          _location = craftsman.location;
          
          // حفظ روابط الصور القديمة
          _existingPhotoUrl = craftsman.photoUrl;
          _existingCoverUrl = craftsman.coverImageUrl;
          _existingIdUrl = craftsman.nationalIdImageUrl;
          _existingPortfolioUrls.clear();
          _existingPortfolioUrls.addAll(craftsman.portfolioUrls);
          
          // تحميل قائمة الأسعار
          _priceList.clear();
          _priceList.addAll(craftsman.priceList.map((e) => e.toMap()).toList());
          
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _desc.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _pickImage(void Function(File) onPicked) async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x != null) onPicked(File(x.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _professionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر المهنة وأكمل البيانات')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      // استخدام الصورة الجديدة أو القديمة
      String? photoUrl = _existingPhotoUrl;
      if (_photoFile != null) {
        photoUrl = await _service.uploadImage(_photoFile!, 'profile');
      }
      
      String? coverUrl = _existingCoverUrl;
      if (_coverFile != null) {
        coverUrl = await _service.uploadImage(_coverFile!, 'cover');
      }
      
      String? idUrl = _existingIdUrl;
      if (_idFile != null) {
        idUrl = await _service.uploadImage(_idFile!, 'id_card');
      }
      
      // رفع الصور الجديدة في المعرض والاحتفاظ بالقديمة
      final portfolioUrls = <String>[..._existingPortfolioUrls];
      for (final f in _portfolioFiles.take(10 - portfolioUrls.length)) {
        portfolioUrls.add(await _service.uploadImage(f, 'portfolio'));
      }

      await _service.createOrUpdateProfile(
        name: _name.text,
        phone: _phone.text,
        whatsapp: _whatsapp.text.isEmpty ? _phone.text : _whatsapp.text,
        professionId: _professionId!,
        description: _desc.text,
        areaName: _area.text,
        location: _location,
        photoUrl: photoUrl,
        coverImageUrl: coverUrl,
        nationalIdImageUrl: idUrl,
        portfolioUrls: portfolioUrls,
        priceList: _priceList,
        isUpdate: widget.isEdit,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الملف بنجاح')),
        );
        context.go('/craftsmen/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FC),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: CustomScrollView(
                  slivers: [
                    // Custom AppBar مع Gradient
                    SliverAppBar(
                      expandedHeight: 140,
                      floating: false,
                      pinned: true,
                      backgroundColor: AppColors.mainColor,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.mainColor.withOpacity(0.9),
                                AppColors.mainColor,
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 20,
                                top: 28,
                                child: Icon(
                                  Icons.handyman,
                                  size: 72,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              Positioned(
                                right: 20,
                                bottom: 40,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.isEdit ? 'تعديل الملف' : 'تسجيل كصنايعي',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'أنشئ ملفك المهني وابدأ في استقبال الطلبات',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_forward, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // صورة البروفايل
                            _buildProfilePhoto(),
                            const SizedBox(height: 20),

                            // بطاقة صورة الغلاف
                            _buildCoverImageCard(),
                            const SizedBox(height: 14),

                            // بطاقة المعلومات الأساسية
                            _buildBasicInfoCard(),
                            const SizedBox(height: 14),

                            // بطاقة بيانات التواصل
                            _buildContactCard(),
                            const SizedBox(height: 14),

                            // بطاقة الموقع الجغرافي
                            _buildLocationCard(),
                            const SizedBox(height: 14),

                            // بطاقة معرض الأعمال
                            _buildPortfolioCard(),
                            const SizedBox(height: 14),

                            // بطاقة قائمة الأسعار
                            _buildPriceListCard(),
                            const SizedBox(height: 14),

                            // زر الحفظ
                            _buildSubmitButton(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // صورة البروفايل
  Widget _buildProfilePhoto() {
    final hasPhoto = _photoFile != null || (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty);
    
    return Center(
      child: Stack(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.mainColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.mainColor.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: hasPhoto
                ? ClipOval(
                    child: _photoFile != null
                        ? Image.file(_photoFile!, fit: BoxFit.cover)
                        : Image.network(_existingPhotoUrl!, fit: BoxFit.cover),
                  )
                : Icon(Icons.person, size: 36, color: AppColors.mainColor),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: GestureDetector(
              onTap: () => _pickImage((f) => setState(() => _photoFile = f)),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.mainColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة صورة الغلاف
  Widget _buildCoverImageCard() {
    final hasCover = _coverFile != null || (_existingCoverUrl != null && _existingCoverUrl!.isNotEmpty);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE4E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.image_outlined, size: 16, color: AppColors.mainColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'صورة الغلاف',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'اختياري · تظهر خلف ملفك الشخصي',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: GestureDetector(
              onTap: () => _pickImage((f) => setState(() => _coverFile = f)),
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasCover
                        ? AppColors.mainColor
                        : const Color(0xFFD1D9E6),
                    width: 1.5,
                  ),
                ),
                child: hasCover
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: _coverFile != null
                                ? Image.file(_coverFile!, fit: BoxFit.cover)
                                : Image.network(_existingCoverUrl!, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _coverFile = null;
                                _existingCoverUrl = null;
                              }),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.red[600],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: GestureDetector(
                              onTap: () => _pickImage((f) => setState(() => _coverFile = f)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit, color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'تغيير',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: AppColors.mainColor, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            'اضغط لإضافة صورة غلاف',
                            style: TextStyle(
                              color: AppColors.mainColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'تُستخدم كخلفية لملفك الشخصي',
                            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة المعلومات الأساسية
  Widget _buildBasicInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE4E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.person, size: 16, color: AppColors.mainColor),
                ),
                const SizedBox(width: 10),
                const Text(
                  'المعلومات الأساسية',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildCustomField(
                  icon: Icons.badge,
                  label: 'الاسم الكامل *',
                  controller: _name,
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 10),
                _buildProfessionDropdown(),
                const SizedBox(height: 10),
                _buildCustomField(
                  icon: Icons.description,
                  label: 'نبذة عن خبراتك',
                  controller: _desc,
                  maxLines: 3,
                  placeholder: 'اكتب وصفاً موجزاً عن مهاراتك...',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة بيانات التواصل
  Widget _buildContactCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE4E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.phone, size: 16, color: AppColors.mainColor),
                ),
                const SizedBox(width: 10),
                const Text(
                  'بيانات التواصل',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildCustomField(
                  icon: Icons.phone_android,
                  label: 'رقم الهاتف *',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                  placeholder: '01xxxxxxxxx',
                ),
                const SizedBox(height: 10),
                _buildCustomField(
                  icon: Icons.chat,
                  label: 'واتساب (اختياري)',
                  controller: _whatsapp,
                  keyboardType: TextInputType.phone,
                  placeholder: 'نفس الهاتف إذا تركت فارغاً',
                ),
                const SizedBox(height: 10),
                _buildCustomField(
                  icon: Icons.location_city,
                  label: 'المنطقة / الحي *',
                  controller: _area,
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة الموقع الجغرافي
  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE4E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.map, size: 16, color: AppColors.mainColor),
                ),
                const SizedBox(width: 10),
                const Text(
                  'الموقع الجغرافي',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: GestureDetector(
              onTap: () async {
                final pt = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MapPickerPage(),
                  ),
                );
                if (pt != null) {
                  setState(() => _location = GeoPoint(pt.latitude, pt.longitude));
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _location != null ? const Color(0xFFECFDF5) : const Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _location != null ? const Color(0xFF059669) : const Color(0xFFE4E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 18,
                      color: _location != null ? const Color(0xFF059669) : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _location != null ? 'تم تحديد موقعك بنجاح' : 'اضغط لتحديد موقعك',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _location != null ? const Color(0xFF065F46) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _location != null ? const Color(0xFF059669) : AppColors.mainColor,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        _location != null ? 'تغيير' : 'تحديد',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة معرض الأعمال
  Widget _buildPortfolioCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE4E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.photo_library, size: 16, color: AppColors.mainColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'معرض الأعمال',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'أضف حتى 10 صور تُبيّن مهاراتك',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Grid للصور (يعرض الصور القديمة والجديدة معاً)
                if (_existingPortfolioUrls.isNotEmpty || _portfolioFiles.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: (_existingPortfolioUrls.length + _portfolioFiles.length) +
                        ((_existingPortfolioUrls.length + _portfolioFiles.length) < 10 ? 1 : 0),
                    itemBuilder: (context, index) {
                      final totalExisting = _existingPortfolioUrls.length;
                      final totalCombined = totalExisting + _portfolioFiles.length;

                      if (index < totalExisting) {
                        // صور قديمة من السيرفر
                        final url = _existingPortfolioUrls[index];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (_, __) => Container(
                                  color: Colors.grey.shade100,
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (_, __, ___) => const Icon(Icons.error),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              left: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _existingPortfolioUrls.removeAt(index)),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.red[600],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else if (index < totalCombined) {
                        // صور جديدة تم اختيارها محلياً
                        final fileIndex = index - totalExisting;
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _portfolioFiles[fileIndex],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              left: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _portfolioFiles.removeAt(fileIndex)),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.red[600],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        // زر إضافة صورة داخل الشبكة
                        return GestureDetector(
                          onTap: () => _pickImage((f) => setState(() => _portfolioFiles.add(f))),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E7FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add, color: Color(0xFF6366F1), size: 22),
                          ),
                        );
                      }
                    },
                  ),
                if (_existingPortfolioUrls.isNotEmpty || _portfolioFiles.isNotEmpty) const SizedBox(height: 8),
                // زر الإضافة بالأسفل
                GestureDetector(
                  onTap: (_existingPortfolioUrls.length + _portfolioFiles.length) >= 10
                      ? null
                      : () => _pickImage((f) => setState(() => _portfolioFiles.add(f))),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.mainColor.withOpacity(0.4),
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, color: AppColors.mainColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'إضافة صورة (${_existingPortfolioUrls.length + _portfolioFiles.length}/10)',
                          style: TextStyle(
                            color: AppColors.mainColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة قائمة الأسعار
  Widget _buildPriceListCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE4E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.attach_money, size: 16, color: AppColors.mainColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'قائمة الأسعار',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'اختياري · يساعد العملاء على معرفة تكاليفك',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // قائمة الأسعار
                ..._priceList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE4E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            '${item['price']} ج.م',
                            style: TextStyle(
                              color: AppColors.mainColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item['serviceName'] ?? '',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _priceList.removeAt(index)),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(Icons.delete_outline, color: Color(0xFF991B1B), size: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                // زر إضافة خدمة
                GestureDetector(
                  onTap: _addPriceItem,
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE4E8F0)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Color(0xFF6B7280), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'إضافة خدمة وسعرها',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // زر الحفظ
  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.mainColor.withOpacity(0.9),
            AppColors.mainColor,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainColor.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _saving ? null : _submit,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: _saving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'إنشاء الملف الشخصي',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // حقل مخصص
  Widget _buildCustomField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    String? placeholder,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E8F0)),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 1),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFC4C9D4),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  validator: validator,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dropdown المهنة المخصص
  Widget _buildProfessionDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.handyman, size: 16, color: Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'المهنة *',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 1),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _professionId,
                    hint: const Text(
                      'اختر المهنة',
                      style: TextStyle(fontSize: 13, color: Color(0xFFC4C9D4)),
                    ),
                    isExpanded: true,
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                    items: [
                      for (final g in kCraftsmanCategoryGroups)
                        for (final p in g.professions)
                          DropdownMenuItem(
                            value: p.id,
                            child: Text(p.nameAr),
                          ),
                    ],
                    onChanged: (v) => setState(() => _professionId = v),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addPriceItem() async {
    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => const _AddPriceDialog(),
    );

    if (result != null && mounted) {
      setState(() => _priceList.add(result));
    }
  }
}

// ─────────────────────────────────────────────
// Dialog مستقل بـ State خاصة به
// ─────────────────────────────────────────────
class _AddPriceDialog extends StatefulWidget {
  const _AddPriceDialog();

  @override
  State<_AddPriceDialog> createState() => _AddPriceDialogState();
}

class _AddPriceDialogState extends State<_AddPriceDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    Navigator.pop(context, {
      'serviceName': _nameCtrl.text.trim(),
      'price': price,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // أيقونة العنوان
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_circle_outline,
                      color: AppColors.mainColor, size: 30),
                ),
                const SizedBox(height: 14),
                const Text(
                  'إضافة خدمة جديدة',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                Text(
                  'أضف اسم الخدمة وسعرها لقائمتك',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // حقل اسم الخدمة
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE4E8F0)),
                  ),
                  child: TextFormField(
                    controller: _nameCtrl,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'اسم الخدمة',
                      labelStyle:
                          TextStyle(color: Colors.grey[600], fontSize: 13),
                      prefixIcon: Icon(Icons.work_outline,
                          color: AppColors.mainColor, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'أدخل اسم الخدمة' : null,
                  ),
                ),
                const SizedBox(height: 12),

                // حقل السعر
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE4E8F0)),
                  ),
                  child: TextFormField(
                    controller: _priceCtrl,
                    textDirection: TextDirection.rtl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'السعر (ج.م)',
                      labelStyle:
                          TextStyle(color: Colors.grey[600], fontSize: 13),
                      prefixIcon: Icon(Icons.payments_outlined,
                          color: AppColors.mainColor, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'أدخل السعر';
                      if (double.tryParse(v.trim()) == null) return 'رقم غير صحيح';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // الأزرار
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, null),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'إضافة',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
