import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bazar_suez/support/models/support_conversation.dart';
import 'package:bazar_suez/support/services/support_service.dart';
import 'package:bazar_suez/support/services/support_image_service.dart';
import 'package:bazar_suez/support/viewmodels/support_viewmodel.dart';
import 'package:bazar_suez/support/widgets/issue_type_selector.dart';
import 'package:bazar_suez/support/widgets/merchant_picker.dart';
import 'package:bazar_suez/support/widgets/craftsman_picker.dart';
import 'package:bazar_suez/support/widgets/driver_picker.dart';
import 'package:bazar_suez/widgets/app_field.dart';
import 'package:bazar_suez/widgets/primary_button.dart';
import 'package:bazar_suez/theme/app_color.dart';

class CreateSupportRequestPage extends StatefulWidget {
  final String? preselectedIssueType;
  final String? preselectedRelatedId;
  final String? preselectedRelatedName;

  const CreateSupportRequestPage({
    super.key,
    this.preselectedIssueType,
    this.preselectedRelatedId,
    this.preselectedRelatedName,
  });

  @override
  State<CreateSupportRequestPage> createState() => _CreateSupportRequestPageState();
}

class _CreateSupportRequestPageState extends State<CreateSupportRequestPage> {
  final SupportService _supportService = SupportService();
  final SupportImageService _imageService = SupportImageService();
  final TextEditingController _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  IssueType? _selectedIssueType;
  
  // Related entities data
  String? _relatedId;
  String? _relatedName;

  // Pickers state data
  List<Map<String, dynamic>> _recentMerchants = [];
  List<Map<String, dynamic>> _recentDrivers = [];
  bool _isLoadingData = false;

  // Attached Image state
  File? _selectedImage;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _initializePreselection();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _initializePreselection() {
    if (widget.preselectedIssueType != null) {
      final typeStr = widget.preselectedIssueType!;
      _selectedIssueType = IssueType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => IssueType.generalInquiry,
      );
      _relatedId = widget.preselectedRelatedId;
      _relatedName = widget.preselectedRelatedName;
    }
    
