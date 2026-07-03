import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../../authentication/guards/AuthGuard.dart';
import '../../theme/app_color.dart';
import '../viewmodels/inbox_viewmodel.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initInbox());
  }

  Future<void> _initInbox() async {
    final authGuard = context.read<AuthGuard>();
    final vm = context.read<InboxViewModel>();
    await vm.initialize(
      userStatus: authGuard.userStatus ?? 'user',
      isCraftsman: authGuard.userStatus == 'craftsman',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: Consumer<InboxViewModel>(
            builder: (context, vm, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'الرسائل والإعلانات',
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (vm.unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${vm.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        body: Consumer<InboxViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.mainColor),
              );
            }

            if (vm.errorMessage != null) {
              return Center(
                child: Text(
                  'حدث خطأ أثناء تحميل الرسائل',
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    color: Colors.red.shade700,
                  ),
                ),
              );
            }

            if (vm.messages.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mail_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'لا توجد رسائل حالياً',
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.mainColor,
              onRefresh: _initInbox,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: vm.messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final message = vm.messages[index];
                  return _InboxTile(
                    message: message,
                    onTap: () async {
                      await context.push('/inbox/${message.id}');
                      if (context.mounted) await _initInbox();
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  final dynamic message;
  final VoidCallback onTap;

  const _InboxTile({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy، h:mm a', 'ar').format(message.sentAt);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.mainColor,
                    shape: BoxShape.circle,
                  ),
                ),
              if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: message.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.campaign_rounded, color: AppColors.mainColor),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 15,
                        fontWeight:
                            message.isRead ? FontWeight.w600 : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
