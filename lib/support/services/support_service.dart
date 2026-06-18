import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bazar_suez/support/models/support_conversation.dart';
import 'package:bazar_suez/support/models/support_message.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'support_conversations';
  static const String _messagesSubcollection = 'messages';

  /// جلب محادثات المستخدم الحالي (Stream)
  Stream<List<SupportConversation>> getUserConversations() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => SupportConversation.fromFirestore(doc))
              .toList();
          // ترتيب محلي لتجنب اشتراط الفهارس المركبة
          list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return list;
        });
  }

  /// إنشاء محادثة جديدة
  Future<String> createConversation({
    required IssueType issueType,
    required String initialMessage,
    String? imageUrl,
    String? relatedMerchantId,
    String? relatedMerchantName,
    String? relatedCraftsmanId,
    String? relatedCraftsmanName,
    String? relatedDriverId,
    String? relatedDriverName,
    String? relatedOrderId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

    // تحديد نوع المستخدم من قاعدة البيانات
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final userStatus = userData['status'] ?? 'user';
    
    String userType;
    if (userStatus == 'market_owner') {
      userType = 'merchant';
    } else {
      // تحقق هل هو صنايعي
      final craftsmanDoc = await _firestore.collection('craftsmen').doc(user.uid).get();
      userType = craftsmanDoc.exists ? 'craftsman' : 'customer';
    }

    final conversationRef = _firestore.collection(_collection).doc();
    final conversationId = conversationRef.id;

    final conversationData = {
      'id': conversationId,
      'userId': user.uid,
      'userName': userData['name'] ?? user.displayName ?? 'مستخدم',
      'userType': userType,
      'issueType': issueType.name,
      'relatedMerchantId': relatedMerchantId ?? '',
      'relatedMerchantName': relatedMerchantName ?? '',
      'relatedCraftsmanId': relatedCraftsmanId ?? '',
      'relatedCraftsmanName': relatedCraftsmanName ?? '',
      'relatedDriverId': relatedDriverId ?? '',
      'relatedDriverName': relatedDriverName ?? '',
      'relatedOrderId': relatedOrderId ?? '',
      'status': 'open',
      'lastMessage': initialMessage.isNotEmpty ? initialMessage : '📷 صورة',
      'unreadAdminCount': 1,
      'unreadUserCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // 1. إنشاء المحادثة
    await conversationRef.set(conversationData);

    // 2. إرسال الرسالة الأولى من المستخدم
    await _sendMessage(
      conversationId: conversationId,
      text: initialMessage,
      imageUrl: imageUrl,
      senderType: 'user',
    );

    // 3. إرسال رسالة النظام التلقائية
    await _sendMessage(
      conversationId: conversationId,
      text: 'شكراً لتواصلك مع بازار السويس.\n\nتم استلام رسالتك وسيتم مراجعتها والرد عليك فى أقرب وقت ممكن.',
      senderType: 'system',
      isSystem: true,
    );

    return conversationId;
  }

  /// إرسال رسالة
  Future<void> sendMessage({
    required String conversationId,
    String? text,
    String? imageUrl,
  }) async {
    await _sendMessage(
      conversationId: conversationId,
      text: text,
      imageUrl: imageUrl,
      senderType: 'user',
    );

    // تحديث آخر رسالة + عداد غير المقروءة للـ admin
    await _firestore.collection(_collection).doc(conversationId).update({
      'lastMessage': (text != null && text.isNotEmpty) ? text : '📷 صورة',
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadAdminCount': FieldValue.increment(1),
    });
  }

  Future<void> _sendMessage({
    required String conversationId,
    String? text,
    String? imageUrl,
    required String senderType,
    bool isSystem = false,
  }) async {
    final user = _auth.currentUser;
    final messageRef = _firestore
        .collection(_collection)
        .doc(conversationId)
        .collection(_messagesSubcollection)
        .doc();

    await messageRef.set({
      'id': messageRef.id,
      'senderId': isSystem ? 'system' : (user?.uid ?? ''),
      'senderType': senderType,
      'text': text ?? '',
      'imageUrl': imageUrl ?? '',
      'isSystem': isSystem,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// جلب رسائل محادثة (Stream)
  Stream<List<SupportMessage>> getMessages(String conversationId) {
    return _firestore
        .collection(_collection)
        .doc(conversationId)
        .collection(_messagesSubcollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SupportMessage.fromFirestore(doc))
            .toList());
  }

  /// تصفير عداد غير المقروءة للمهتم/المستخدم الحالي
  Future<void> markAsRead(String conversationId) async {
    await _firestore.collection(_collection).doc(conversationId).update({
      'unreadUserCount': 0,
    });
  }

  /// جلب آخر المتاجر التى تعامل معها المستخدم
  Future<List<Map<String, dynamic>>> getRecentMerchants() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    try {
      final ordersSnap = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final seen = <String>{};
      final merchants = <Map<String, dynamic>>[];

      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        final storeId = data['storeId']?.toString() ?? '';
        final storeName = data['storeName']?.toString() ?? '';
        if (storeId.isNotEmpty && !seen.contains(storeId)) {
          seen.add(storeId);
          // جلب صورة المتجر
          String? storeImage;
          try {
            final marketDoc = await _firestore.collection('markets').doc(storeId).get();
            storeImage = marketDoc.data()?['imageUrl']?.toString();
          } catch (_) {}
          merchants.add({
            'id': storeId,
            'name': storeName,
            'imageUrl': storeImage ?? '',
          });
        }
        if (merchants.length >= 10) break;
      }
      return merchants;
    } catch (e) {
      print('Error fetching recent merchants: $e');
      return [];
    }
  }

  /// جلب آخر المناديب المرتبطين بطلبات المستخدم
  Future<List<Map<String, dynamic>>> getRecentDrivers() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    try {
      final ordersSnap = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      final seen = <String>{};
      final drivers = <Map<String, dynamic>>[];

      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        final deliveryRequest = data['deliveryRequest'] as Map<String, dynamic>?;
        final driverId = (data['assignedCourierId'] ??
                deliveryRequest?['courierId'] ??
                deliveryRequest?['driverId'] ??
                '')
            .toString();
        final driverName = (deliveryRequest?['assignedDriverName'] ??
                deliveryRequest?['driverName'] ??
                data['assignedDriverName'] ??
                '')
            .toString();

        if (driverId.isNotEmpty && driverName.isNotEmpty && !seen.contains(driverId)) {
          seen.add(driverId);
          drivers.add({
            'id': driverId,
            'name': driverName,
          });
        }
        if (drivers.length >= 10) break;
      }
      return drivers;
    } catch (e) {
      print('Error fetching recent drivers: $e');
      return [];
    }
  }

  /// بحث في الصنايعية
  Future<List<Map<String, dynamic>>> searchCraftsmen(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final snap = await _firestore
          .collection('craftsmen')
          .where('visibility', isEqualTo: 'public')
          .limit(50)
          .get();

      return snap.docs
          .where((doc) {
            final data = doc.data();
            final name = (data['name'] ?? '').toString().toLowerCase();
            final profession = (data['professionName'] ?? '').toString().toLowerCase();
            final q = query.toLowerCase();
            return name.contains(q) || profession.contains(q);
          })
          .map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? '',
              'professionName': data['professionName'] ?? '',
              'imageUrl': data['profileImageUrl'] ?? data['imageUrl'] ?? '',
            };
          })
          .toList();
    } catch (e) {
      print('Error searching craftsmen: $e');
      return [];
    }
  }
}
