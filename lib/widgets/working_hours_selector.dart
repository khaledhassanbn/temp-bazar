import 'package:bazar_suez/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../markets/create_market/models/working_hours.dart';

class WorkingHoursSelector extends StatefulWidget {
  final WeeklyWorkingHours? initialWorkingHours;
  final Function(WeeklyWorkingHours) onChanged;
  final bool required;

  const WorkingHoursSelector({
    Key? key,
    this.initialWorkingHours,
    required this.onChanged,
    this.required = false,
  }) : super(key: key);

  @override
  State<WorkingHoursSelector> createState() => _WorkingHoursSelectorState();
}

class _WorkingHoursSelectorState extends State<WorkingHoursSelector> {
  late WeeklyWorkingHours _workingHours;

  @override
  void initState() {
    super.initState();
    _workingHours = widget.initialWorkingHours ?? WeeklyWorkingHours.empty();
  }

  void _updateDayHours(String dayOfWeek, WorkingHours newHours) {
    setState(() {
      _workingHours.updateDayHours(dayOfWeek, newHours);
      widget.onChanged(_workingHours);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'مواعيد العمل',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.mainColor,
              ),
            ),
            if (widget.required)
              const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: _workingHours.workingHours.map((dayHours) {
              return _DayWorkingHoursCard(
                dayHours: dayHours,
                onChanged: (newHours) =>
                    _updateDayHours(dayHours.dayOfWeek, newHours),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        if (!_workingHours.isValid)
          Text(
            'يرجى التحقق من صحة مواعيد العمل',
            style: TextStyle(color: Colors.red[600], fontSize: 12),
          ),
      ],
    );
  }
}

class _DayWorkingHoursCard extends StatefulWidget {
  final WorkingHours dayHours;
  final Function(WorkingHours) onChanged;

  const _DayWorkingHoursCard({
    Key? key,
    required this.dayHours,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<_DayWorkingHoursCard> createState() => _DayWorkingHoursCardState();
}

class _DayWorkingHoursCardState extends State<_DayWorkingHoursCard> {
  late bool _isOpen;
  late String _openTime;
  late String _closeTime;
  late bool _hasBreak;
  late String _breakStartTime;
  late String _breakEndTime;

  @override
  void initState() {
    super.initState();
    _isOpen = widget.dayHours.isOpen;
    _openTime = widget.dayHours.openTime ?? '09:00';
    _closeTime = widget.dayHours.closeTime ?? '18:00';
    _hasBreak = widget.dayHours.hasBreak;
    _breakStartTime = widget.dayHours.breakStartTime ?? '12:00';
    _breakEndTime = widget.dayHours.breakEndTime ?? '13:00';
  }

  void _updateHours() {
    final newHours = WorkingHours(
      dayOfWeek: widget.dayHours.dayOfWeek,
      isOpen: _isOpen,
      openTime: _isOpen ? _openTime : null,
      closeTime: _isOpen ? _closeTime : null,
      hasBreak: _isOpen ? _hasBreak : false,
      breakStartTime: _isOpen && _hasBreak ? _breakStartTime : null,
      breakEndTime: _isOpen && _hasBreak ? _breakEndTime : null,
    );
    widget.onChanged(newHours);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.dayHours.dayOfWeek,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: _isOpen,
                onChanged: (value) {
                  setState(() {
                    _isOpen = value;
                  });
                  _updateHours();
                },
                activeColor: AppColors.mainColor,
              ),
            ],
          ),
          if (_isOpen) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'من',
                    value: _openTime,
                    onChanged: (value) {
                      setState(() {
                        _openTime = value;
                      });
                      _updateHours();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TimeField(
                    label: 'إلى',
                    value: _closeTime,
                    onChanged: (value) {
                      setState(() {
                        _closeTime = value;
                      });
                      _updateHours();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _hasBreak,
                  onChanged: (value) {
                    setState(() {
                      _hasBreak = value ?? false;
                    });
                    _updateHours();
                  },
                  activeColor: AppColors.mainColor,
                ),
                const Text('استراحة'),
              ],
            ),
            if (_hasBreak) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'بداية الاستراحة',
                      value: _breakStartTime,
                      onChanged: (value) {
                        setState(() {
                          _breakStartTime = value;
                        });
                        _updateHours();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TimeField(
                      label: 'نهاية الاستراحة',
                      value: _breakEndTime,
                      onChanged: (value) {
                        setState(() {
                          _breakEndTime = value;
                        });
                        _updateHours();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onChanged;

  const _TimeField({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _TimeInputFormatter(),
          ],
          decoration: InputDecoration(
            hintText: 'HH:MM',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.teal),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // إزالة جميع الأحرف غير الرقمية
    text = text.replaceAll(RegExp(r'[^0-9]'), '');

    // تحديد الحد الأقصى للطول
    if (text.length > 4) {
      text = text.substring(0, 4);
    }

    // إضافة النقطتين تلقائياً
    if (text.length >= 3) {
      text = '${text.substring(0, 2)}:${text.substring(2)}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
