import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_color.dart';
import '../models/inbox_message_model.dart';
import '../services/inbox_service.dart';
import '../viewmodels/inbox_viewmodel.dart';

class MessageDetailPage extends StatefulWidget {
  final String announcementId;

  const MessageDetailPage({super.key, required this.announcementId});

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  InboxMessageModel? _message;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final message = await InboxService.instance.getMessage(widget.announcementId);
    if (!mounted) return;

    setState(() {
      _message = message;
      _loading = false;
    });

    if (message != null) {
      await context.read<InboxViewModel>().markAsRead(message.id);
    }
  }

  Future<void> _handleCta(AnnouncementCTA cta) async {
    switch (cta.type) {
      case 'open_store':
        context.push('/HomeMarketPage?marketLink=${cta.value}');
        break;
      case 'open_product':
        context.push('/productdetails?marketId=${cta.value}');
        break;
      case 'open_page':
        if (cta.value.startsWith('/')) context.push(cta.value);
        break;
      case 'external_link':
        final uri = Uri.tryParse(cta.value);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.mainColor,
          foregroundColor: Colors.white,
          title: const Text(
            'تفاصيل الرسالة',
            style: TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.bold),
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.mainColor),
              )
            : _message == null
                ? const Center(
                    child: Text(
                      'لم يتم العثور على الرسالة',
                      style: TextStyle(fontFamily: 'NotoSansArabic'),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_message!.imageUrl != null &&
                            _message!.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: _message!.imageUrl!,
                              fit: BoxFit.cover,
                              height: 180,
                              width: double.infinity,
                            ),
                          ),
                        if (_message!.imageUrl != null &&
                            _message!.imageUrl!.isNotEmpty)
                          const SizedBox(height: 16),
                        Text(
                          _message!.title,
                          style: const TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('d MMMM yyyy، h:mm a', 'ar')
                              .format(_message!.sentAt),
                          style: TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _message!.body,
                          style: const TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 16,
                            height: 1.7,
                            color: Color(0xFF34495E),
                          ),
                        ),
                        if (_message!.cta != null &&
                            _message!.cta!.label.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => _handleCta(_message!.cta!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mainColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _message!.cta!.label,
                              style: const TextStyle(
                                fontFamily: 'NotoSansArabic',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}
