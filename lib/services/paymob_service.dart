import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// خدمة Paymob للتعامل مع بوابة الدفع
class PaymobService {
  // TODO: استبدل هذه القيم بمفاتيح Paymob الخاصة بك
  static const String _apiKey =
      'ZXlKaGJHY2lPaUpJVXpVeE1pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SndjbTltYVd4bFgzQnJJam95TmpBeE9Ua3NJbTVoYldVaU9pSnBibWwwYVdGc0lpd2lZMnhoYzNNaU9pSk5aWEpqYUdGdWRDSjkudW9HeGNTLVRVak9zVzhuMk9kbzNieGFtaHJFeUpWM2thZFo3QVREVFNtRVZyVGtta3M0MmwtMjJrMi1OUVdzUTZpX25FUUZCdDZVM0hIazM4THZEdmc=';
  static const String _iframeId = '609800';
  static const String _integrationId = '2536730'; // Card integration ID

  // لتخزين آخر خطأ
  String? _lastError;

  // URLs
  static const String _baseUrl = 'https://accept.paymob.com/api';
  static const String _authUrl = '$_baseUrl/auth/tokens';
  static const String _orderUrl = '$_baseUrl/ecommerce/orders';
  static const String _paymentKeyUrl = '$_baseUrl/acceptance/payment_keys';

  /// الحصول على آخر خطأ
  Future<String?> getLastError() async {
    return _lastError;
  }

  /// الحصول على token من Paymob
  Future<String?> getAuthToken() async {
    try {
      final response = await http.post(
        Uri.parse(_authUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'api_key': _apiKey}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String?;
        if (token == null) {
          _lastError = 'لم يتم الحصول على token من Paymob';
        }
        return token;
      } else {
        _lastError =
            'خطأ في المصادقة: ${response.statusCode} - ${response.body}';
        debugPrint(
          'Paymob Auth Error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      _lastError = 'خطأ في الاتصال: $e';
      debugPrint('Paymob Auth Exception: $e');
      return null;
    }
  }

  /// إنشاء order في Paymob
  Future<Map<String, dynamic>?> createOrder({
    required String authToken,
    required double amount,
    required List<Map<String, dynamic>> items,
    required String currency,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_orderUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'auth_token': authToken,
          'delivery_needed': 'false',
          'amount_cents': (amount * 100).toInt(), // تحويل إلى قروش
          'currency': currency,
          'items': items,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        _lastError =
            'خطأ في إنشاء الطلب: ${response.statusCode} - ${response.body}';
        debugPrint(
          'Paymob Order Error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      _lastError = 'خطأ في إنشاء الطلب: $e';
      debugPrint('Paymob Order Exception: $e');
      return null;
    }
  }

  /// الحصول على payment key
  Future<String?> getPaymentKey({
    required String authToken,
    required int orderId,
    required double amount,
    required Map<String, String> billingData,
    required String currency,
    String? storeId,
    String? packageId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_paymentKeyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'auth_token': authToken,
          'amount_cents': (amount * 100).toInt(),
          'expiration': 3600, // انتهاء الصلاحية بالثواني (ساعة)
          'order_id': orderId,
          'billing_data': billingData,
          'currency': currency,
          'integration_id': int.parse(_integrationId),
          'lock_order_when_paid': 'false',
          // إضافة metadata للربط مع المتجر والباقة
          'metadata': {
            if (storeId != null) 'storeId': storeId,
            if (packageId != null) 'packageId': packageId,
          },
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token == null) {
          _lastError = 'لم يتم الحصول على payment key من Paymob';
        }
        return token;
      } else {
        _lastError =
            'خطأ في الحصول على payment key: ${response.statusCode} - ${response.body}';
        debugPrint(
          'Paymob Payment Key Error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      _lastError = 'خطأ في الحصول على payment key: $e';
      debugPrint('Paymob Payment Key Exception: $e');
      return null;
    }
  }

  /// الحصول على رابط الدفع
  ///
  /// في Paymob يجب استخدام iframe URL لعرض صفحة الدفع
  /// لا تستخدم API endpoints مباشرة لأنها تتطلب POST
  String getPaymentUrl(String paymentKey) {
    // استخدام iframe_id - هذا هو الطريقة الصحيحة لعرض صفحة الدفع
    return 'https://accept.paymob.com/api/acceptance/iframes/$_iframeId?payment_token=$paymentKey';
  }

  /// العملية الكاملة: الحصول على token -> إنشاء order -> الحصول على payment key
  Future<String?> initiatePayment({
    required double amount,
    required Map<String, String> billingData,
    required String currency,
    String? storeId,
    String? packageId,
  }) async {
    _lastError = null; // إعادة تعيين الخطأ

    // 1. الحصول على auth token
    final authToken = await getAuthToken();
    if (authToken == null) {
      return null;
    }

    // 2. إنشاء order
    final order = await createOrder(
      authToken: authToken,
      amount: amount,
      items: [
        {
          'name': 'اشتراك متجر',
          'amount_cents': (amount * 100).toInt(),
          'description': packageId != null
              ? 'باقة اشتراك: $packageId'
              : 'اشتراك متجر',
          'quantity': 1,
        },
      ],
      currency: currency,
    );

    if (order == null) {
      return null;
    }

    final orderId = order['id'] as int?;
    if (orderId == null) {
      return null;
    }

    // 3. الحصول على payment key
    final paymentKey = await getPaymentKey(
      authToken: authToken,
      orderId: orderId,
      amount: amount,
      billingData: billingData,
      currency: currency,
      storeId: storeId,
      packageId: packageId,
    );

    if (paymentKey == null) {
      return null;
    }

    // 4. إرجاع رابط الدفع
    return getPaymentUrl(paymentKey);
  }
}
