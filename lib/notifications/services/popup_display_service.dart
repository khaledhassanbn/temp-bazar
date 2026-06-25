import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/promotional_popup_model.dart';
import '../widgets/promotional_popup_dialog.dart';

/// عرض الإعلانات المنبثقة عند فتح التطبيق
class PopupDisplayService {
  PopupDisplayService._();
  static final PopupDisplayService instance = PopupDisplayService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _impressionsKey = 'popup_impressions';

  bool _shownThisSession = false;

  Future<Map<String, int>> _getImpressions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_impressionsKey) ?? [];
    final map = <String, int>{};
    for (final entry in raw) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        map[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }
    return map;
  }

  Future<void> _saveImpressions(Map<String, int> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _impressionsKey,
      map.entries.map((e) => '${e.key}:${e.value}').toList(),
    );
  }

  Future<void> tryShowPopup(
    BuildContext context, {
    required String audience,
  }) async {
    if (_shownThisSession) return;
    if (!context.mounted) return;

    final now = DateTime.now();
    final snap = await _firestore
        .collection('promotional_popups')
        .where('isActive', isEqualTo: true)
        .get();

    final impressions = await _getImpressions();
    final candidates = <PromotionalPopupModel>[];

    for (final doc in snap.docs) {
      final popup = PromotionalPopupModel.fromFirestore(doc);
      if (popup.imageUrl.isEmpty) continue;
      if (popup.startDate.isAfter(now) || popup.endDate.isBefore(now)) continue;
      if (popup.targetAudience != 'all' && popup.targetAudience != audience) {
        continue;
      }
      final count = impressions[popup.id] ?? 0;
      if (popup.maxImpressions > 0 && count >= popup.maxImpressions) continue;
      candidates.add(popup);
    }

    if (candidates.isEmpty || !context.mounted) return;

    candidates.sort((a, b) => b.priority.compareTo(a.priority));
    final popup = candidates.first;

    _shownThisSession = true;
    impressions[popup.id] = (impressions[popup.id] ?? 0) + 1;
    await _saveImpressions(impressions);

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: popup.isDismissible,
      builder: (_) => PromotionalPopupDialog(
        popup: popup,
        onCta: () => _handleCta(context, popup),
      ),
    );
  }

  Future<void> _handleCta(BuildContext context, PromotionalPopupModel popup) async {
    Navigator.of(context).pop();
    final cta = popup.cta;
    if (cta == null || cta.value.isEmpty) return;

    switch (cta.type) {
      case 'open_store':
        context.push('/HomeMarketPage?marketLink=${cta.value}');
        break;
      case 'open_product':
        context.push('/productdetails?marketId=${cta.value}');
        break;
      case 'open_craftsman':
        context.push('/craftsman/${cta.value}');
        break;
      case 'open_page':
        if (cta.value.startsWith('/')) {
          context.push(cta.value);
        }
        break;
      case 'external_link':
        final uri = Uri.tryParse(cta.value);
        if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
        break;
    }
  }
}