    // If we have an issue type, pre-fetch data if needed
    if (_selectedIssueType != null) {
      _fetchPickerData();
    }
  }

  Future<void> _fetchPickerData() async {
    if (_selectedIssueType == IssueType.storeIssue && widget.preselectedRelatedId == null) {
      setState(() => _isLoadingData = true);
      final list = await _supportService.getRecentMerchants();
      setState(() {
        _recentMerchants = list;
        _isLoadingData = false;
      });
    } else if (_selectedIssueType == IssueType.driverIssue && widget.preselectedRelatedId == null) {
      setState(() => _isLoadingData = true);
      final list = await _supportService.getRecentDrivers();
      setState(() {
        _recentDrivers = list;
        _isLoadingData = false;
      });
    }
  }

  void _onIssueTypeSelected(IssueType type) {
    setState(() {
      _selectedIssueType = type;
      _relatedId = null;
      _relatedName = null;
    });
    _fetchPickerData();
  }

  Future<void> _pickImage(bool fromCamera) async {
    Navigator.of(context).pop(); // Close sheet
    final file = fromCamera
        ? await _imageService.takePhoto()
        : await _imageService.pickImage();
    if (file != null) {
      setState(() {
        _selectedImage = file;
      });
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'إرفاق صورة للمشكلة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _PickerOption(
                        icon: Icons.camera_alt_outlined,
                        label: 'كاميرا',
                        onTap: () => _pickImage(true),
                      ),
                      _PickerOption(
                        icon: Icons.photo_library_outlined,
                        label: 'المعرض',
                        onTap: () => _pickImage(false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitRequest() async {
    if (_selectedIssueType == null) return;
    
    // Validate custom pickers
    if (_selectedIssueType == IssueType.storeIssue && _relatedId == null && _recentMerchants.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار المتجر المعني')),
      );
      return;
    }
    
    if (_selectedIssueType == IssueType.craftsmanIssue && _relatedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الصنايعي المعني')),
      );
      return;
    }

    if (_selectedIssueType == IssueType.driverIssue && _relatedId == null && _recentDrivers.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار المندوب المعني')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final vm = Provider.of<SupportViewModel>(context, listen: false);
    
    setState(() {
      _isUploadingImage = true;
    });

    String? imageUrl;
    try {
      if (_selectedImage != null) {
        // Generate a temporary ID for image bucket path
        final tempId = FirebaseFirestore.instance.collection('support_conversations').doc().id;
        imageUrl = await _imageService.uploadImage(_selectedImage!, tempId);
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل رفع الصورة، يرجى المحاولة مرة أخرى')),
      );
      return;
    }

    setState(() {
      _isUploadingImage = false;
    });

    final conversationId = await vm.createConversation(
      issueType: _selectedIssueType!,
      message: _descController.text.trim(),
      imageUrl: imageUrl,
      relatedMerchantId: _selectedIssueType == IssueType.storeIssue ? _relatedId : null,
      relatedMerchantName: _selectedIssueType == IssueType.storeIssue ? _relatedName : null,
      relatedCraftsmanId: _selectedIssueType == IssueType.craftsmanIssue ? _relatedId : null,
      relatedCraftsmanName: _selectedIssueType == IssueType.craftsmanIssue ? _relatedName : null,
      relatedDriverId: _selectedIssueType == IssueType.driverIssue ? _relatedId : null,
      relatedDriverName: _selectedIssueType == IssueType.driverIssue ? _relatedName : null,
    );

    if (conversationId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء طلب الدعم بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate to chat detail page and remove create page from back stack
      context.replace('/support/chat/$conversationId');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.error ?? 'حدث خطأ أثناء إرسال الطلب'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<SupportViewModel>(context);
    final isPageLoading = vm.isLoading || _isUploadingImage;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'إنشاء طلب دعم',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: isPageLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.mainColor),
                    SizedBox(height: 16),
                    Text(
                      'جاري إرسال طلبك وصورتك...',
                      style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey),
                    )
                  ],
                ),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (widget.preselectedIssueType == null && _selectedIssueType == null) ...[
                      const Text(
                        'ما نوع المشكلة التي تواجهها؟',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      IssueTypeSelector(
                        selectedType: _selectedIssueType,
                        onSelected: _onIssueTypeSelected,
                      ),
                    ] else ...[
                      // If type is selected or preselected, show detail form
                      _buildDetailForm(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDetailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card displaying the selected type with a reset option if not preselected
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _selectedIssueType == IssueType.storeIssue
                        ? Icons.store_outlined
                        : _selectedIssueType == IssueType.craftsmanIssue
                            ? Icons.construction_outlined
                            : _selectedIssueType == IssueType.driverIssue
                                ? Icons.delivery_dining_outlined
                                : _selectedIssueType == IssueType.appIssue
                                    ? Icons.phone_android_outlined
                                    : Icons.help_outline,
                    color: AppColors.mainColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نوع الطلب المختار',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _selectedIssueType == IssueType.storeIssue
                            ? 'مشكلة خاصة بمتجر'
                            : _selectedIssueType == IssueType.craftsmanIssue
                                ? 'مشكلة خاصة بصنايعي'
                                : _selectedIssueType == IssueType.driverIssue
                                    ? 'مشكلة خاصة بمندوب'
                                    : _selectedIssueType == IssueType.appIssue
                                        ? 'مشكلة بالتطبيق'
                                        : 'استفسار عام',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.preselectedIssueType == null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedIssueType = null;
                        _relatedId = null;
                        _relatedName = null;
                      });
                    },
                    child: const Text(
                      'تغيير',
                      style: TextStyle(fontFamily: 'Tajawal', color: AppColors.mainColor),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Pickers based on type
        if (_isLoadingData)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppColors.mainColor),
            ),
          )
        else ...[
          if (_selectedIssueType == IssueType.storeIssue && widget.preselectedRelatedId == null) ...[
            MerchantPicker(
              merchants: _recentMerchants,
              selectedMerchantId: _relatedId,
              onSelected: (id, name) {
                setState(() {
                  _relatedId = id;
                  _relatedName = name;
                });
              },
            ),
            const SizedBox(height: 20),
          ] else if (_selectedIssueType == IssueType.storeIssue && widget.preselectedRelatedId != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.store, color: AppColors.mainColor),
                  const SizedBox(width: 10),
                  Text(
                    'بلاغ خاص بمتجر: ${_relatedName ?? ""}',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (_selectedIssueType == IssueType.craftsmanIssue) ...[
            CraftsmanPicker(
              selectedCraftsmanId: _relatedId,
              onSelected: (id, name) {
                setState(() {
                  _relatedId = id;
                  _relatedName = name;
                });
              },
            ),
            const SizedBox(height: 20),
          ],

          if (_selectedIssueType == IssueType.driverIssue && widget.preselectedRelatedId == null) ...[
            DriverPicker(
              drivers: _recentDrivers,
              selectedDriverId: _relatedId,
              onSelected: (id, name) {
                setState(() {
                  _relatedId = id;
                  _relatedName = name;
                });
              },
            ),
            const SizedBox(height: 20),
          ] else if (_selectedIssueType == IssueType.driverIssue && widget.preselectedRelatedId != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delivery_dining, color: AppColors.mainColor),
                  const SizedBox(width: 10),
                  Text(
                    'بلاغ خاص بمندوب: ${_relatedName ?? ""}',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],

        // Issue Description
        AppTextField(
          label: 'وصف المشكلة بالتفصيل',
          hint: 'اكتب هنا تفاصيل المشكلة التي تواجهها لمساعدتنا في حلها بشكل أسرع...',
          controller: _descController,
          maxLines: 5,
          required: true,
        ),
        const SizedBox(height: 20),

        // Image Attachment
        const Text(
          'إرفاق صورة (اختياري)',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _showImagePickerSheet,
          child: Container(
            width: double.infinity,
            height: _selectedImage == null ? 100 : 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedImage == null ? Colors.grey.shade300 : AppColors.mainColor,
                style: _selectedImage == null ? BorderStyle.solid : BorderStyle.solid,
                width: _selectedImage == null ? 1 : 2,
              ),
            ),
            child: _selectedImage == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 36),
                      SizedBox(height: 8),
                      Text(
                        'اضغط هنا لإرفاق لقطة شاشة أو صورة توضيحية',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 32),

        PrimaryButton(
          text: 'إرسال طلب الدعم',
          onPressed: _submitRequest,
        ),
      ],
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.mainColor.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.mainColor.withOpacity(0.15)),
            ),
            child: Icon(icon, color: AppColors.mainColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
