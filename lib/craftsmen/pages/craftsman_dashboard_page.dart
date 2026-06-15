import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bazar_suez/widgets/auth_gate.dart';

import 'package:bazar_suez/craftsmen/models/craftsman_model.dart';
import 'package:bazar_suez/craftsmen/services/craftsman_service.dart';
import 'package:bazar_suez/theme/app_color.dart';

class CraftsmanDashboardPage extends StatefulWidget {
  const CraftsmanDashboardPage({super.key});

  @override
  State<CraftsmanDashboardPage> createState() => _CraftsmanDashboardPageState();
}

class _CraftsmanDashboardPageState extends State<CraftsmanDashboardPage> {
  final _service = CraftsmanService();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Text(
            'سجّل الدخول أولاً',
            style: GoogleFonts.cairo(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F7),
        body: StreamBuilder<CraftsmanModel?>(
          stream: _service.watchById(uid),
          builder: (context, snap) {
            if (!snap.hasData) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.mainColor),
              );
            }
            final c = snap.data;
            if (c == null) return _EmptyState(service: _service);

            return CustomScrollView(
              slivers: [
                _DashboardHeader(craftsman: c),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        if (c.hasAccountRestriction)
                          _AccountStatusBanner(craftsman: c),
                        if (c.hasAccountRestriction) const SizedBox(height: 16),
                        _QuickStatsRow(craftsman: c),
                        const SizedBox(height: 20),
                        _sectionHeader('الإعدادات السريعة', Icons.tune_rounded),
                        const SizedBox(height: 10),
                        _ToggleCard(craftsman: c, service: _service),
                        const SizedBox(height: 20),
                        _sectionHeader('التقييم والمراجعات', Icons.star_rounded),
                        const SizedBox(height: 10),
                        _RatingCard(craftsman: c),
                        const SizedBox(height: 20),
                        _sectionHeader('إحصائيات الأداء', Icons.bar_chart_rounded),
                        const SizedBox(height: 10),
                        _StatsCard(craftsman: c),
                        const SizedBox(height: 20),
                        _sectionHeader('معدل الاستجابة', Icons.reply_rounded),
                        const SizedBox(height: 10),
                        _ResponseRateCard(craftsman: c),
                        if (c.subscriptionEnd != null) ...[
                          const SizedBox(height: 20),
                          _sectionHeader('الاشتراك', Icons.workspace_premium_rounded),
                          const SizedBox(height: 10),
                          _SubscriptionCard(craftsman: c),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.mainColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final CraftsmanModel craftsman;
  const _DashboardHeader({required this.craftsman});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4E99B4), Color(0xFF2A7A95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'لوحة التحكم',
                      style: GoogleFonts.cairo(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _GlassButton(
                      icon: Icons.edit_outlined,
                      label: 'تعديل الملف',
                      onTap: () => pushIfAuthed(
                        context,
                        '/craftsmen/register?edit=1',
                        message: 'سجّل دخولك لتعديل ملف الصنايعي',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Craftsman info
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          craftsman.name.isNotEmpty
                              ? craftsman.name.substring(0, 1)
                              : '؟',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            craftsman.name,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${craftsman.professionName} • ${craftsman.areaName}',
                            style: GoogleFonts.cairo(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _AvailabilityBadge(
                                  isAvailable: craftsman.isAvailableNow),
                              if (craftsman.hasAccountRestriction) ...[
                                const SizedBox(width: 8),
                                _AccountStatusChip(craftsman: craftsman),
                              ],
                            ],
                          ),
                        ],
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

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final color =
        isAvailable ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final label = isAvailable ? 'متاح الآن' : 'غير متاح';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountStatusChip extends StatelessWidget {
  final CraftsmanModel craftsman;
  const _AccountStatusChip({required this.craftsman});

  Color get _color {
    final label = craftsman.accountStatusLabel;
    if (label == 'محذوف') return const Color(0xFF6B7280);
    if (label == 'محظور') return const Color(0xFFEF4444);
    if (label == 'موقوف') return const Color(0xFFF59E0B);
    return const Color(0xFF6B7280);
  }

  IconData get _icon {
    final label = craftsman.accountStatusLabel;
    if (label == 'محذوف') return Icons.delete_outline;
    if (label == 'محظور') return Icons.block;
    if (label == 'موقوف') return Icons.pause_circle_outline;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            craftsman.accountStatusLabel,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountStatusBanner extends StatelessWidget {
  final CraftsmanModel craftsman;
  const _AccountStatusBanner({required this.craftsman});

  Color get _color {
    final label = craftsman.accountStatusLabel;
    if (label == 'محذوف') return const Color(0xFF6B7280);
    if (label == 'محظور') return const Color(0xFFEF4444);
    if (label == 'موقوف') return const Color(0xFFF59E0B);
    return const Color(0xFF6B7280);
  }

  IconData get _icon {
    final label = craftsman.accountStatusLabel;
    if (label == 'محذوف') return Icons.delete_outline_rounded;
    if (label == 'محظور') return Icons.block_rounded;
    if (label == 'موقوف') return Icons.pause_circle_outline_rounded;
    return Icons.info_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final message = craftsman.accountRestrictionMessage ??
        'حسابك ${craftsman.accountStatusLabel}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة الحساب: ${craftsman.accountStatusLabel}',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: const Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GlassButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Stats ─────────────────────────────────────────────────────────────
class _QuickStatsRow extends StatelessWidget {
  final CraftsmanModel craftsman;
  const _QuickStatsRow({required this.craftsman});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.visibility_outlined,
            value: '${craftsman.stats.profileViews}',
            label: 'مشاهدات',
            color: AppColors.mainColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.check_circle_outline,
            value: '${craftsman.completedJobsCount}',
            label: 'طلبات مكتملة',
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.star_outline_rounded,
            value: craftsman.averageRating.toStringAsFixed(1),
            label: 'التقييم',
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _MiniStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.cairo(
              color: const Color(0xFF1F2937),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Toggle Card ─────────────────────────────────────────────────────────────
class _ToggleCard extends StatelessWidget {
  final CraftsmanModel craftsman;
  final CraftsmanService service;
  const _ToggleCard({required this.craftsman, required this.service});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        children: [
          _ToggleRow(
            icon: Icons.wifi_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'متاح الآن',
            subtitle: 'يظهر للعملاء كمتاح للعمل',
            value: craftsman.isAvailableNow,
            activeColor: const Color(0xFF10B981),
            onChanged: (v) =>
                service.updateAvailability(isAvailableNow: v),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _ToggleRow(
            icon: Icons.visibility_off_outlined,
            iconColor: const Color(0xFFEC4899),
            title: 'إخفاء من البحث',
            subtitle: 'إخفاء مؤقت عن نتائج البحث',
            value: craftsman.isSelfHidden,
            activeColor: const Color(0xFFEF4444),
            onChanged: (v) => service.updateAvailability(
              isAvailableNow: craftsman.isAvailableNow,
              isSelfHidden: v,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF1F2937),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
            activeTrackColor: activeColor.withOpacity(0.25),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }
}

// ─── Rating Card ─────────────────────────────────────────────────────────────
class _RatingCard extends StatelessWidget {
  final CraftsmanModel craftsman;
  const _RatingCard({required this.craftsman});

  @override
  Widget build(BuildContext context) {
    final rating = craftsman.averageRating;
    final total = craftsman.totalReviews;
    return _SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left: big number + stars
            Column(
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF1F2937),
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < rating.floor()
                          ? Icons.star_rounded
                          : i < rating
                              ? Icons.star_half_rounded
                              : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 16,
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  'من $total تقييم',
                  style: GoogleFonts.cairo(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            // Right: bar distribution
            Expanded(
              child: Column(
                children: [5, 4, 3, 2, 1].map((star) {
                  final pct = star == 5
                      ? 0.78
                      : star == 4
                          ? 0.14
                          : star == 3
                              ? 0.05
                              : star == 2
                                  ? 0.02
                                  : 0.01;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Text(
                          '$star',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 11),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFFF59E0B)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Card ──────────────────────────────────────────────────────────────
class _StatsCard extends StatelessWidget {
  final CraftsmanModel craftsman;
  const _StatsCard({required this.craftsman});

  @override
  Widget build(BuildContext context) {
    final s = craftsman.stats;
    final maxVal = [
      s.profileViews,
      s.callClicks,
      s.whatsappClicks,
      s.shareClicks,
      s.searchImpressions,
    ].reduce((a, b) => a > b ? a : b);

    final rows = [
      (Icons.visibility_outlined, AppColors.mainColor, 'مشاهدات البروفايل', s.profileViews),
      (Icons.phone_outlined, const Color(0xFF10B981), 'ضغطات الاتصال', s.callClicks),
      (Icons.chat_outlined, const Color(0xFF10B981), 'ضغطات الواتساب', s.whatsappClicks),
      (Icons.share_outlined, const Color(0xFF8B5CF6), 'مشاركة البروفايل', s.shareClicks),
      (Icons.search_rounded, const Color(0xFFF59E0B), 'ظهور في البحث', s.searchImpressions),
    ];

    return _SurfaceCard(
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          final row = e.value;
          return Column(
            children: [
              _StatProgressRow(
                icon: row.$1,
                color: row.$2,
                label: row.$3,
                value: row.$4,
                maxValue: maxVal,
              ),
              if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _StatProgressRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int value;
  final int maxValue;
  const _StatProgressRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final pct = maxValue == 0 ? 0.0 : value / maxValue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$value',
            style: GoogleFonts.cairo(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Response Rate Card ───────────────────────────────────────────────────────
class _ResponseRateCard extends StatelessWidget {
  final CraftsmanModel craftsman;
  const _ResponseRateCard({required this.craftsman});

  @override
  Widget build(BuildContext context) {
    final rate = craftsman.responseRate;
    final pct = (rate * 100).round();
    return _SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.reply_rounded, color: AppColors.mainColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نسبة الرد على الطلبات',
                    style: GoogleFonts.cairo(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: rate,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade100,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.mainColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$pct%',
              style: GoogleFonts.cairo(
                color: AppColors.mainColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Subscription Card ────────────────────────────────────────────────────────
class _SubscriptionCard extends StatelessWidget {
  final CraftsmanModel craftsman;
  const _SubscriptionCard({required this.craftsman});

  @override
  Widget build(BuildContext context) {
    final end = craftsman.subscriptionEnd!;
    final formatted = '${end.day} / ${end.month} / ${end.year}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4E99B4), Color(0xFF2A7A95)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تنتهي في',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                  ),
                ),
                Text(
                  formatted,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: Text(
              'نشط',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final CraftsmanService service;
  const _EmptyState({required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.handyman_outlined,
                    size: 56, color: AppColors.mainColor),
              ),
              const SizedBox(height: 20),
              Text(
                'لم تسجّل ملفاً بعد',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'سجّل ملفك الآن وابدأ باستقبال الطلبات',
                style: GoogleFonts.cairo(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => pushIfAuthed(
                    context,
                    '/craftsmen/register',
                    message: 'سجّل دخولك لإنشاء ملف صنايعي',
                  ),
                  child: Text(
                    'تسجيل الآن',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared Surface Card ──────────────────────────────────────────────────────
class _SurfaceCard extends StatelessWidget {
  final Widget child;
  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}