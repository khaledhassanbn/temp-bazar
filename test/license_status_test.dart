import 'package:bazar_suez/markets/license/models/license_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LicenseStatus', () {
    test('calculates remaining days from licenseEndAt', () {
      final now = DateTime.now();
      final end = now.add(const Duration(days: 2, hours: 3));

      final status = LicenseStatus.fromDoc('store-1', {
        'licenseEndAt': Timestamp.fromDate(end),
        'licenseDurationDays': 30,
        'licenseAutoRenew': true,
      });

      expect(status.remainingDays, greaterThanOrEqualTo(2));
      expect(status.remainingDays, lessThanOrEqualTo(3));
    });
  });
}


