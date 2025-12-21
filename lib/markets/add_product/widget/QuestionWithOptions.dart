import 'package:bazar_suez/theme/app_color.dart';
import 'package:bazar_suez/widgets/app_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';

class QuestionWithOptions extends StatefulWidget {
  final List<Map<String, TextEditingController>> optionsControllers;
  // Emits multiple groups: [{ title, items: [{name, price}] }]
  final void Function({
    required bool enabled,
    required List<Map<String, dynamic>> groups,
  })?
  onChanged;

  const QuestionWithOptions({
    Key? key,
    required this.optionsControllers,
    this.onChanged,
  }) : super(key: key);

  @override
  State<QuestionWithOptions> createState() => _QuestionWithOptionsState();
}

class _QuestionWithOptionsState extends State<QuestionWithOptions> {
  bool optionsEnabled = false;

  // Each group has a title controller and its own item controllers
  final List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    // Seed with one group using the incoming controllers (not owned here)
    _groups.add({
      'title': TextEditingController(),
      'groupOwned': false,
      'items': widget.optionsControllers
          .map<Map<String, dynamic>>(
            (m) => {'name': m['name']!, 'price': m['price']!, 'owned': false},
          )
          .toList(),
    });
  }

  @override
  void dispose() {
    for (final g in _groups) {
      final bool groupOwned = (g['groupOwned'] as bool?) ?? false;
      if (groupOwned) {
        (g['title'] as TextEditingController).dispose();
      }
      for (final m in (g['items'] as List<Map<String, dynamic>>)) {
        final bool owned = (m['owned'] as bool?) ?? false;
        if (owned) {
          (m['name'] as TextEditingController).dispose();
          (m['price'] as TextEditingController).dispose();
        }
      }
    }
    super.dispose();
  }

  void _emitChange() {
    if (widget.onChanged == null) return;
    final groups = <Map<String, dynamic>>[];
    for (final g in _groups) {
      final title = (g['title'] as TextEditingController).text.trim();
      final itemsCtrls = g['items'] as List<Map<String, dynamic>>;
      final items = <Map<String, String>>[];
      for (final m in itemsCtrls) {
        final name = ((m['name'] as TextEditingController).text).trim();
        final price = ((m['price'] as TextEditingController).text).trim();
        if (name.isEmpty) continue;
        items.add({'name': name, 'price': price});
      }
      groups.add({'title': title, 'items': items});
    }
    widget.onChanged!(enabled: optionsEnabled, groups: groups);
  }

  @override
  Widget build(BuildContext context) {
    // نبني المحتوى داخل عمود ثم نغلفه بحاوية نهتزها
    final content = Column(
      children: [
        // 🔹 تفعيل الخيارات
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "تفعيل",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Switch(
              activeColor: AppColors.mainColor,
              value: optionsEnabled,
              onChanged: (val) {
                setState(() {
                  optionsEnabled = val;
                  if (optionsEnabled && widget.optionsControllers.isEmpty) {
                    widget.optionsControllers.add({
                      "name": TextEditingController(),
                      "price": TextEditingController(),
                    });
                  }
                  // إذا كنت تريد أن تمسح الكنترولرز عند الإلغاء، أضف منطق الحذف هنا (واصرفهم في parent)
                });
                _emitChange();
              },
            ),
          ],
        ),

        if (optionsEnabled) ...[
          const SizedBox(height: 16),
          Column(
            children: [
              for (int gi = 0; gi < _groups.length; gi++) ...[
                AppTextField(
                  controller: _groups[gi]['title'] as TextEditingController,
                  label: "عنوان مجموعة الخيارات",
                  hint: "مثال: اختر الحجم",
                  onChanged: (_) => _emitChange(),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    for (
                      int i = 0;
                      i < (_groups[gi]['items'] as List).length;
                      i++
                    )
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller:
                                    ((_groups[gi]['items']
                                            as List<
                                              Map<String, dynamic>
                                            >)[i]["name"])
                                        as TextEditingController,
                                label: "اسم الخيار",
                                hint: "مثال: حجم كبير",
                                onChanged: (_) => _emitChange(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppTextField(
                                controller:
                                    ((_groups[gi]['items']
                                            as List<
                                              Map<String, dynamic>
                                            >)[i]["price"])
                                        as TextEditingController,
                                label: "سعر الخيار",
                                hint: "0",
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (_) => _emitChange(),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AppColors.mainColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  final items =
                                      (_groups[gi]['items']
                                          as List<Map<String, dynamic>>);
                                  final removed = items.removeAt(i);
                                  final bool owned =
                                      (removed['owned'] as bool?) ?? false;
                                  if (owned) {
                                    (removed['name'] as TextEditingController)
                                        .dispose();
                                    (removed['price'] as TextEditingController)
                                        .dispose();
                                  }
                                });
                                _emitChange();
                              },
                            ),
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 12,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                (_groups[gi]['items'] as List).add({
                                  "name": TextEditingController(),
                                  "price": TextEditingController(),
                                  'owned': true,
                                });
                              });
                              _emitChange();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text(
                              "إضافة خيار آخر",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.mainColor,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _groups.add({
                                  'title': TextEditingController(),
                                  'groupOwned': true,
                                  'items': <Map<String, dynamic>>[
                                    {
                                      "name": TextEditingController(),
                                      "price": TextEditingController(),
                                      'owned': true,
                                    },
                                  ],
                                });
                              });
                              _emitChange();
                            },
                            icon: const Icon(Icons.playlist_add),
                            label: const Text(
                              "إضافة مجموعة خيارات جديدة",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.mainColor,
                              ),
                            ),
                          ),
                          if (_groups.length > 1)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  final g = _groups.removeAt(gi);
                                  final bool groupOwned =
                                      (g['groupOwned'] as bool?) ?? false;
                                  if (groupOwned) {
                                    (g['title'] as TextEditingController)
                                        .dispose();
                                  }
                                  for (final m
                                      in (g['items']
                                          as List<Map<String, dynamic>>)) {
                                    final bool owned =
                                        (m['owned'] as bool?) ?? false;
                                    if (owned) {
                                      (m['name'] as TextEditingController)
                                          .dispose();
                                      (m['price'] as TextEditingController)
                                          .dispose();
                                    }
                                  }
                                });
                                _emitChange();
                              },
                              icon: const Icon(Icons.delete_forever),
                              label: const Text(
                                "حذف المجموعة",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.mainColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ],
      ],
    );

    // نلف المحتوى بـ Container ثم نطبّق الـ shake animation على الحاوية
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(child: content),
    ).animate().shake(duration: 600.ms, hz: 3, offset: const Offset(8, 0));
  }
}
