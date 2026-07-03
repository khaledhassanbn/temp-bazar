class CategoryModel {
  final String id;
  final String name;
  final int order;
  final String icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.order,
    required this.icon,
  });

  /// كل ملفات الصور الموجودة في `assets/images/categories/`
  static const List<String> _allAssetFiles = [
    'Accessories.png',
    'animal.png',
    'cars.png',
    'clothes.png',
    'cosmatics.png',
    'electric.png',
    'fabrics.png',
    'florist.png',
    'food.png',
    'furniture.png',
    'home_tools.png',
    'laptop.png',
    'nuts.png',
    'perfumes.png',
    'pharmacy.png',
    'phones.png',
    'sebaka.png',
    'service.png',
    'shcool.png',
    'supermarket.png',
    'tourism.png',
  ];

  static const Map<String, String> _assetFileNames = {
    'accessories': 'Accessories.png',
    'animal': 'animal.png',
    'cars': 'cars.png',
    'clothes': 'clothes.png',
    'cosmatics': 'cosmatics.png',
    'cosmetics': 'cosmatics.png',
    'cosmatic': 'cosmatics.png',
    'cosmetic': 'cosmatics.png',
    'electric': 'electric.png',
    'electronic': 'electric.png',
    'electronics': 'electric.png',
    'fabrics': 'fabrics.png',
    'textiles': 'fabrics.png',
    'textile': 'fabrics.png',
    'florist': 'florist.png',
    'flowers': 'florist.png',
    'flower': 'florist.png',
    'food': 'food.png',
    'furniture': 'furniture.png',
    'home_tools': 'home_tools.png',
    'household': 'home_tools.png',
    'laptop': 'laptop.png',
    'computer': 'laptop.png',
    'nuts': 'nuts.png',
    'perfumes': 'perfumes.png',
    'perfume': 'perfumes.png',
    'pharmacy': 'pharmacy.png',
    'phones': 'phones.png',
    'sebaka': 'sebaka.png',
    'school': 'shcool.png',
    'shcool': 'shcool.png',
    'service': 'service.png',
    'services': 'service.png',
    'supermarket': 'supermarket.png',
    'tourism': 'tourism.png',
    'travel': 'tourism.png',
  };

  static String? _matchKnownAssetFile(String fileName) {
    final lower = fileName.toLowerCase();
    for (final asset in _allAssetFiles) {
      if (asset.toLowerCase() == lower) return asset;
    }
    return null;
  }

  static String? _resolveDirectAssetIcon(String icon) {
    if (icon.isEmpty) return null;
    if (icon.startsWith('http://') || icon.startsWith('https://')) {
      return null;
    }

    final baseName = icon
        .replaceAll(
          RegExp(r'^assets/images/categories/', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\.(png|jpg|jpeg)$', caseSensitive: false), '')
        .toLowerCase();

    final normalized = _assetFileNames[baseName];
    if (normalized != null) return normalized;

    return _matchKnownAssetFile(icon);
  }

  static String _resolveCategoryIcon({
    required String rawIcon,
    required String name,
    required String docId,
  }) {
    final icon = rawIcon.trim();
    final searchText = '$icon $name $docId'.toLowerCase();

    // أولاً: اسم ملف محلي صريح في حقل icon (مثل cosmatics أو cosmatics.png)
    final directAsset = _resolveDirectAssetIcon(icon);
    if (directAsset != null) return directAsset;

    // ثانياً: الربط من الاسم العربي/الإنجليزي أو الـ docId
    final fromKeywords = _matchByKeywords(searchText);
    if (fromKeywords != null) return fromKeywords;

    // ثالثاً: رابط Firebase
    if (icon.startsWith('http://') || icon.startsWith('https://')) {
      return icon;
    }

    return icon;
  }

  static String? _matchByKeywords(String searchText) {
    if (_containsAny(searchText, [
      'home_tools',
      'household',
      'أدوات منزل',
      'ادوات منزل',
      'منزلية',
      'منزليه',
    ])) {
      return 'home_tools.png';
    }
    if (_containsAny(searchText, [
      'fabrics',
      'textile',
      'textiles',
      'منسوج',
      'أقمشة',
      'اقمشة',
      'قماش',
    ])) {
      return 'fabrics.png';
    }
    if (_containsAny(searchText, [
      'service',
      'services',
      'خدمات',
      'خدمة',
    ])) {
      return 'service.png';
    }
    if (_containsAny(searchText, [
      'tourism',
      'travel',
      'سياح',
      'سفر',
      'رحلات',
    ])) {
      return 'tourism.png';
    }
    if (_containsAny(searchText, [
      'florist',
      'flowers',
      'flower',
      'ورد',
      'ورود',
      'زهور',
    ])) {
      return 'florist.png';
    }
    if (_containsAny(searchText, [
      'shcool',
      'school',
      'مكتب',
      'مدرس',
      'أدوات مدرس',
      'ادوات مدرس',
      'مستلزمات مدرس',
      'قرطاسية',
    ])) {
      return 'shcool.png';
    }
    if (_containsAny(searchText, [
      'cosmatic',
      'cosmetic',
      'cosmatics',
      'cosmetics',
      'makeup',
      'beauty',
      'تجميل',
      'مكياج',
      'كوزمتك',
      'مستحضر',
      'مستلزمات تجميل',
    ])) {
      return 'cosmatics.png';
    }
    if (_containsAny(searchText, ['perfume', 'perfumes', 'عطر', 'عطور'])) {
      return 'perfumes.png';
    }
    if (_containsAny(searchText, [
      'electric',
      'electronic',
      'electronics',
      'كهربائ',
      'أجهزة كهرب',
      'اجهزة كهرب',
      'أدوات كهرب',
    ])) {
      return 'electric.png';
    }
    if (_containsAny(searchText, [
      'accessory',
      'accessories',
      'أكسسوار',
      'اكسسوار',
      'حقائب',
    ])) {
      return 'Accessories.png';
    }
    if (_containsAny(searchText, ['furniture', 'أثاث', 'اثاث', 'موبيليا', 'مفروشات'])) {
      return 'furniture.png';
    }
    if (_containsAny(searchText, [
      'laptop',
      'computer',
      'كمبيوتر',
      'لابتوب',
      'حاسوب',
      'pc',
    ])) {
      return 'laptop.png';
    }
    if (_containsAny(searchText, ['supermarket', 'سوبر', 'بقالة', 'ماركت'])) {
      return 'supermarket.png';
    }
    if (_containsAny(searchText, ['pharmacy', 'صيدل', 'دواء', 'أدوية'])) {
      return 'pharmacy.png';
    }
    if (_containsAny(searchText, ['phone', 'phones', 'موبايل', 'هاتف', 'جوالات'])) {
      return 'phones.png';
    }
    if (_containsAny(searchText, ['car', 'cars', 'سيارات', 'سيارة'])) {
      return 'cars.png';
    }
    if (_containsAny(searchText, ['food', 'طعام', 'أكل', 'مطاعم', 'مأكولات'])) {
      return 'food.png';
    }
    if (_containsAny(searchText, ['animal', 'حيوان', 'حيوانات', 'أليف'])) {
      return 'animal.png';
    }
    if (_containsAny(searchText, ['nut', 'nuts', 'مكسرات', 'فواكه مجفف'])) {
      return 'nuts.png';
    }
    if (_containsAny(searchText, ['sebaka', 'سباكة', 'سباك', 'مواسير'])) {
      return 'sebaka.png';
    }
    if (_containsAny(searchText, ['clothes', 'cloth', 'ملابس', 'أزياء', 'ازياء'])) {
      return 'clothes.png';
    }

    return null;
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword.toLowerCase())) return true;
    }
    return false;
  }

  factory CategoryModel.fromFirestore(Map<String, dynamic> data, String docId) {
    final String resolvedName =
        (data['name_ar'] ?? data['name'] ?? data['name_en'] ?? '') as String;

    final String rawIcon = (data['icon'] ?? '') as String;
    final String mappedIcon = _resolveCategoryIcon(
      rawIcon: rawIcon,
      name: resolvedName,
      docId: docId,
    );

    return CategoryModel(
      id: docId,
      name: resolvedName,
      order: (data['order'] ?? 0) as int,
      icon: mappedIcon,
    );
  }
}
