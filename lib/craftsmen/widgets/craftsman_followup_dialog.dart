import 'package:flutter/material.dart';

import 'package:bazar_suez/craftsmen/services/craftsman_review_service.dart';

/// استبيان: هل رد الصنايعي؟ هل تمت الخدمة؟
class CraftsmanFollowUpDialog extends StatefulWidget {
  final String craftsmanId;
  final String contactEventId;

  const CraftsmanFollowUpDialog({
    super.key,
    required this.craftsmanId,
    required this.contactEventId,
  });

  static Future<void> showIfNeeded(
    BuildContext context, {
    required String craftsmanId,
    required String contactEventId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => CraftsmanFollowUpDialog(
        craftsmanId: craftsmanId,
        contactEventId: contactEventId,
      ),
    );
  }

  @override
  State<CraftsmanFollowUpDialog> createState() => _CraftsmanFollowUpDialogState();
}

class _CraftsmanFollowUpDialogState extends State<CraftsmanFollowUpDialog> {
  bool? _responded;
  bool? _completed;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('كيف كانت تجربتك؟'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('هل قام الصنايعي بالرد عليك؟'),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _responded = true),
                child: const Text('نعم'),
              ),
              TextButton(
                onPressed: () => setState(() => _responded = false),
                child: const Text('لا'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('هل تمت الخدمة؟'),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _completed = true),
                child: const Text('نعم'),
              ),
              TextButton(
                onPressed: () => setState(() => _completed = false),
                child: const Text('لا'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('لاحقاً'),
        ),
        TextButton(
          onPressed: _saving || _responded == null
              ? null
              : () async {
                  setState(() => _saving = true);
                  await CraftsmanReviewService().submitFollowUp(
                    contactEventId: widget.contactEventId,
                    craftsmanId: widget.craftsmanId,
                    responded: _responded!,
                    serviceCompleted: _completed ?? false,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
          child: const Text('إرسال'),
        ),
      ],
    );
  }
}
