import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/delivery_fee/delivery_fee_service.dart';
import '../../services/delivery_fee/delivery_fee_settings.dart';
import '../../theme/app_color.dart';

/// صفحة إعدادات رسوم التوصيل للأدمن
class DeliveryFeeSettingsPage extends StatefulWidget {
  const DeliveryFeeSettingsPage({super.key});

  @override
  State<DeliveryFeeSettingsPage> createState() => _DeliveryFeeSettingsPageState();
}

class _DeliveryFeeSettingsPageState extends State<DeliveryFeeSettingsPage> {
  final DeliveryFeeService _service = DeliveryFeeService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _baseDistanceController;
  late TextEditingController _baseFeeController;
  late TextEditingController _tier1MaxDistanceController;
  late TextEditingController _tier1FeePerKmController;
  late TextEditingController _tier2MaxDistanceController;
  late TextEditingController _tier2FeePerKmController;

  bool _isLoading = true;
  bool _isSaving = false;
  DeliveryFeeSettings? _currentSettings;

  @override
  void initState() {
    super.initState();
    _baseDistanceController = TextEditingController();
    _baseFeeController = TextEditingController();
    _tier1MaxDistanceController = TextEditingController();
    _tier1FeePerKmController = TextEditingController();
    _tier2MaxDistanceController = TextEditingController();
    _tier2FeePerKmController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _baseDistanceController.dispose();
    _baseFeeController.dispose();
    _tier1MaxDistanceController.dispose();
    _tier1FeePerKmController.dispose();
    _tier2MaxDistanceController.dispose();
    _tier2FeePerKmController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _service.getSettings(forceRefresh: true);
      if (!mounted) return;
      setState(() {
        _currentSettings = settings;
        _baseDistanceController.text = settings.baseDistance.toString();
        _baseFeeController.text = settings.baseFee.toString();
        _tier1MaxDistanceController.text = settings.tier1MaxDistance.toString();
        _tier1FeePerKmController.text = settings.tier1FeePerKm.toString();
        _tier2MaxDistanceController.text = settings.tier2MaxDistance.toString();
        _tier2FeePerKmController.text = settings.tier2FeePerKm.toString();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('فشل في تحميل الإعدادات');
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final newSettings = DeliveryFeeSettings(
        baseDistance: double.parse(_baseDistanceController.text),
        baseFee: double.parse(_baseFeeController.text),
        tier1MaxDistance: double.parse(_tier1MaxDistanceController.text),
        tier1FeePerKm: double.parse(_tier1FeePerKmController.text),
        tier2MaxDistance: double.parse(_tier2MaxDistanceController.text),
        tier2FeePerKm: double.parse(_tier2FeePerKmController.text),
      );

      final success = await _service.updateSettings(newSettings);
      if (!mounted) return;

      if (success) {
        setState(() {
          _currentSettings = newSettings;
          _isSaving = false;
        });
        _showSuccess('تم حفظ الإعدادات بنجاح');
      } else {
        setState(() => _isSaving = false);
        _showError('فشل في حفظ الإعدادات');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError('حدث خطأ: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String? _validateNumber(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'أدخل رقم صحيح';
    }
    if (min != null && number < min) {
      return 'يجب أن يكون أكبر من أو يساوي $min';
    }
    if (max != null && number > max) {
      return 'يجب أن يكون أقل من أو يساوي $max';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إعدادات رسوم التوصيل'),
          backgroundColor: AppColors.mainColor,
          foregroundColor: Colors.white,
          actions: [
            if (!_isLoading)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadSettings,
                tooltip: 'تحديث',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // معلومات توضيحية
                      _buildInfoCard(),
                      const SizedBox(height: 24),

                      // المستوى الأساسي
                      _buildSectionTitle('المستوى الأساسي', Icons.location_on),
                      const SizedBox(height: 12),
                      _buildTierCard(
                        description: 'الرسوم الأساسية للمسافات القصيرة',
                        children: [
                          _buildTextField(
                            controller: _baseDistanceController,
                            label: 'المسافة الأساسية (كم)',
                            hint: 'مثال: 2',
                            validator: (v) => _validateNumber(v, min: 0.1, max: 50),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _baseFeeController,
                            label: 'الرسوم الأساسية (جنيه)',
                            hint: 'مثال: 30',
                            validator: (v) => _validateNumber(v, min: 0),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // المستوى الأول
                      _buildSectionTitle('المستوى الأول', Icons.trending_up),
                      const SizedBox(height: 12),
                      _buildTierCard(
                        description: 'رسوم إضافية للمسافات المتوسطة',
                        children: [
                          _buildTextField(
                            controller: _tier1MaxDistanceController,
                            label: 'حد المسافة (كم)',
                            hint: 'مثال: 5',
                            validator: (v) => _validateNumber(v, min: 0),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _tier1FeePerKmController,
                            label: 'رسوم لكل كم إضافي (جنيه)',
                            hint: 'مثال: 1',
                            validator: (v) => _validateNumber(v, min: 0),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // المستوى الثاني
                      _buildSectionTitle('المستوى الثاني', Icons.speed),
                      const SizedBox(height: 12),
                      _buildTierCard(
                        description: 'رسوم إضافية للمسافات البعيدة',
                        children: [
                          _buildTextField(
                            controller: _tier2MaxDistanceController,
                            label: 'حد المسافة الأقصى (كم)',
                            hint: 'مثال: 100',
                            validator: (v) => _validateNumber(v, min: 0),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _tier2FeePerKmController,
                            label: 'رسوم لكل كم إضافي (جنيه)',
                            hint: 'مثال: 3',
                            validator: (v) => _validateNumber(v, min: 0),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // معاينة الحساب
                      if (_currentSettings != null) ...[
                        _buildSectionTitle('معاينة الحساب', Icons.calculate),
                        const SizedBox(height: 12),
                        _buildPreviewCard(),
                        const SizedBox(height: 24),
                      ],

                      // زر الحفظ
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'حفظ الإعدادات',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كيفية حساب رسوم التوصيل',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• المسافة الأساسية: الرسوم الثابتة\n'
                  '• المستوى الأول: رسوم إضافية لكل كم بعد المسافة الأساسية\n'
                  '• المستوى الثاني: رسوم إضافية أعلى للمسافات البعيدة',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.mainColor, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTierCard({
    required String description,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  Widget _buildPreviewCard() {
    // حساب أمثلة للمعاينة
    final examples = [1.0, 2.0, 3.0, 5.0, 10.0, 20.0];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أمثلة على الحساب (بالإعدادات الحالية)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 12),
          ...examples.map((distance) {
            final fee = _service.calculateDeliveryFee(distance, _currentSettings!);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$distance كم',
                    style: TextStyle(color: Colors.green.shade800),
                  ),
                  Text(
                    '${fee.toStringAsFixed(0)} جنيه',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
