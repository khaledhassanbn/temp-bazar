import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bazar_suez/support/models/support_conversation.dart';
import 'package:bazar_suez/support/models/support_message.dart';
import 'package:bazar_suez/support/services/support_service.dart';
import 'package:bazar_suez/support/services/support_image_service.dart';
import 'package:bazar_suez/support/widgets/chat_bubble.dart';
import 'package:bazar_suez/support/widgets/chat_input_bar.dart';
import 'package:bazar_suez/support/widgets/conversation_status_badge.dart';
import 'package:bazar_suez/theme/app_color.dart';

class SupportChatPage extends StatefulWidget {
  final String conversationId;

  const SupportChatPage({
    super.key,
    required this.conversationId,
  });

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final SupportService _supportService = SupportService();
  final SupportImageService _imageService = SupportImageService();
  
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _markConversationAsRead();
  }

  void _markConversationAsRead() {
    _supportService.markAsRead(widget.conversationId);
  }

  Future<void> _handleSendMessage(String text, File? image) async {
    setState(() {
      _isSending = true;
    });

    try {
      String? imageUrl;
      if (image != null) {
        imageUrl = await _imageService.uploadImage(image, widget.conversationId);
      }

      await _supportService.sendMessage(
        conversationId: widget.conversationId,
        text: text,
        imageUrl: imageUrl,
      );
      
      // Auto scroll or mark as read again
      _markConversationAsRead();
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل إرسال الرسالة، يرجى المحاولة مرة أخرى'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String? _getRelatedName(SupportConversation conversation) {
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('support_conversations')
            .doc(widget.conversationId)
            .snapshots(),
        builder: (context, conversationSnapshot) {
          if (conversationSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.mainColor),
              ),
            );
          }

          if (!conversationSnapshot.hasData || !conversationSnapshot.data!.exists) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(
                child: Text(
                  'المحادثة غير موجودة أو تم حذفها.',
                  style: TextStyle(fontFamily: 'NotoSansArabic'),
                ),
              ),
            );
          }

          final conversation = SupportConversation.fromFirestore(conversationSnapshot.data!);
          final isClosed = conversation.status == ConversationStatus.closed ||
              conversation.status == ConversationStatus.resolved;

          // Anytime this updates, make sure unread is cleared if user sees new messages
          if (conversation.unreadUserCount > 0) {
            _markConversationAsRead();
          }

          final relatedName = _getRelatedName(conversation);

          return Scaffold(
            backgroundColor: const Color(0xFFF5F6FA),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              iconTheme: const IconThemeData(color: Colors.black87),
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.issueTypeDisplayName,
                          style: const TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (relatedName != null && relatedName.isNotEmpty)
                          Text(
                            relatedName,
                            style: TextStyle(
                              fontFamily: 'NotoSansArabic',
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConversationStatusBadge(
                    status: conversation.status,
                    statusName: conversation.statusDisplayName,
                    color: conversation.statusColor,
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<SupportMessage>>(
                    stream: _supportService.getMessages(widget.conversationId),
                    builder: (context, messagesSnapshot) {
                      if (messagesSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.mainColor),
                        );
                      }

                      final messages = messagesSnapshot.data ?? [];

                      if (messages.isEmpty) {
                        return const Center(
                          child: Text(
                            'لا توجد رسائل بعد.',
                            style: TextStyle(fontFamily: 'NotoSansArabic', color: Colors.grey),
                          ),
                        );
                      }

                      // Reverse messages so index 0 is at bottom (reversed ListView)
                      final reversedMessages = messages.reversed.toList();

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                        reverse: true,
                        itemCount: reversedMessages.length,
                        itemBuilder: (context, index) {
                          return ChatBubble(message: reversedMessages[index]);
                        },
                      );
                    },
                  ),
                ),
                if (isClosed)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 16.0,
                      bottom: MediaQuery.of(context).padding.bottom + 16.0,
                    ),
                    color: Colors.grey.shade100,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, color: Colors.grey.shade600, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          conversation.status == ConversationStatus.resolved
                              ? 'تم حل هذه الشكوى وتصنيفها كمكتملة. المحادثة مغلقة.'
                              : 'لقد تم إغلاق محادثة الدعم هذه من قِبل الإدارة.',
                          style: TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ChatInputBar(
                    onSend: _handleSendMessage,
                    isSending: _isSending,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
