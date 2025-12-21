class WorkingHours {
  final String dayOfWeek; // يوم الأسبوع (السبت، الأحد، إلخ)
  final bool isOpen; // هل المتجر مفتوح في هذا اليوم
  final String? openTime; // وقت الفتح (مثل "09:00")
  final String? closeTime; // وقت الإغلاق (مثل "18:00")
  final String? breakStartTime; // وقت بداية الاستراحة (اختياري)
  final String? breakEndTime; // وقت نهاية الاستراحة (اختياري)
  final bool hasBreak; // هل هناك استراحة في هذا اليوم

  WorkingHours({
    required this.dayOfWeek,
    required this.isOpen,
    this.openTime,
    this.closeTime,
    this.breakStartTime,
    this.breakEndTime,
    this.hasBreak = false,
  });

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    return WorkingHours(
      dayOfWeek: map['dayOfWeek'] ?? '',
      isOpen: map['isOpen'] ?? false,
      openTime: map['openTime'],
      closeTime: map['closeTime'],
      breakStartTime: map['breakStartTime'],
      breakEndTime: map['breakEndTime'],
      hasBreak: map['hasBreak'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayOfWeek': dayOfWeek,
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
      'breakStartTime': breakStartTime,
      'breakEndTime': breakEndTime,
      'hasBreak': hasBreak,
    };
  }

  // إنشاء نسخة معدلة من الكائن
  WorkingHours copyWith({
    String? dayOfWeek,
    bool? isOpen,
    String? openTime,
    String? closeTime,
    String? breakStartTime,
    String? breakEndTime,
    bool? hasBreak,
  }) {
    return WorkingHours(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      breakEndTime: breakEndTime ?? this.breakEndTime,
      hasBreak: hasBreak ?? this.hasBreak,
    );
  }

  // التحقق من صحة البيانات
  bool get isValid {
    if (!isOpen) return true; // إذا كان مغلق، فلا نحتاج للتحقق من الأوقات

    if (openTime == null || closeTime == null) return false;

    // التحقق من أن وقت الإغلاق بعد وقت الفتح
    final open = _parseTime(openTime!);
    final close = _parseTime(closeTime!);

    if (open == null || close == null) return false;

    // إذا كان وقت الإغلاق قبل وقت الفتح، فهذا يعني أنه يعمل لليوم التالي
    if (close.isBefore(open)) {
      // هذا مقبول (مثل من 22:00 إلى 02:00)
      return true;
    }

    // التحقق من الاستراحة إذا كانت موجودة
    if (hasBreak && (breakStartTime == null || breakEndTime == null)) {
      return false;
    }

    if (hasBreak && breakStartTime != null && breakEndTime != null) {
      final breakStart = _parseTime(breakStartTime!);
      final breakEnd = _parseTime(breakEndTime!);

      if (breakStart == null || breakEnd == null) return false;

      // التحقق من أن الاستراحة داخل ساعات العمل
      if (breakStart.isBefore(open) || breakEnd.isAfter(close)) {
        return false;
      }
    }

    return true;
  }

  // تحويل نص الوقت إلى DateTime
  DateTime? _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

      return DateTime(2024, 1, 1, hour, minute);
    } catch (e) {
      return null;
    }
  }

  // الحصول على نص وصف ساعات العمل
  String get displayText {
    if (!isOpen) return 'مغلق';

    String text = 'من $openTime إلى $closeTime';

    if (hasBreak && breakStartTime != null && breakEndTime != null) {
      text += ' (استراحة من $breakStartTime إلى $breakEndTime)';
    }

    return text;
  }
}

// نموذج لإدارة مواعيد العمل الأسبوعية
class WeeklyWorkingHours {
  final List<WorkingHours> workingHours;

  WeeklyWorkingHours({required this.workingHours});

  factory WeeklyWorkingHours.empty() {
    return WeeklyWorkingHours(
      workingHours: [
        WorkingHours(dayOfWeek: 'السبت', isOpen: false),
        WorkingHours(dayOfWeek: 'الأحد', isOpen: false),
        WorkingHours(dayOfWeek: 'الاثنين', isOpen: false),
        WorkingHours(dayOfWeek: 'الثلاثاء', isOpen: false),
        WorkingHours(dayOfWeek: 'الأربعاء', isOpen: false),
        WorkingHours(dayOfWeek: 'الخميس', isOpen: false),
        WorkingHours(dayOfWeek: 'الجمعة', isOpen: false),
      ],
    );
  }

  factory WeeklyWorkingHours.fromMap(Map<String, dynamic> map) {
    final List<dynamic> hoursList = map['workingHours'] ?? [];
    return WeeklyWorkingHours(
      workingHours: hoursList
          .map((hour) => WorkingHours.fromMap(hour))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'workingHours': workingHours.map((hour) => hour.toMap()).toList()};
  }

  // الحصول على ساعات عمل يوم معين
  WorkingHours? getDayHours(String dayOfWeek) {
    try {
      return workingHours.firstWhere((hour) => hour.dayOfWeek == dayOfWeek);
    } catch (e) {
      return null;
    }
  }

  // تحديث ساعات عمل يوم معين
  void updateDayHours(String dayOfWeek, WorkingHours newHours) {
    final index = workingHours.indexWhere(
      (hour) => hour.dayOfWeek == dayOfWeek,
    );
    if (index != -1) {
      workingHours[index] = newHours;
    }
  }

  // التحقق من صحة جميع ساعات العمل
  bool get isValid {
    return workingHours.every((hour) => hour.isValid);
  }

  // الحصول على أيام العمل المفتوحة
  List<WorkingHours> get openDays {
    return workingHours.where((hour) => hour.isOpen).toList();
  }

  // التحقق من أن المتجر مفتوح في وقت معين
  bool isOpenAt(DateTime dateTime) {
    final dayNames = [
      'السبت',
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
    ];
    final dayIndex = dateTime.weekday % 7; // تحويل من 1-7 إلى 0-6
    final dayName = dayNames[dayIndex];

    final dayHours = getDayHours(dayName);
    if (dayHours == null || !dayHours.isOpen) return false;

    final timeString =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    // التحقق من ساعات العمل العادية
    if (dayHours.openTime != null && dayHours.closeTime != null) {
      if (timeString.compareTo(dayHours.openTime!) >= 0 &&
          timeString.compareTo(dayHours.closeTime!) <= 0) {
        // التحقق من الاستراحة إذا كانت موجودة
        if (dayHours.hasBreak &&
            dayHours.breakStartTime != null &&
            dayHours.breakEndTime != null) {
          if (timeString.compareTo(dayHours.breakStartTime!) >= 0 &&
              timeString.compareTo(dayHours.breakEndTime!) <= 0) {
            return false; // في وقت الاستراحة
          }
        }

        return true;
      }
    }

    return false;
  }
}
