const { setGlobalOptions } = require("firebase-functions");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

// Initialize Admin SDK once
if (!admin.apps.length) {
  admin.initializeApp();
}

setGlobalOptions({ maxInstances: 10 });

// Scheduled function to expire markets based on expiredAt
exports.expireMarkets = onSchedule(
  {
      schedule: "0 0 * * *", // كل يوم الساعة 00:00
    timeZone: "Asia/Riyadh",
    memory: "256MiB",
    region: "europe-west1",
  },
  async (event) => {
    const db = getFirestore();
    const now = Timestamp.now();
    const batch = db.batch();

    try {
      // استعلام بشرط واحد فقط علشان نتجنب مشكلة الـ index
      const snapshot = await db
        .collection("markets")
        .where("expiredAt", "<=", now)
        .limit(400)
        .get();

      if (snapshot.empty) {
        logger.info("expireMarkets: No documents to update");
        return;
      }

      // فلترة في الكود بدل Firestore
      const docsToExpire = snapshot.docs.filter(
        (doc) => doc.data().status === "active"
      );

      docsToExpire.forEach((doc) => {
        batch.update(doc.ref, {
          status: "expired",
          isVisible: false,
          renewedAt: null,
          // storeStatus left untouched intentionally
        });
      });

      if (docsToExpire.length > 0) {
        await batch.commit();
        logger.info(`expireMarkets: Updated ${docsToExpire.length} markets`);
      } else {
        logger.info("expireMarkets: No active markets to expire");
      }
    } catch (error) {
      logger.error("expireMarkets failed", { error });
      throw error;
    }
  }
);
