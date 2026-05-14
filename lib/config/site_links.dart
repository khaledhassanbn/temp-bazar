/// روابط الموقع العامة (مشاركة الويب — يجب أن تطابق الدومين المستضاف).
const String kPublicSiteOrigin = 'https://bazaarsuez.com';

String publicStoreShareUrl(String storeLink) => '$kPublicSiteOrigin/$storeLink';

String publicProductShareUrl(String storeLink, String itemId) =>
    '$kPublicSiteOrigin/$storeLink/$itemId';
