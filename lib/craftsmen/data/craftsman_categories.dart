/// تصنيفات الصنايعية الرئيسية والمهن الفرعية.
class CraftsmanCategoryGroup {
  final String id;
  final String nameAr;
  final String emoji;
  final String iconName;
  final List<CraftsmanProfession> professions;

  const CraftsmanCategoryGroup({
    required this.id,
    required this.nameAr,
    required this.emoji,
    required this.iconName,
    required this.professions,
  });
}

class CraftsmanProfession {
  final String id;
  final String nameAr;
  final String groupId;

  const CraftsmanProfession({
    required this.id,
    required this.nameAr,
    required this.groupId,
  });
}

const List<CraftsmanCategoryGroup> kCraftsmanCategoryGroups = [
  CraftsmanCategoryGroup(
    id: 'finishing',
    nameAr: 'التشطيبات والبناء',
    emoji: '🏠',
    iconName: 'home_work',
    professions: [
      CraftsmanProfession(id: 'buildings_brick', nameAr: 'المباني والطوب', groupId: 'finishing'),
      CraftsmanProfession(id: 'plaster', nameAr: 'المحارة', groupId: 'finishing'),
      CraftsmanProfession(id: 'ceramic', nameAr: 'السيراميك والبورسلين', groupId: 'finishing'),
      CraftsmanProfession(id: 'marble', nameAr: 'الرخام', groupId: 'finishing'),
      CraftsmanProfession(id: 'painting_trade', nameAr: 'النقاشة', groupId: 'finishing'),
      CraftsmanProfession(id: 'paints', nameAr: 'الدهانات', groupId: 'finishing'),
      CraftsmanProfession(id: 'decor', nameAr: 'الديكورات', groupId: 'finishing'),
      CraftsmanProfession(id: 'gypsum', nameAr: 'الألواح الجبسية', groupId: 'finishing'),
    ],
  ),
  CraftsmanCategoryGroup(
    id: 'plumbing_electric',
    nameAr: 'السباكة والكهرباء',
    emoji: '🔧',
    iconName: 'plumbing',
    professions: [
      CraftsmanProfession(id: 'plumber', nameAr: 'سباكة', groupId: 'plumbing_electric'),
      CraftsmanProfession(id: 'electrician', nameAr: 'كهرباء', groupId: 'plumbing_electric'),
      CraftsmanProfession(id: 'water_filter', nameAr: 'فلاتر مياه منزلية', groupId: 'plumbing_electric'),
      CraftsmanProfession(id: 'heating', nameAr: 'تدفئة', groupId: 'plumbing_electric'),
      CraftsmanProfession(id: 'pool', nameAr: 'حمامات سباحة', groupId: 'plumbing_electric'),
    ],
  ),
  CraftsmanCategoryGroup(
    id: 'carpentry_metal',
    nameAr: 'النجارة والحدادة',
    emoji: '🪚',
    iconName: 'carpenter',
    professions: [
      CraftsmanProfession(id: 'carpenter', nameAr: 'نجارة', groupId: 'carpentry_metal'),
      CraftsmanProfession(id: 'reinforced_carpenter', nameAr: 'نجار مسلح', groupId: 'carpentry_metal'),
      CraftsmanProfession(id: 'blacksmith', nameAr: 'حدادة', groupId: 'carpentry_metal'),
      CraftsmanProfession(id: 'reinforced_blacksmith', nameAr: 'حداد مسلح', groupId: 'carpentry_metal'),
      CraftsmanProfession(id: 'aluminum', nameAr: 'ألوميتال وشتر', groupId: 'carpentry_metal'),
      CraftsmanProfession(id: 'accordion', nameAr: 'أعمال الأكورديون والكوران', groupId: 'carpentry_metal'),
    ],
  ),
  CraftsmanCategoryGroup(
    id: 'ac_insulation',
    nameAr: 'التكييف والعزل',
    emoji: '❄️',
    iconName: 'ac_unit',
    professions: [
      CraftsmanProfession(id: 'ac', nameAr: 'أعمال التكييفات', groupId: 'ac_insulation'),
      CraftsmanProfession(id: 'moisture_insulation', nameAr: 'عزل رطوبة', groupId: 'ac_insulation'),
      CraftsmanProfession(id: 'heat_insulation', nameAr: 'عزل حرارة', groupId: 'ac_insulation'),
    ],
  ),
  CraftsmanCategoryGroup(
    id: 'glass_kitchen',
    nameAr: 'الزجاج والمطابخ',
    emoji: '🪟',
    iconName: 'kitchen',
    professions: [
      CraftsmanProfession(id: 'glass_work', nameAr: 'أعمال الزجاج', groupId: 'glass_kitchen'),
      CraftsmanProfession(id: 'kitchens', nameAr: 'مطابخ', groupId: 'glass_kitchen'),
      CraftsmanProfession(id: 'furniture', nameAr: 'موبيليا ومفروشات وستائر', groupId: 'glass_kitchen'),
    ],
  ),
  CraftsmanCategoryGroup(
    id: 'tech_systems',
    nameAr: 'الأنظمة التقنية',
    emoji: '📡',
    iconName: 'videocam',
    professions: [
      CraftsmanProfession(id: 'cctv', nameAr: 'كاميرات وأنظمة مراقبة', groupId: 'tech_systems'),
      CraftsmanProfession(id: 'satellite_net', nameAr: 'دش وشبكات إنترنت', groupId: 'tech_systems'),
    ],
  ),
  CraftsmanCategoryGroup(
    id: 'garden_home',
    nameAr: 'الحدائق والخدمات المنزلية',
    emoji: '🌳',
    iconName: 'yard',
    professions: [
      CraftsmanProfession(id: 'garden', nameAr: 'حدائق وزراعة', groupId: 'garden_home'),
      CraftsmanProfession(id: 'cleaning', nameAr: 'خدمات نظافة', groupId: 'garden_home'),
      CraftsmanProfession(id: 'misc_finishing', nameAr: 'خدمات متنوعة وأعمال التشطيبات', groupId: 'garden_home'),
    ],
  ),
  CraftsmanCategoryGroup(
    id: 'technicians',
    nameAr: 'الفنيون',
    emoji: '🛠️',
    iconName: 'build',
    professions: [
      CraftsmanProfession(id: 'fridge_tech', nameAr: 'فني ثلاجات', groupId: 'technicians'),
      CraftsmanProfession(id: 'washer_tech', nameAr: 'فني غسالات', groupId: 'technicians'),
      CraftsmanProfession(id: 'stove_tech', nameAr: 'فني بوتاجازات', groupId: 'technicians'),
      CraftsmanProfession(id: 'tv_tech', nameAr: 'فني شاشات', groupId: 'technicians'),
      CraftsmanProfession(id: 'pc_tech', nameAr: 'فني كمبيوتر', groupId: 'technicians'),
      CraftsmanProfession(id: 'laptop_tech', nameAr: 'فني لابتوب', groupId: 'technicians'),
      CraftsmanProfession(id: 'mobile_tech', nameAr: 'فني موبايلات', groupId: 'technicians'),
      CraftsmanProfession(id: 'printer_tech', nameAr: 'فني طابعات', groupId: 'technicians'),
      CraftsmanProfession(id: 'network_tech', nameAr: 'فني شبكات', groupId: 'technicians'),
      CraftsmanProfession(id: 'pbx_tech', nameAr: 'فني سنترالات', groupId: 'technicians'),
    ],
  ),
  CraftsmanCategoryGroup(
    id: 'transport',
    nameAr: 'خدمات النقل',
    emoji: '🚚',
    iconName: 'local_shipping',
    professions: [
      CraftsmanProfession(id: 'furniture_move', nameAr: 'نقل أثاث', groupId: 'transport'),
      CraftsmanProfession(id: 'crane_lift', nameAr: 'ونش رفع أثاث', groupId: 'transport'),
      CraftsmanProfession(id: 'goods_move', nameAr: 'نقل بضائع', groupId: 'transport'),
      CraftsmanProfession(id: 'private_driver', nameAr: 'سائق خاص', groupId: 'transport'),
    ],
  ),
  CraftsmanCategoryGroup(
    id: 'personal_services',
    nameAr: 'خدمات شخصية',
    emoji: '👨‍🏫',
    iconName: 'person',
    professions: [
      CraftsmanProfession(id: 'tutor', nameAr: 'مدرس خصوصي', groupId: 'personal_services'),
      CraftsmanProfession(id: 'home_nurse', nameAr: 'ممرض منزلي', groupId: 'personal_services'),
      CraftsmanProfession(id: 'elder_care', nameAr: 'جليسة مسنين', groupId: 'personal_services'),
      CraftsmanProfession(id: 'pest_control', nameAr: 'مكافحة حشرات', groupId: 'personal_services'),
    ],
  ),
];

CraftsmanProfession? findProfessionById(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final g in kCraftsmanCategoryGroups) {
    for (final p in g.professions) {
      if (p.id == id) return p;
    }
  }
  return null;
}

String? findGroupNameById(String? groupId) {
  if (groupId == null) return null;
  for (final g in kCraftsmanCategoryGroups) {
    if (g.id == groupId) return g.nameAr;
  }
  return null;
}

CraftsmanCategoryGroup? findGroupById(String? groupId) {
  if (groupId == null) return null;
  for (final g in kCraftsmanCategoryGroups) {
    if (g.id == groupId) return g;
  }
  return null;
}

/// ربط اختصارات الصفحة الرئيسية بمعرّفات المهن الفعلية.
String? resolveProfessionIdFromShortcut(String shortcutId) {
  const mapping = {
    'plumber': 'plumber',
    'electric': 'electrician',
    'satellite': 'satellite_net',
    'teacher': 'tutor',
    'painter': 'painting_trade',
    'ac': 'ac',
    'carpenter': 'carpenter',
    'cleaning': 'cleaning',
  };
  return mapping[shortcutId];
}
