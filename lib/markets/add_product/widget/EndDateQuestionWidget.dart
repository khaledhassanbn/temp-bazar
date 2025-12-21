import 'package:bazar_suez/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/add_product_viewmodel.dart';

/// 🔹 ويدجت منفصل لتاريخ الإزالة
class EndDateQuestionWidget extends StatefulWidget {
  const EndDateQuestionWidget({Key? key}) : super(key: key);

  @override
  State<EndDateQuestionWidget> createState() => _EndDateQuestionWidgetState();
}

class _EndDateQuestionWidgetState extends State<EndDateQuestionWidget> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return Consumer<AddProductViewModel>(
      builder: (context, vm, _) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "تفعيل",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    activeColor: AppColors.mainColor,
                    value: vm.hasEndDate,
                    onChanged: (val) {
                      vm.setHasEndDate(val);
                      if (val) {
                        // تعيين التاريخ والوقت الافتراضي إذا لم يكن محدداً
                        if (_selectedDate == null) {
                          _selectedDate = DateTime.now().add(
                            const Duration(days: 1),
                          );
                        }
                        if (_selectedTime == null) {
                          _selectedTime = const TimeOfDay(hour: 23, minute: 59);
                        }
                        _updateEndAt();
                      }
                    },
                  ),
                ],
              ),
              if (vm.hasEndDate) ...[
                const SizedBox(height: 16),

                // عرض التاريخ والوقت المحددين
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.mainColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: AppColors.mainColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "تاريخ الإزالة: ${_formatDate(_selectedDate)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.mainColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: AppColors.mainColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "وقت الإزالة: ${_formatTime(_selectedTime)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.mainColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // أزرار اختيار التاريخ والوقت
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today),
                        label: const Text("اختر التاريخ"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectTime,
                        icon: const Icon(Icons.access_time),
                        label: const Text("اختر الوقت"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // معلومات إضافية
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "سيتم إزالة المنتج تلقائياً في التاريخ والوقت المحددين",
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "غير محدد";
    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "غير محدد";
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _updateEndAt();
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 23, minute: 59),
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      _updateEndAt();
    }
  }

  void _updateEndAt() {
    if (_selectedDate != null && _selectedTime != null) {
      final DateTime combinedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final vm = context.read<AddProductViewModel>();
      vm.setEndAt(combinedDateTime);
    }
  }
}
