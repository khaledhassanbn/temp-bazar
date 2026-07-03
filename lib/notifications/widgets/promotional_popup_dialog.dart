import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/promotional_popup_model.dart';

class PromotionalPopupDialog extends StatelessWidget {
  final PromotionalPopupModel popup;
  final VoidCallback? onCta;

  const PromotionalPopupDialog({
    super.key,
    required this.popup,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: CachedNetworkImage(
                  imageUrl: popup.imageUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
              if (popup.isDismissible)
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                    ),
                  ),
                ),
            ],
          ),
          if (popup.title != null && popup.title!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                popup.title!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (popup.description != null && popup.description!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                popup.description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
          ],
          if (popup.cta != null && popup.cta!.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onCta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4E99B4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'عرض التفاصيل',
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}
