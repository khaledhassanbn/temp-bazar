import 'package:flutter/material.dart';
import '../../theme/app_color.dart';
import '../models/ad_model.dart';

class AdSlotCard extends StatefulWidget {
  final AdModel ad;
  final List<Map<String, String>> stores;
  final VoidCallback onPickImage;
  final Function(AdModel) onSave;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const AdSlotCard({
    super.key,
    required this.ad,
    required this.stores,
    required this.onPickImage,
    required this.onSave,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  State<AdSlotCard> createState() => _AdSlotCardState();
}

class _AdSlotCardState extends State<AdSlotCard> {
  late TextEditingController _durationController;
  late String? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(
      text: widget.ad.durationHours.toString(),
    );
    _selectedStoreId = widget.ad.targetStoreId;
  }

  @override
  void didUpdateWidget(AdSlotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ad.durationHours != widget.ad.durationHours) {
      _durationController.text = widget.ad.durationHours.toString();
    }
    if (oldWidget.ad.targetStoreId != widget.ad.targetStoreId) {
      _selectedStoreId = widget.ad.targetStoreId;
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  String _formatDuration(double hours) {
    if (hours <= 0) return 'منتهي';

    final h = hours.floor();
    final m = ((hours - h) * 60).floor();

    if (h > 0 && m > 0) {
      return '${h}س ${m}د';
    } else if (h > 0) {
      return '${h}س';
    } else {
      return '${m}د';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final remainingHours = widget.ad.remainingHours;
    final expiryDate = widget.ad.expiryDate;
    final isValid = widget.ad.isValid;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان والحالة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Tooltip(
                      message: 'اضغط مطولاً لسحب الإعلان وإعادة ترتيبه',
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.drag_handle,
                          color: Colors.grey,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'الإعلان ${widget.ad.slotId}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isValid ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isValid ? 'نشط' : 'غير نشط',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        widget.ad.isActive ? Icons.pause : Icons.play_arrow,
                        color: widget.ad.isActive
                            ? Colors.orange
                            : Colors.green,
                      ),
                      onPressed: widget.onToggleStatus,
                      tooltip: widget.ad.isActive ? 'إيقاف' : 'تشغيل',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: widget.onDelete,
                      tooltip: 'حذف',
                    ),
                  ],
                ),
              ],
            ),

            // معلومات الإعلان
            if (widget.ad.isActive && widget.ad.startTime != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.dashboard,
                          size: 20,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'معلومات الإعلان',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الوقت المتبقي',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDuration(remainingHours),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: remainingHours > 1
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'تاريخ الانتهاء',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(expiryDate),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (widget.ad.startTime != null) ...[
                      const SizedBox(height: 8),
                      Divider(color: Colors.blue[200]),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'تاريخ البدء',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            _formatDate(widget.ad.startTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'مدة العرض',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '${widget.ad.durationHours} ساعة',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // معاينة الصورة
            GestureDetector(
              onTap: widget.onPickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child:
                    widget.ad.imageUrl != null && widget.ad.imageUrl!.isNotEmpty
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.ad.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error, size: 50),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اضغط لاختيار صورة',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // مدة العرض
            Text(
              'مدة العرض (بالساعات)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'مثال: 24',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // اختيار المتجر
            Text(
              'المتجر المستهدف',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedStoreId,
              hint: const Text('اختر متجر'),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: widget.stores.map((store) {
                return DropdownMenuItem<String>(
                  value: store['id'],
                  child: Text(store['name']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStoreId = value;
                });
              },
            ),

            const SizedBox(height: 24),

            // زر الحفظ
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final duration = int.tryParse(_durationController.text) ?? 0;

                  final updatedAd = widget.ad.copyWith(
                    durationHours: duration,
                    targetStoreId: _selectedStoreId,
                  );

                  widget.onSave(updatedAd);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'حفظ الإعلان',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
