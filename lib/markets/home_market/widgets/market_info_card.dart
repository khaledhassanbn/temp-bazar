import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';

class MarketInfoCard extends StatelessWidget {
  final String marketName;
  final String marketDescription;
  final String marketLogo;
  final double rating;
  final int reviewCount;
  final String deliveryTime;
  final String deliveryFee;

  // 🔹 بيانات حقيقية تأتي من قاعدة البيانات (اختيارية)
  final String? phone;
  final String? facebook;
  final String? instagram;
  final String? marketLink; // نستخدم رابط المتجر للمشاركة
  final String? storeId; // معرف المتجر للتقييمات

  const MarketInfoCard({
    super.key,
    required this.marketName,
    required this.marketDescription,
    required this.marketLogo,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTime,
    required this.deliveryFee,
    this.phone,
    this.facebook,
    this.instagram,
    this.marketLink,
    this.storeId,
  });

  // 🔹 تنسيق الأرقام (1000 → 1,000)
  String _formatWithCommas(int number) {
    final s = number.toString();
    final len = s.length;
    final sb = StringBuffer();
    for (int i = 0; i < len; i++) {
      sb.write(s[i]);
      final pos = len - i - 1;
      if (pos % 3 == 0 && pos != 0) sb.write(',');
    }
    return sb.toString();
  }

  // 🔹 فتح روابط أو مكالمات مع تصحيح البروتوكول المفقود
  Future<void> _launchUrl(String url) async {
    // لو الرابط مفيهوش بروتوكول، نزود https:// عشان نتجنب PlatformException
    final String fixed = url.contains('://') ? url : 'https://$url';
    final uri = Uri.parse(fixed);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('❌ لم يتم فتح الرابط: $fixed');
    }
  }

  String get _phoneNumber =>
      (phone != null && phone!.isNotEmpty) ? phone! : '01012345678';
  String get _whatsappNumber => _phoneNumber; // بدون +
  bool get _hasFacebook => facebook != null && facebook!.isNotEmpty;
  bool get _hasInstagram => instagram != null && instagram!.isNotEmpty;
  String get _shareLink => marketLink != null && marketLink!.isNotEmpty
      ? 'com.example.bazar_suez/market/$marketLink'
      : 'com.example.bazar_suez/market/unknown';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // الصورة يمين
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 الصف العلوي (الشعار + التفاصيل)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ شعار المتجر
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    marketLogo,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.store,
                        size: 32,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ✅ تفاصيل المتجر
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 الاسم + النقاط الثلاثة
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              marketName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.more_vert, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // 🔹 الوصف
                      Text(
                        marketDescription,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // 🔹 التقييم (قابل للنقر لعرض التقييمات)
                      GestureDetector(
                        onTap: storeId != null
                            ? () => context.push(
                                  '/store-reviews?storeId=$storeId&storeName=${Uri.encodeComponent(marketName)}',
                                )
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 18, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(+${_formatWithCommas(reviewCount)})',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_left,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 🔹 صف الأيقونات (واتساب - اتصال - فيسبوك - انستجرام - مشاركة)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🔸 أيقونات التواصل
                Row(
                  children: [
                    _buildIconButton(
                      icon: FontAwesomeIcons.whatsapp,
                      color: Colors.green,
                      onTap: () => _launchUrl(
                        'https://wa.me/$_whatsappNumber?text=مرحبًا!',
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildIconButton(
                      icon: Icons.call,
                      color: Colors.blue,
                      onTap: () => _launchUrl('tel:$_phoneNumber'),
                    ),
                    if (_hasFacebook) const SizedBox(width: 10),
                    if (_hasFacebook)
                      _buildIconButton(
                        icon: FontAwesomeIcons.facebook,
                        color: Colors.blueAccent,
                        onTap: () => _launchUrl(facebook!),
                      ),
                    if (_hasInstagram) const SizedBox(width: 10),
                    if (_hasInstagram)
                      _buildIconButton(
                        icon: FontAwesomeIcons.instagram,
                        color: Colors.purple,
                        onTap: () => _launchUrl(instagram!),
                      ),
                  ],
                ),

                // 🔸 زر المشاركة على اليمين
                _buildIconButton(
                  icon: Icons.share,
                  color: Colors.black87,
                  onTap: () {
                    Share.share(
                      'تعال شوف متجر "$marketName" في بازار السويس 👇\n$_shareLink',
                      subject: marketName,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Widget موحد للأيقونات
  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
