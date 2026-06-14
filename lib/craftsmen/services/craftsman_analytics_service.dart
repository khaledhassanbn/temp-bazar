import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bazar_suez/craftsmen/services/craftsman_service.dart';

enum ContactChannel { call, whatsapp }

class CraftsmanAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CraftsmanService _craftsmanService = CraftsmanService();

  Future<void> logContact({
    required String craftsmanId,
    required ContactChannel channel,
    required String phone,
    required String whatsapp,
  }) async {
    final user = _auth.currentUser;
    final statField =
        channel == ContactChannel.call ? 'callClicks' : 'whatsappClicks';

    await _craftsmanService.incrementStat(craftsmanId, statField);

    if (user != null) {
      await _firestore
          .collection('craftsmen')
          .doc(craftsmanId)
          .collection('contact_events')
          .add({
        'customerId': user.uid,
        'channel': channel.name,
        'createdAt': FieldValue.serverTimestamp(),
        'followUpSent': false,
        'responded': null,
        'serviceCompleted': null,
      });
    }

    final number = channel == ContactChannel.call
        ? phone.replaceAll(RegExp(r'\s'), '')
        : whatsapp.replaceAll(RegExp(r'\D'), '');

    if (channel == ContactChannel.call) {
      final uri = Uri.parse('tel:$number');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } else {
      final wa = number.startsWith('0') ? '2$number' : number;
      final uri = Uri.parse('https://wa.me/$wa');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> logShare(String craftsmanId) async {
    await _craftsmanService.incrementStat(craftsmanId, 'shareClicks');
  }

  Future<void> logProfileView(String craftsmanId) async {
    await _craftsmanService.incrementStat(craftsmanId, 'profileViews');
  }

  Future<void> logSearchImpression(String craftsmanId) async {
    await _craftsmanService.incrementStat(craftsmanId, 'searchImpressions');
  }
}
