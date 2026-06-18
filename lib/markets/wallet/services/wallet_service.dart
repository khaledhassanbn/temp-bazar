import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/wallet_transaction_model.dart';
import '../models/wallet_ledger_model.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data != null && data['phone'] != null) {
        return data['phone'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get deposit phone number
  Future<String?> getDepositPhoneNumber() async {
    try {
      final doc = await _firestore
          .collection('wallet')
          .doc('vodafonecachnummber')
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['number'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
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
          final transactions = snapshot.docs
              .map(
                (doc) =>
                    WalletTransaction.fromJson({'id': doc.id, ...doc.data()}),
              )
              .toList();
          // Sort by createdAt descending
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
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WalletLedgerEntry.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
