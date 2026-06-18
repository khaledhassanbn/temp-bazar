import 'package:flutter/material.dart';
import 'package:bazar_suez/support/models/support_conversation.dart';

class ConversationStatusBadge extends StatelessWidget {
  final ConversationStatus status;
  final String statusName;
  final Color color;

  const ConversationStatusBadge({
    super.key,
    required this.status,
    required this.statusName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        statusName,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
