import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";
import { ScheduledEvent } from "firebase-functions/v2/scheduler";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const messaging = admin.messaging();
const TARGET_DAYS = [1, 2, 3];

export async function sendExpiryAlerts(
  event: ScheduledEvent
): Promise<void> {
  logger.info("sendExpiryAlerts: start");
  const now = Timestamp.now();
  const in3 = Timestamp.fromDate(
    new Date(Date.now() + 3 * 24 * 60 * 60 * 1000)
  );

  const snapshot = await db
    .collection("markets")
    .where("expiryDate", "<=", in3)
    .where("isActive", "==", true)
    .get();

  let alertsSent = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const expiry = data.expiryDate as Timestamp | undefined;
    const ownerId = data.ownerId as string | undefined;
    if (!expiry || !ownerId) continue;

    const diffMs = expiry.toMillis() - now.toMillis();
    const days = Math.ceil(diffMs / (1000 * 60 * 60 * 24));
    if (!TARGET_DAYS.includes(days)) continue;

    await doc.ref.set(
      {
        licenseAlertDaysRemaining: days,
        licenseAlertUpdatedAt: Timestamp.now(),
      },
      { merge: true }
    );

    try {
      const userDoc = await db.collection("users").doc(ownerId).get();
      const tokens = (userDoc.data()?.fcmTokens as string[]) ?? [];
      if (tokens.length > 0) {
        await messaging.sendEachForMulticast({
          tokens,
          notification: {
            title: "تنبيه ترخيص المتجر",
            body: `متبقي ${days} يوم قبل انتهاء ترخيص متجرك. جدده الآن.`,
          },
          data: {
            type: "license_alert",
            storeId: doc.id,
            remainingDays: String(days),
          },
        });
        alertsSent += tokens.length;
      }
    } catch (error) {
      logger.error("sendExpiryAlerts: push error", {
        storeId: doc.id,
        error,
      });
    }
  }

  logger.info("sendExpiryAlerts: done", { alertsSent });
}

