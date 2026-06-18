import 'package:flutter/material.dart';
import 'package:bazar_suez/support/models/support_message.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:bazar_suez/support/widgets/system_message_widget.dart';

class ChatBubble extends StatelessWidget {
  final SupportMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return SystemMessageWidget(text: message.text ?? '');
    }

    final isUser = message.isFromUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 6,
          bottom: 6,
          left: isUser ? 50 : 16,
          right: isUser ? 16 : 50,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              const Padding(
                padding: EdgeInsets.only(right: 6.0, bottom: 4.0, left: 6.0),
                child: Text(
                  'الدعم الفني',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
            Container(
              decoration: BoxDecoration(
                color: isUser ? AppColors.mainColor : const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.hasImage)
                      GestureDetector(
                        onTap: () => _showImagePreview(context, message.imageUrl!),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: CachedNetworkImage(
                            imageUrl: message.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 150,
                              height: 150,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(color: AppColors.mainColor),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 150,
                              height: 150,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    if (message.text != null && message.text!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        child: Text(
                          message.text!,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            color: isUser ? Colors.white : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 6.0, right: 6.0),
              child: Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 10,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
