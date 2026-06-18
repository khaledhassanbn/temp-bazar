class WalletNotificationService {
  static final Map<String, bool> _shownNotifications = {};

  /// تفحص الرصيد وترسل التنبيه المناسب (يعود بنص التنبيه أو null إن لم يكن هناك تنبيه جديد)
  static String? checkBalanceAndNotify(double balance, double creditLimit) {
    if (balance <= creditLimit) {
      return _showOnce('credit_exceeded', 'تم تجاوز الحد الائتماني للمحفظة! لن يتم استقبال طلبات جديدة.');
    }
    if (balance < 0) {
      return _showOnce('negative', 'تنبيه: رصيد محفظتك أصبح سالب (${balance.toStringAsFixed(2)} جنيه)');
    }
    if (balance < 10) {
      return _showOnce('below_10', 'تنبيه: رصيد محفظتك أقل من 10 جنيه');
    }
    if (balance < 20) {
      return _showOnce('below_20', 'تنبيه: رصيد محفظتك أقل من 20 جنيه');
    }
    if (balance < 50) {
      return _showOnce('below_50', 'تنبيه: رصيد محفظتك أقل من 50 جنيه');
    }
    return null;
  }

  static String? _showOnce(String key, String message) {
    if (_shownNotifications[key] == true) return null;
    
    // عند تفعيل تنبيه معين، نقوم بمسح التنبيهات الأعلى منه للسماح بظهورها مجدداً إذا شحن المستخدم ثم قل الرصيد ثانية
    if (key == 'credit_exceeded') {
      _shownNotifications.clear();
    } else if (key == 'negative') {
      _shownNotifications.remove('credit_exceeded');
    } else if (key == 'below_10') {
      _shownNotifications.remove('negative');
      _shownNotifications.remove('credit_exceeded');
    } else if (key == 'below_20') {
      _shownNotifications.remove('below_10');
      _shownNotifications.remove('negative');
      _shownNotifications.remove('credit_exceeded');
    } else if (key == 'below_50') {
      _shownNotifications.remove('below_20');
      _shownNotifications.remove('below_10');
      _shownNotifications.remove('negative');
      _shownNotifications.remove('credit_exceeded');
    }
    
    _shownNotifications[key] = true;
    return message;
  }

  static void resetForNewBalance() {
    _shownNotifications.clear();
  }
}
