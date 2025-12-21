# فولدر صور الفئات

هذا الفولدر يحتوي على صور الفئات المستخدمة في التطبيق.

## كيفية إضافة صور جديدة:

1. ضع الصورة في هذا الفولدر (`assets/images/categories/`)
2. افتح ملف `lib/admin/categories/create_edit_category_page.dart`
3. في دالة `_loadAvailableImages()`، أضف اسم الصورة إلى قائمة `staticImages`:

```dart
const List<String> staticImages = [
  'category1.png',      // اسم الصورة الجديدة
  'category2.jpg',
  'food.png',
  // أضف هنا...
];
```

4. تأكد من أن الصور محددة في `pubspec.yaml` تحت:
```yaml
assets:
  - assets/images/categories/
```

5. قم بتشغيل `flutter pub get` أو أعد تشغيل التطبيق

## ملاحظات:

- الصور المدعومة: `.png`, `.jpg`, `.jpeg`
- يفضل استخدام صور بحجم مناسب (مثلاً 200x200 بكسل)
- عند إضافة فئة جديدة، يمكنك اختيار صورة من الصور الموجودة في هذا الفولدر
- اسم الصورة سُيحفظ في قاعدة البيانات بدلاً من رابط Firebase

