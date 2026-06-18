import 'package:flutter/material.dart';
import 'package:bazar_suez/support/models/support_conversation.dart';
import 'package:bazar_suez/support/services/support_service.dart';

class SupportViewModel extends ChangeNotifier {
  final SupportService _service = SupportService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// إنشاء محادثة دعم جديدة
  Future<String?> createConversation({
    required IssueType issueType,
    required String message,
    String? imageUrl,
    String? relatedMerchantId,
    String? relatedMerchantName,
    String? relatedCraftsmanId,
    String? relatedCraftsmanName,
    String? relatedDriverId,
    String? relatedDriverName,
    String? relatedOrderId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _service.createConversation(
        issueType: issueType,
        initialMessage: message,
        imageUrl: imageUrl,
        relatedMerchantId: relatedMerchantId,
        relatedMerchantName: relatedMerchantName,
        relatedCraftsmanId: relatedCraftsmanId,
        relatedCraftsmanName: relatedCraftsmanName,
        relatedDriverId: relatedDriverId,
        relatedDriverName: relatedDriverName,
        relatedOrderId: relatedOrderId,
      );
      return id;
    } catch (e) {
      print('Error creating support conversation: $e');
      _error = 'حدث خطأ أثناء إنشاء المحادثة. يرجى المحاولة مرة أخرى.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
