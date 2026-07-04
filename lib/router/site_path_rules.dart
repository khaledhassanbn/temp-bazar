// قواعد مسارات المشاركة العامة: [لينك المتجر] حروف صغيرة وأرقام وشرطة فقط،
// ولا يتعارض مع مسارات التطبيق الحرفية (مثل login، pricingpage).

final Set<String> _reservedStoreSlugSegments = {
  'login',
  'login-email',
  'register',
  'forgot-password',
  'user-orders',
  'store-reviews',
  'create-store',
  'addproduct',
  'myorder',
  'market-dashboard',
  'pricingpage',
  'request-ads',
  'my-ads',
  'wallet',
  'deposit-request',
  'productdetails',
  'delivery-addresses',
  'favourite-markets',
  'admin',
  'market',
  'craftsmen',
  'craftsman',
};

bool isStoreShareSlugSegment(String segment) {
  if (segment.isEmpty || segment.length > 80) return false;
  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(segment)) return false;
  return !_reservedStoreSlugSegments.contains(segment);
}

bool isProductShareItemSegment(String segment) {
  if (segment.isEmpty || segment.length > 200) return false;
  return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(segment);
}

bool isPublicProductSharePath(String marketSegment, String itemSegment) {
  return isStoreShareSlugSegment(marketSegment) &&
      isProductShareItemSegment(itemSegment);
}
