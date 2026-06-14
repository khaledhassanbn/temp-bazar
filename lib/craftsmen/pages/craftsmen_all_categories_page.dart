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
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: AppColors.mainColor,
          foregroundColor: Colors.white,
          title: const Text('التصنيفات الرئيسية'),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: kCraftsmanCategoryGroups.length,
          itemBuilder: (context, index) {
            final group = kCraftsmanCategoryGroups[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ExpansionTile(
                initiallyExpanded: index < 2,
                leading: Text(group.emoji, style: const TextStyle(fontSize: 28)),
                title: Text(
                  group.nameAr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text('${group.professions.length} مهنة'),
                children: group.professions
                    .map(
                      (p) => ListTile(
                        title: Text(p.nameAr),
                        trailing: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 14,
                          color: Colors.grey,
                        ),
                        onTap: () => context.push(
                          '/craftsmen/browse?professionId=${p.id}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
