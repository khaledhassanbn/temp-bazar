import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bazar_suez/craftsmen/models/craftsman_filter_options.dart';
import 'package:bazar_suez/theme/app_color.dart';

class CraftsmanCard extends StatelessWidget {
  final CraftsmanSearchResult result;
  final VoidCallback? onImpression;

  const CraftsmanCard({super.key, required this.result, this.onImpression});

  @override
  Widget build(BuildContext context) {
    if (onImpression != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onImpression!());
    }

    final c = result.craftsman;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/craftsmen/${c.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Avatar(url: c.photoUrl, name: c.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (c.hasNewBadge)
                          _BadgeChip(label: 'جديد', color: Colors.green),
                        if (c.isFeatured)
                          _BadgeChip(label: 'مميز', color: Colors.amber.shade800),
                      ],
                    ),
                    Text(
                      c.professionName,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    if (c.areaName != null && c.areaName!.isNotEmpty)
                      Text(
                        c.areaName!,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                        Text(
                          ' ${c.averageRating.toStringAsFixed(1)} (${c.totalReviews})',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.phone_in_talk, size: 14, color: Colors.grey.shade600),
                        Text(
                          ' ${c.callClicks + c.whatsappClicks}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (result.distanceKm != null) ...[
                          const Spacer(),
                          Icon(Icons.place, size: 14, color: AppColors.mainColor),
                          Text(
                            ' ${result.distanceText}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mainColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!c.isAvailableNow)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'غير متاح حالياً',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;

  const _Avatar({this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.mainColor.withOpacity(0.15),
      backgroundImage: url != null && url!.isNotEmpty
          ? CachedNetworkImageProvider(url!)
          : null,
      child: url == null || url!.isEmpty
          ? Text(
              name.isNotEmpty ? name[0] : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.mainColor,
              ),
            )
          : null,
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _BadgeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
