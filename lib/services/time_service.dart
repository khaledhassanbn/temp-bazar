import 'dart:convert';
import 'package:http/http.dart' as http;

class TimeService {
  static const String _worldTimeApiUrl =
      'http://worldtimeapi.org/api/timezone/Africa/Cairo';
  static const String _timeApiUrl =
      'http://timeapi.io/api/Time/current/zone?timeZone=Africa/Cairo';

  /// الحصول على الوقت الحالي من سيرفر خارجي
  /// يستخدم WorldTimeAPI كخيار أساسي و TimeAPI كخيار احتياطي
  static Future<DateTime> getCurrentTime() async {
    try {
      // المحاولة الأولى: WorldTimeAPI
      final response = await http
          .get(
            Uri.parse(_worldTimeApiUrl),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final utcDateTime = DateTime.parse(data['utc_datetime']);
        return utcDateTime;
      }
    } catch (e) {
      print('خطأ في WorldTimeAPI: $e');
    }

    try {
      // المحاولة الثانية: TimeAPI
      final response = await http
          .get(Uri.parse(_timeApiUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dateTime = DateTime.parse(data['dateTime']);
        return dateTime;
      }
    } catch (e) {
      print('خطأ في TimeAPI: $e');
    }

    // في حالة فشل جميع المحاولات، نستخدم وقت الجهاز مع تحذير
    print('تحذير: فشل في الحصول على الوقت من السيرفر، سيتم استخدام وقت الجهاز');
    return DateTime.now();
  }

  /// التحقق من صحة الوقت (مقارنة مع وقت الجهاز)
  static Future<bool> isTimeValid() async {
    try {
      final serverTime = await getCurrentTime();
      final deviceTime = DateTime.now();
      final difference = serverTime.difference(deviceTime).abs();

      // إذا كان الفرق أقل من 5 دقائق، نعتبر الوقت صحيح
      return difference.inMinutes < 5;
    } catch (e) {
      print('خطأ في التحقق من صحة الوقت: $e');
      return false;
    }
  }

  /// الحصول على الوقت مع التحقق من الصحة
  static Future<DateTime> getValidatedTime() async {
    final serverTime = await getCurrentTime();
    final isValid = await isTimeValid();

    if (!isValid) {
      print('تحذير: الوقت من السيرفر قد لا يكون دقيقاً');
    }

    return serverTime;
  }
}
