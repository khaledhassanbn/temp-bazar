import 'package:flutter/material.dart';
import 'package:bazar_suez/support/models/support_conversation.dart';
import 'package:bazar_suez/support/widgets/conversation_status_badge.dart';
import 'package:bazar_suez/theme/app_color.dart';

class ConversationCard extends StatelessWidget {
  final SupportConversation conversation;
  final VoidCallback onTap;

  const ConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (conversation.issueType) {
      case IssueType.storeIssue:
        return Icons.store_outlined;
      case IssueType.craftsmanIssue:
        return Icons.construction_outlined;
      case IssueType.driverIssue:
        return Icons.delivery_dining_outlined;
      case IssueType.appIssue:
        return Icons.phone_android_outlined;
      case IssueType.generalInquiry:
        return Icons.help_outline;
    }
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      if (mins == 1) return 'منذ دقيقة';
      if (mins == 2) return 'منذ دقيقتين';
      if (mins >= 3 && mins <= 10) return 'منذ $mins دقائق';
      return 'منذ $mins دقيقة';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      if (hours == 1) return 'منذ ساعة';
      if (hours == 2) return 'منذ ساعتين';
      if (hours >= 3 && hours <= 10) return 'منذ $hours ساعات';
      return 'منذ $hours ساعة';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      if (days == 1) return 'أمس';
      if (days == 2) return 'منذ يومين';
      return 'منذ $days أيام';
    } else {
      return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
    }
  }

  String? _getRelatedName() {
    switch (conversation.issueType) {
      case IssueType.storeIssue:
        return conversation.relatedMerchantName;
      case IssueType.craftsmanIssue:
        return conversation.relatedCraftsmanName;
      case IssueType.driverIssue:
        return conversation.relatedDriverName;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final relatedName = _getRelatedName();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: conversation.unreadUserCount > 0
              ? AppColors.mainColor.withOpacity(0.3)
              : Colors.grey.shade100,
          width: conversation.unreadUserCount > 0 ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIcon(),
                        color: AppColors.mainColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        conversation.issueTypeDisplayName,
                        style: const TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    ConversationStatusBadge(
                      status: conversation.status,
                      statusName: conversation.statusDisplayName,
                      color: conversation.statusColor,
                    ),
                  ],
                ),
                if (relatedName != null && relatedName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    relatedName,
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Divider(height: 1, color: Color(0xFFF1F1F1)),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conversation.lastMessage,
                            style: TextStyle(
                              fontFamily: 'NotoSansArabic',
                              fontSize: 13,
                              color: conversation.unreadUserCount > 0
                                  ? Colors.black
                                  : Colors.grey.shade600,
                              fontWeight: conversation.unreadUserCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getRelativeTime(conversation.updatedAt),
                            style: TextStyle(
                              fontFamily: 'NotoSansArabic',
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (conversation.unreadUserCount > 0)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${conversation.unreadUserCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
