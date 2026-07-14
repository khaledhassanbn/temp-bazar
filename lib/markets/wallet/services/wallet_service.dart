import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/wallet_transaction_model.dart';
import '../models/wallet_ledger_model.dart';

class DepositPhoneResult {
  final String? phone;
  final String? error;

  const DepositPhoneResult({this.phone, this.error});

  bool get isSuccess => phone != null && phone!.isNotEmpty;
}

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const _depositPhoneDocIds = [
    'vodafonecachnumber', // المسار الفعلي في Firebase Console
    'vodafonecachnummber',
    'vodafonecashnumber',
    'vodafone_cash_number',
  ];

  static const _depositSettingsDocIds = [
    'wallet_deposit',
    'wallet',
    'deposit',
    'vodafone_cash',
  ];

  // Get user wallet balance
  Future<double> getWalletBalance(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data != null && data['walletBalance'] != null) {
        return (data['walletBalance'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Get user phone number
  Future<String?> getUserPhoneNumber(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.serverAndCache));
      final data = doc.data();
      if (data == null) return null;

      return _extractPhoneFromData(data);
    } catch (e) {
      debugPrint('getUserPhoneNumber error: $e');
      return null;
    }
  }

  // Get deposit phone number
  Future<DepositPhoneResult> getDepositPhoneNumber() async {
    // قراءة مباشرة من المسار المعروف في قاعدة البيانات
    try {
      final doc = await _firestore
          .collection('wallet')
          .doc('vodafonecachnumber')
          .get();
      if (doc.exists) {
        final raw = doc.data()?['number'];
        final phone = _readPhoneValue(raw);
        if (phone != null) {
          return DepositPhoneResult(phone: phone);
        }
      }
    } catch (e) {
      debugPrint('getDepositPhoneNumber direct read: $e');
    }

    final errors = <String>[];

    // 1) المستندات المعروفة في مجموعة wallet
    for (final docId in _depositPhoneDocIds) {
      try {
        final doc = await _firestore.collection('wallet').doc(docId).get();
        if (!doc.exists) continue;

        final phone = _extractPhoneFromData(doc.data() ?? {});
        if (phone != null) {
          return DepositPhoneResult(phone: phone);
        }
      } catch (e) {
        errors.add('wallet/$docId: $e');
      }
    }

    // 2) بحث احتياطي في كامل مجموعة wallet (يعمل مهما تغيّر اسم المستند)
    try {
      final snapshot = await _firestore.collection('wallet').get();
      for (final doc in snapshot.docs) {
        final phone = _extractPhoneFromData(doc.data());
        if (phone != null) {
          return DepositPhoneResult(phone: phone);
        }
      }
    } catch (e) {
      errors.add('wallet (scan): $e');
    }

    // 3) مستندات الإعدادات كخيار أخير
    for (final docId in _depositSettingsDocIds) {
      try {
        final doc = await _firestore.collection('settings').doc(docId).get();
        if (!doc.exists) continue;

        final phone = _extractPhoneFromData(doc.data() ?? {});
        if (phone != null) {
          return DepositPhoneResult(phone: phone);
        }
      } catch (e) {
        errors.add('settings/$docId: $e');
      }
    }

    return DepositPhoneResult(
      error: errors.isEmpty
          ? 'لم يُعثر على رقم فودافون كاش في قاعدة البيانات'
          : errors.join(' | '),
    );
  }

  static String? _readPhoneValue(dynamic value) {
    if (value == null) return null;
    final phone = value.toString().trim();
    if (phone.isEmpty) return null;
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 10) return digitsOnly;
    return phone;
  }

  static String? _extractPhoneFromData(Map<String, dynamic> data) {
    const preferredKeys = [
      'number',
      'phone',
      'phoneNumber',
      'phone_number',
      'vodafoneNumber',
      'vodafoneCashNumber',
      'depositNumber',
      'value',
    ];

    for (final key in preferredKeys) {
      final phone = _readPhoneValue(data[key]);
      if (phone != null) return phone;
    }

    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();
      if (key.contains('phone') ||
          key.contains('number') ||
          key.contains('vodafone') ||
          key.contains('mobile')) {
        final phone = _readPhoneValue(entry.value);
        if (phone != null) return phone;
      }
    }

    for (final entry in data.entries) {
      if (entry.value is Map) {
        final nested = _extractPhoneFromData(
          Map<String, dynamic>.from(entry.value as Map),
        );
        if (nested != null) return nested;
      }
    }

    return null;
  }

  // Create deposit request
  Future<String> createDepositRequest({
    required String userId,
    required double amount,
    required String phoneNumber,
    String? notes,
    File? imageFile,
  }) async {
    try {
      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        final ref = _storage
            .ref()
            .child('wallet_deposits')
            .child(userId)
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      final transaction = WalletTransaction(
        id: _firestore.collection('wallet_transactions').doc().id,
        userId: userId,
        amount: amount,
        status: 'pending',
        phoneNumber: phoneNumber,
        notes: notes,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('wallet_transactions')
          .doc(transaction.id)
          .set(transaction.toJson());

      return transaction.id;
    } catch (e) {
      throw Exception('فشل إنشاء طلب الإيداع: ${e.toString()}');
    }
  }

  // Get user transactions
  Stream<List<WalletTransaction>> getUserTransactions(String userId) {
    return _firestore
        .collection('wallet_transactions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final transactions = <WalletTransaction>[];
          for (final doc in snapshot.docs) {
            try {
              transactions.add(
                WalletTransaction.fromJson({'id': doc.id, ...doc.data()}),
              );
            } catch (e) {
              debugPrint('wallet_transactions parse error ${doc.id}: $e');
            }
          }
          transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return transactions;
        });
  }

  // Deduct amount from wallet
  Future<bool> deductFromWallet(String userId, double amount) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('المستخدم غير موجود');
      }

      final currentBalance = userDoc.data()?['walletBalance'] ?? 0.0;
      final balance = (currentBalance as num).toDouble();

      if (balance < amount) {
        return false; // Insufficient balance
      }

      final newBalance = balance - amount;
      await _firestore.collection('users').doc(userId).update({
        'walletBalance': newBalance,
      });

      return true;
    } catch (e) {
      throw Exception('فشل خصم المبلغ: ${e.toString()}');
    }
  }

  /// جلب سجل المحفظة الموحد
  Stream<List<WalletLedgerEntry>> getWalletLedger(String userId) {
    return _firestore
        .collection('wallet_ledger')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final entries = <WalletLedgerEntry>[];
          for (final doc in snapshot.docs) {
            try {
              entries.add(
                WalletLedgerEntry.fromJson({...doc.data(), 'id': doc.id}),
              );
            } catch (e) {
              debugPrint('wallet_ledger parse error ${doc.id}: $e');
            }
          }
          entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (entries.length > 50) {
            return entries.sublist(0, 50);
          }
          return entries;
        });
  }
}
