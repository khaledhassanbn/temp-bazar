import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bazar_suez/craftsmen/data/craftsman_categories.dart';
import 'package:bazar_suez/theme/app_color.dart';

/// كل التصنيفات الرئيسية والمهن الفرعية.
class CraftsmenAllCategoriesPage extends StatelessWidget {
  const CraftsmenAllCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'التصنيفات الرئيسية',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: kCraftsmanCategoryGroups.length,
          itemBuilder: (context, index) {
            final group = kCraftsmanCategoryGroups[index];
            return _CategoryCard(
              group: group,
              initiallyExpanded: index < 2,
            );
          },
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.group,
    required this.initiallyExpanded,
  });

  final dynamic group; // CraftsmanCategoryGroup
  final bool initiallyExpanded;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEFF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: AppColors.mainColor.withOpacity(0.06),
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.mainColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(group.emoji, style: const TextStyle(fontSize: 24)),
          ),
          title: InkWell(
            onTap: () => context.push(
              '/CraftsmenCategoryPage?groupId=${group.id}',
            ),
            child: Text(
              group.nameAr,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${group.professions.length} مهنة',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          trailing: AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.grey, size: 26),
          ),
          children: [
            const Divider(height: 1, color: Color(0xFFF0F0F3)),
            ...group.professions.map<Widget>(
              (p) => InkWell(
                onTap: () {
                  final profession = p;
                  context.push(
                    '/CraftsmenCategoryPage?groupId=${group.id}&professionId=${profession.id}',
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.mainColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.nameAr,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_back_ios_new,
                        size: 13,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}