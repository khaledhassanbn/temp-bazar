import '../../create_market/models/store_model.dart';

/// Service to manage local notifications for license expiration reminders.
/// Notifications are shown via a dialog/alert when the app is opened.
class LicenseNotificationService {
  // Static map to track shown notifications in current session
  static final Map<String, bool> _shownNotifications = {};

  /// Check if we should show a license expiration notification for the store.
  /// Returns a notification message if applicable, null otherwise.
  static String? checkAndShowNotification(StoreModel? store) {
    if (store == null) return null;

    // If license is already expired
    if (store.isLicenseExpired) {
      final key = '${store.id}_expired';
      if (_shownNotifications[key] == true) return null;
      _shownNotifications[key] = true;
      return 'انتهت صلاحية ترخيص متجرك "${store.name}"! لن يظهر المتجر للعملاء. جدد الآن!';
    }

    // Check if we're within warning period
    final daysLeft = store.daysUntilExpiry;

    // Only notify at specific thresholds: 7, 3, 1 days
    if (daysLeft == 7 || daysLeft == 3 || daysLeft == 1 || daysLeft == 0) {
      final key = '${store.id}_$daysLeft';
      if (_shownNotifications[key] == true) return null;
      _shownNotifications[key] = true;

      if (daysLeft == 0) {
        return 'تنبيه عاجل: ينتهي ترخيص "${store.name}" اليوم!';
      } else if (daysLeft == 1) {
        return 'تحذير: ينتهي ترخيص "${store.name}" غداً!';
      } else if (daysLeft == 3) {
        return 'تذكير: ينتهي ترخيص "${store.name}" خلال 3 أيام';
      } else if (daysLeft == 7) {
        return 'تذكير: ينتهي ترخيص "${store.name}" خلال أسبوع';
      }
    }

    return null;
  }

  /// Get the urgency level for styling purposes
  static NotificationUrgency getUrgency(int daysLeft) {
    if (daysLeft <= 1) return NotificationUrgency.critical;
    if (daysLeft <= 3) return NotificationUrgency.high;
    if (daysLeft <= 7) return NotificationUrgency.medium;
    return NotificationUrgency.low;
  }

  /// Clear shown notifications (useful for testing or on logout)
  static void clearShownNotifications() {
    _shownNotifications.clear();
  }
}

enum NotificationUrgency {
  low,
  medium,
  high,
  critical,
}
