import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bazar_suez/config/site_links.dart';
import 'package:bazar_suez/craftsmen/models/craftsman_model.dart';
import 'package:bazar_suez/craftsmen/services/craftsman_analytics_service.dart';
import 'package:bazar_suez/craftsmen/services/craftsman_review_service.dart';
import 'package:bazar_suez/craftsmen/services/craftsman_service.dart';
import 'package:bazar_suez/shared/widgets/report_dialog.dart';
import 'package:bazar_suez/theme/app_color.dart';

class CraftsmanDetailPage extends StatefulWidget {
  final String craftsmanId;

  const CraftsmanDetailPage({super.key, required this.craftsmanId});

  @override
  State<CraftsmanDetailPage> createState() => _CraftsmanDetailPageState();
}

class _CraftsmanDetailPageState extends State<CraftsmanDetailPage> {
  final _service = CraftsmanService();
  final _analytics = CraftsmanAnalyticsService();
  final _reviews = CraftsmanReviewService();
  CraftsmanModel? _craftsman;
  bool _loading = true;
  bool _isOwner = false; // للتحقق إذا كان صاحب الصفحة
  bool _uploadingPortfolio = false;

  static const double _coverHeight = 260;
  static const double _avatarRadius = 48;
  static const double _avatarOverlap = 30; // how much avatar peeks above card

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await _service.getById(widget.craftsmanId);
    if (c != null) await _analytics.logProfileView(widget.craftsmanId);
    
    // التحقق إذا كان المستخدم الحالي هو صاحب هذا البروفايل
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid != null && currentUid == widget.craftsmanId;
    
