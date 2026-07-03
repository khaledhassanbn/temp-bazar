import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bazar_suez/support/models/support_conversation.dart';
import 'package:bazar_suez/support/services/support_service.dart';
import 'package:bazar_suez/support/widgets/conversation_card.dart';
import 'package:bazar_suez/theme/app_color.dart';

class SupportCenterPage extends StatefulWidget {
  const SupportCenterPage({super.key});

  @override
  State<SupportCenterPage> createState() => _SupportCenterPageState();
}

class _SupportCenterPageState extends State<SupportCenterPage> {
  final SupportService _supportService = SupportService();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'مركز المساعدة',
            style: TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: StreamBuilder<List<SupportConversation>>(
          stream: _supportService.getUserConversations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.mainColor),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'حدث خطأ أثناء تحميل المحادثات. يرجى المحاولة لاحقاً.',
                  style: TextStyle(
                    fontFamily: 'NotoSansArabic',
                    color: Colors.red.shade700,
                  ),
                ),
              );
            }

            final conversations = snapshot.data ?? [];

            if (conversations.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return ConversationCard(
                  conversation: conversation,
                  onTap: () {
                    context.push('/support/chat/${conversation.id}');
                  },
                );
              },
            );
          },
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: MediaQuery.of(context).padding.bottom + 16.0,
            top: 8.0,
          ),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.mainColor.withOpacity(0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/support/create');
              },
              icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
              label: const Text(
                'إنشاء طلب دعم جديد',
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_outlined,
                size: 80,
                color: AppColors.mainColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد طلبات دعم حالية',
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'إذا واجهتك أي مشكلة في طلباتك أو في استخدام التطبيق، يمكنك الضغط على الزر أدناه لفتح تذكرة دعم وسيتواصل معك فريق العمل.',
              style: TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 14,
                color: Colors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
