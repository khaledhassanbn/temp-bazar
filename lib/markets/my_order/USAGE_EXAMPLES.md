# مثال على استخدام نظام إدارة الطلبات

## 1. إضافة الصفحة إلى التطبيق

### في ملف التوجيه (routing)
```dart
// إضافة مسار جديد للطلبات
GoRoute(
  path: '/market-orders/:marketId',
  builder: (context, state) {
    final marketId = state.pathParameters['marketId']!;
    return MarketOrdersPage(marketId: marketId);
  },
),
```

### في صفحة المتجر الرئيسية
```dart
// إضافة زر للوصول إلى الطلبات
ElevatedButton.icon(
  onPressed: () {
    context.push('/market-orders/$marketId');
  },
  icon: const Icon(Icons.shopping_cart),
  label: const Text('إدارة الطلبات'),
),
```

## 2. مثال على بيانات الطلب في Firebase

```json
{
  "orderId": "MARKET_2501011200_ABC123",
  "createdAt": "2025-01-01T12:00:00Z",
  "status": "pending",
  "customerInfo": {
    "name": "أحمد محمد",
    "phone": "01012345678",
    "address": "شارع الثورة - السويس",
    "location": {
      "lat": 29.9668,
      "lng": 32.5498
    }
  },
  "items": [
    {
      "productId": "prod_001",
      "productName": "بيتزا مارغريتا",
      "productImage": "https://example.com/pizza.jpg",
      "quantity": 2,
      "unitPrice": 75.0,
      "totalPrice": 150.0,
      "selectedOptions": ["جبنة زيادة", "فلفل حار"]
    },
    {
      "productId": "prod_002", 
      "productName": "بيبسي",
      "quantity": 1,
      "unitPrice": 15.0,
      "totalPrice": 15.0,
      "selectedOptions": []
    }
  ],
  "subtotal": 165.0,
  "deliveryFee": 10.0,
  "serviceFee": 8.25,
  "totalAmount": 183.25
}
```

## 3. مثال على تغيير حالة الطلب

```dart
// في OrderActionButtons.dart
void _confirmAction(BuildContext context, String message, String newStatus) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("تأكيد العملية"),
      content: Text(message),
      actions: [
        TextButton(
          child: const Text("إلغاء"),
          onPressed: () => Navigator.pop(ctx),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.mainColor),
          child: const Text("تأكيد"),
          onPressed: () {
            Navigator.pop(ctx);
            onStatusChange(newStatus); // سيتم استدعاء _updateOrderStatus
          },
        ),
      ],
    ),
  );
}
```

## 4. مثال على البحث

```dart
// البحث برقم الطلب
searchQuery = "MARKET_2501011200_ABC123"
// النتيجة: سيظهر الطلب المطابق

// البحث باسم العميل
searchQuery = "أحمد"
// النتيجة: سيظهر جميع الطلبات للعملاء الذين يحتوي اسمهم على "أحمد"

// البحث بدون نتائج
searchQuery = "غير موجود"
// النتيجة: رسالة "لا توجد طلبات مطابقة للبحث"
```

## 5. مثال على الإحصائيات

```dart
// إذا كان لديك 10 طلبات:
// - 3 قيد المراجعة
// - 4 تم استلامها
// - 2 جاهزة للتسليم
// - 1 تم التسليم

// ستظهر الإحصائيات كالتالي:
// [3] قيد المراجعة    [4] مستلمة
// [2] جاهزة للتسليم   [1] تم التسليم
```

## 6. مثال على معالجة الأخطاء

```dart
// خطأ في الاتصال
if (snapshot.hasError) {
  return SliverFillRemaining(
    child: Center(
      child: Column(
        children: [
          Icon(Icons.error, size: 64, color: Colors.red),
          Text('خطأ في تحميل الطلبات'),
          Text(snapshot.error.toString()),
          ElevatedButton(
            onPressed: _setupOrdersStream, // إعادة المحاولة
            child: Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );
}
```

## 7. مثال على التحديث التلقائي

```dart
// عند إضافة طلب جديد في Firebase:
// 1. Firebase Stream يتلقى التحديث
// 2. يتم تحويل البيانات الجديدة
// 3. يتم إضافة الطلب الجديد للقائمة
// 4. يتم تحديث الإحصائيات
// 5. يتم عرض الطلب مع رسوم متحركة
```

## 8. مثال على الأذونات المطلوبة في Firebase

```javascript
// قواعد الأمان في Firebase
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // السماح للمتاجر بقراءة وكتابة طلباتها فقط
    match /markets/{marketId}/present_order/{orderId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.marketOwnerId;
    }
  }
}
```

## 9. مثال على الاختبار

```dart
// اختبار بسيط للتأكد من عمل النظام
void testOrderStatusUpdate() {
  // إنشاء طلب تجريبي
  final testOrder = {
    'id': 'TEST_001',
    'status': 'قيد المراجعة',
    'customerName': 'عميل تجريبي',
    // ... باقي البيانات
  };
  
  // تغيير الحالة
  onStatusChange('تم استلام الطلب');
  
  // التحقق من التحديث
  assert(testOrder['status'] == 'تم استلام الطلب');
}
```