    if (mounted) setState(() { 
      _craftsman = c; 
      _loading = false; 
      _isOwner = isOwner;
    });
  }

  Future<void> _share() async {
    final c = _craftsman;
    if (c == null) return;
    final link = publicCraftsmanShareUrl(c.id);
    await Share.share('تعرف على ${c.name} — ${c.professionName}\n$link');
    await _analytics.logShare(c.id);
  }

  Future<void> _pickAndUploadPortfolioImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _uploadingPortfolio = true);

      final file = File(image.path);
      final url = await _service.uploadImage(file, 'portfolio');

      await FirebaseFirestore.instance.collection('craftsmen').doc(widget.craftsmanId).update({
        'portfolioUrls': FieldValue.arrayUnion([url]),
      });

      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الصورة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في رفع الصورة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPortfolio = false);
    }
  }

  Future<void> _deletePortfolioImage(String url) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الصورة'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذه الصورة من معرض أعمالك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('craftsmen').doc(widget.craftsmanId).update({
        'portfolioUrls': FieldValue.arrayRemove([url]),
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الصورة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حذف الصورة: $e')),
        );
      }
    }
  }

  // ─── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        extendBodyBehindAppBar: true,
        appBar: _buildTransparentAppBar(),
        body: _loading
            ? _buildLoader()
            : _craftsman == null
                ? _buildNotFound()
                : _buildContent(_craftsman!),
        bottomNavigationBar:
            _craftsman == null ? null : _contactBar(_craftsman!),
      ),
    );
  }

  PreferredSizeWidget _buildTransparentAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      foregroundColor: Colors.white,
      actions: [
        if (_craftsman != null)
          _appBarAction(Icons.share_outlined, _share),
        // زر الإبلاغ (لغير صاحب الصفحة فقط)
        if (_craftsman != null && !_isOwner)
          _appBarAction(Icons.report_outlined, () {
            showReportDialog(
              context,
              targetId: _craftsman!.id,
              targetType: 'craftsman',
              targetName: _craftsman!.name,
            );
          }),
        // زر التعديل يظهر فقط لصاحب الصفحة
        if (_craftsman != null && _isOwner)
          _appBarAction(Icons.edit_outlined, () {
            context.push('/craftsmen/register?edit=1');
          }),
      ],
      // back button gets a frosted pill background for readability
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _frostedCircleButton(
          Icons.arrow_back_ios_new_rounded,
          () => Navigator.maybePop(context),
        ),
      ),
    );
  }

  Widget _frostedCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _appBarAction(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
      child: _frostedCircleButton(icon, onTap),
    );
  }

  // ─── loader / not-found ──────────────────────────────────────────────────

  Widget _buildLoader() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: AppColors.mainColor),
        const SizedBox(height: 16),
        Text('جارٍ التحميل...',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
      ]),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.person_off_outlined, size: 72, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('الملف غير موجود',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
      ]),
    );
  }

  // ─── main content ────────────────────────────────────────────────────────

  Widget _buildContent(CraftsmanModel c) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ① Cover image — full bleed, no text
          _buildCoverImage(c),

          // ② Profile card slides up over the cover
          Transform.translate(
            offset: const Offset(0, -_avatarOverlap),
            child: Column(
              children: [
                _buildProfileCard(c),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildStatsRow(c),
                      const SizedBox(height: 16),
                      if (c.description.isNotEmpty) ...[
                        _buildSection(
                          title: 'نبذة عن الصنايعي',
                          icon: Icons.info_outline,
                          child: Text(c.description,
                              style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.7,
                                  color: Color(0xFF4A5568))),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (c.portfolioUrls.isNotEmpty || _isOwner) ...[
                        _buildPortfolioSection(c),
                        const SizedBox(height: 16),
                      ],
                      if (c.priceList.isNotEmpty) ...[
                        _buildPriceSection(c),
                        const SizedBox(height: 16),
                      ],
                      _buildReviewsSection(c),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── cover ───────────────────────────────────────────────────────────────

  Widget _buildCoverImage(CraftsmanModel c) {
    final hasCover = c.coverImageUrl != null && c.coverImageUrl!.isNotEmpty;
    return SizedBox(
      height: _coverHeight,
      child: hasCover
          ? CachedNetworkImage(
              imageUrl: c.coverImageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, __) => _gradientCover(),
              errorWidget: (_, __, ___) => _gradientCover(),
            )
          : _gradientCover(),
    );
  }

  Widget _gradientCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.mainColor,
            AppColors.mainColor.withOpacity(0.7),
            const Color(0xFF1A3A5C),
          ],
        ),
      ),
    );
  }

  // ─── profile card ────────────────────────────────────────────────────────

  Widget _buildProfileCard(CraftsmanModel c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // avatar row — sits at top, overlapping cover
          Transform.translate(
            offset: const Offset(0, -_avatarRadius + _avatarOverlap / 2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildAvatar(c),
                  const SizedBox(width: 12),
                  // status pill aligned to bottom of avatar
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _buildStatusPill(c),
                  ),
                  const Spacer(),
                  // badges top-right
                  if (c.badges.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: c.badges.map(_buildBadge).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // name / profession / area
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937))),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.work_outline,
                      color: Color(0xFF6B7280), size: 15),
                  const SizedBox(width: 4),
                  Text(c.professionName,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF6B7280))),
                ]),
                if (c.areaName.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        color: Color(0xFF9CA3AF), size: 15),
                    const SizedBox(width: 4),
                    Text(c.areaName,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF9CA3AF))),
                  ]),
                ],
                if (c.workingHours != null &&
                    c.workingHours!.openDays.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.access_time_outlined,
                        color: Color(0xFF9CA3AF), size: 15),
                    const SizedBox(width: 4),
                    Text(c.workingHours!.openDays.first.displayText,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF9CA3AF))),
                  ]),
                ],
                if (_isOwner) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/craftsmen/register?edit=1'),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('تعديل الملف الشخصي'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.mainColor,
                        side: BorderSide(color: AppColors.mainColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(CraftsmanModel c) {
    final hasPhoto = c.photoUrl != null && c.photoUrl!.isNotEmpty;
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: _avatarRadius,
        backgroundColor: const Color(0xFFE5E7EB),
        backgroundImage: hasPhoto
            ? CachedNetworkImageProvider(c.photoUrl!)
            : const CachedNetworkImageProvider('https://cdn-icons-png.flaticon.com/512/149/149071.png'),
      ),
    );
  }

  Widget _buildStatusPill(CraftsmanModel c) {
    final available = c.isAvailableNow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: available
            ? const Color(0xFF22C55E).withOpacity(0.12)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: available ? const Color(0xFF22C55E) : Colors.red.shade300,
          width: 1,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: available ? const Color(0xFF22C55E) : Colors.red.shade400,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          available ? 'متاح الآن' : 'غير متاح',
          style: TextStyle(
            color: available ? const Color(0xFF16A34A) : Colors.red.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }

  Widget _buildBadge(String b) {
    const map = {
      'verified': (Icons.verified, Color(0xFF3B82F6), 'معتمد'),
      'new': (Icons.fiber_new, Color(0xFF8B5CF6), 'جديد'),
      'fast_response': (Icons.bolt, Color(0xFFF59E0B), 'سريع'),
      'recommended': (Icons.thumb_up, Color(0xFF10B981), 'موصى به'),
    };
    final entry = map[b];
    final color = entry?.$2 ?? const Color(0xFF6B7280);
    final label = entry?.$3 ?? b;
    final icon = entry?.$1 ?? Icons.label_outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ─── stats row ───────────────────────────────────────────────────────────

  Widget _buildStatsRow(CraftsmanModel c) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _statItem(Icons.star_rounded, const Color(0xFFF59E0B),
                c.averageRating.toStringAsFixed(1), 'التقييم'),
            _vDivider(),
            _statItem(Icons.rate_review_outlined, AppColors.mainColor,
                '${c.totalReviews}', 'تقييم'),
            if (c.responseRate > 0) ...[
              _vDivider(),
              _statItem(Icons.speed_outlined, const Color(0xFF10B981),
                  '${(c.responseRate * 100).round()}%', 'الاستجابة'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937))),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ]),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 40, color: Colors.grey.shade200);

  // ─── section card ────────────────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.mainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.mainColor, size: 16),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          if (trailing != null) ...[const Spacer(), trailing],
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  // ─── portfolio ───────────────────────────────────────────────────────────

  Widget _buildPortfolioSection(CraftsmanModel c) {
    return _buildSection(
      title: 'معرض الأعمال',
      icon: Icons.photo_library_outlined,
      child: SizedBox(
        height: 130,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: c.portfolioUrls.length + (_isOwner ? 1 : 0),
          itemBuilder: (_, i) {
            if (i < c.portfolioUrls.length) {
              final url = c.portfolioUrls[i];
              return Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 150,
                        height: 130,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            width: 150,
                            height: 130,
                            color: Colors.grey.shade100,
                            child: const Center(child: CircularProgressIndicator())),
                      ),
                    ),
                    if (_isOwner)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => _deletePortfolioImage(url),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(left: 10),
                child: _uploadingPortfolio
                    ? Container(
                        width: 150,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : GestureDetector(
                        onTap: _pickAndUploadPortfolioImage,
                        child: Container(
                          width: 150,
                          height: 130,
                          decoration: BoxDecoration(
                            color: AppColors.mainColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.mainColor.withOpacity(0.3),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  color: AppColors.mainColor, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                'إضافة صورة',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.mainColor),
                              ),
                            ],
                          ),
                        ),
                      ),
              );
            }
          },
        ),
      ),
    );
  }

  // ─── prices ──────────────────────────────────────────────────────────────

  Widget _buildPriceSection(CraftsmanModel c) {
    return _buildSection(
      title: 'قائمة الأسعار',
      icon: Icons.price_change_outlined,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Text('استرشادية',
            style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
      ),
      child: Column(
        children: c.priceList.asMap().entries.map((e) {
          final i = e.key;
          final p = e.value;
          return Column(children: [
            if (i != 0) Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: AppColors.mainColor.withOpacity(0.4),
                        shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(p.serviceName,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF374151)))),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${p.price.toStringAsFixed(0)} ج.م',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainColor)),
                ),
              ]),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  // ─── reviews ─────────────────────────────────────────────────────────────

  Widget _buildReviewsSection(CraftsmanModel c) {
    return _buildSection(
      title: 'التقييمات',
      icon: Icons.reviews_outlined,
      trailing: TextButton.icon(
        onPressed: () => _showRatingDialog(c.id),
        icon: const Icon(Icons.add, size: 14),
        label: const Text('أضف تقييم', style: TextStyle(fontSize: 12)),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.mainColor,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
        ),
      ),
      child: StreamBuilder(
        stream: _reviews.reviewsStream(c.id),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator()));
          }
          if (snap.data!.docs.isEmpty) {
            return Column(children: [
              Icon(Icons.rate_review_outlined,
                  size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text('لا توجد تقييمات بعد',
                  style:
                      TextStyle(color: Colors.grey.shade400, fontSize: 14)),
              const SizedBox(height: 4),
              Text('كن أول من يقيّم هذا الصنايعي!',
                  style:
                      TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            ]);
          }
          return Column(
            children: snap.data!.docs.map((doc) {
              final d = doc.data();
              final rating = (d['rating'] ?? 0) as int;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppColors.mainColor.withOpacity(0.1),
                          backgroundImage: (d['userPhoto']?.toString() != null && d['userPhoto']!.toString().isNotEmpty)
                              ? CachedNetworkImageProvider(d['userPhoto']!.toString())
                              : const CachedNetworkImageProvider('https://cdn-icons-png.flaticon.com/512/149/149071.png'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                d['userName']?.toString() ?? 'مجهول',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Color(0xFF374151)))),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                              5,
                              (i) => Icon(
                                    i < rating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 15,
                                    color: const Color(0xFFF59E0B),
                                  )),
                        ),
                      ]),
                      if ((d['comment']?.toString() ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(d['comment']?.toString() ?? '',
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                height: 1.5)),
                      ],
                    ]),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ─── contact bar ─────────────────────────────────────────────────────────

  Widget _contactBar(CraftsmanModel c) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () async {
                  await _analytics.logContact(
                      craftsmanId: c.id,
                      channel: ContactChannel.call,
                      phone: c.phone,
                      whatsapp: c.whatsapp);
                  // فتح تطبيق الهاتف
                  final phoneUri = Uri.parse('tel:${c.phone}');
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri);
                  }
                },
                icon: const Icon(Icons.phone_rounded, size: 18),
                label: const Text('اتصال',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () async {
                  await _analytics.logContact(
                      craftsmanId: c.id,
                      channel: ContactChannel.whatsapp,
                      phone: c.phone,
                      whatsapp: c.whatsapp);
                  
                  var whatsappNumber = c.whatsapp.isNotEmpty ? c.whatsapp : c.phone;
                  // تنظيف الرقم من أي مسافات أو رموز غير رقمية
                  whatsappNumber = whatsappNumber.replaceAll(RegExp(r'[^\d]'), '');
                  
                  // تحويل الأرقام المحلية (المصرية) إلى الصيغة الدولية لـ wa.me
                  if (whatsappNumber.startsWith('0') && whatsappNumber.length == 11) {
                    whatsappNumber = '20' + whatsappNumber.substring(1);
                  } else if (whatsappNumber.startsWith('1') && whatsappNumber.length == 10) {
                    whatsappNumber = '20' + whatsappNumber;
                  }
                  
                  final whatsappAppUri = Uri.parse('whatsapp://send?phone=$whatsappNumber');
                  final whatsappWebUri = Uri.parse('https://wa.me/$whatsappNumber');
                  
                  try {
                    if (await canLaunchUrl(whatsappAppUri)) {
                      await launchUrl(whatsappAppUri);
                    } else if (await canLaunchUrl(whatsappWebUri)) {
                      await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
                    } else {
                      await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
                    }
                  } catch (e) {
                    try {
                      await launchUrl(whatsappWebUri, mode: LaunchMode.externalNonBrowserApplication);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تعذر فتح تطبيق واتساب')),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: const Text('واتساب',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── rating dialog ───────────────────────────────────────────────────────

  Future<void> _showRatingDialog(String craftsmanId) async {
    var rating = 5;
    final commentCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.rate_review_outlined,
                    color: AppColors.mainColor, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('قيّم تجربتك مع الصنايعي',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937))),
              const SizedBox(height: 4),
              Text('شاركنا رأيك لمساعدة الآخرين',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 20),
              StatefulBuilder(
                builder: (ctx, setS) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setS(() => rating = i + 1),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          i < rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 36,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                decoration: InputDecoration(
                  hintText: 'اكتب تعليقك هنا... (اختياري)',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.mainColor, width: 1.5)),
                  contentPadding: const EdgeInsets.all(12),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('إلغاء',
                        style: TextStyle(color: Color(0xFF6B7280))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('إرسال',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
    if (ok == true) {
      await _reviews.submitReview(
        craftsmanId: craftsmanId,
        rating: rating,
        comment: commentCtrl.text.trim().isEmpty
            ? null
            : commentCtrl.text.trim(),
      );
      await _load();
    }
    commentCtrl.dispose();
  }
}
