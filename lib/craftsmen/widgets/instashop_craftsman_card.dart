import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bazar_suez/craftsmen/models/craftsman_filter_options.dart';
import 'package:bazar_suez/craftsmen/services/craftsman_analytics_service.dart';
import 'package:bazar_suez/theme/app_color.dart';

/// كارت عرض الصنايعي — صورة، اسم، مهنة، منطقة، تقييم، مسافة، اتصال + واتساب.
class InstashopCraftsmanCard extends StatelessWidget {
  final CraftsmanSearchResult result;
  final String? professionLabel;
  final String? groupLabel;

  const InstashopCraftsmanCard({
    super.key,
    required this.result,
    this.professionLabel,
    this.groupLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = result.craftsman;
    final profession = professionLabel?.isNotEmpty == true
        ? professionLabel!
        : (groupLabel?.isNotEmpty == true ? groupLabel! : c.professionName);
    final imageUrl = c.photoUrl;
    final distanceKm = result.distanceKm;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/craftsmen/${c.id}'),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.mainColor.withValues(alpha: 0.15),
                              AppColors.mainColor.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: AppColors.mainColor.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      _fallbackAvatar(c.name),
                                )
                              : _fallbackAvatar(c.name),
                        ),
                      ),
                      if (c.isAvailableNow)
                        Positioned(
                          bottom: 2,
                          left: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (profession.isNotEmpty)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.mainColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                profession,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mainColor,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Color(0xFFFBBF24),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              c.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            if (c.totalReviews > 0) ...[
                              Text(
                                ' (${c.totalReviews})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                            if (c.areaName != null && c.areaName!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  c.areaName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (distanceKm != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.near_me_outlined,
                                size: 13,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                result.distanceText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (!c.isAvailableNow) ...[
                          const SizedBox(height: 4),
                          Text(
                            'غير متاح حالياً',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.call_rounded,
                      label: 'اتصال',
                      color: AppColors.mainColor,
                      filled: true,
                      onTap: c.phone.isNotEmpty
                          ? () => CraftsmanAnalyticsService().logContact(
                                craftsmanId: c.id,
                                channel: ContactChannel.call,
                                phone: c.phone,
                                whatsapp: c.whatsapp,
                              )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.chat_rounded,
                      label: 'واتساب',
                      color: const Color(0xFF25D366),
                      filled: false,
                      onTap: c.whatsapp.isNotEmpty
                          ? () => CraftsmanAnalyticsService().logContact(
                                craftsmanId: c.id,
                                channel: ContactChannel.whatsapp,
                                phone: c.phone,
                                whatsapp: c.whatsapp,
                              )
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackAvatar(String name) {
    final initial = name.trim().isNotEmpty ? name.trim()[0] : '؟';
    return Container(
      color: AppColors.mainColor.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.mainColor,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: disabled
          ? Colors.grey.shade100
          : (filled ? color : color.withValues(alpha: 0.1)),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: disabled
                    ? Colors.grey.shade400
                    : (filled ? Colors.white : color),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: disabled
                      ? Colors.grey.shade400
                      : (filled ? Colors.white : color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
