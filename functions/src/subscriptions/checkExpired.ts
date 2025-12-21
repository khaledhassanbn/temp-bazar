/**
 * Scheduled Function: Check Expired Subscriptions
 * 
 * Runs every hour to find and disable expired store subscriptions.
 * Sets isActive, canAddProducts, and canReceiveOrders to false.
 */

import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";
import { ScheduledEvent } from "firebase-functions/v2/scheduler";

// Ensure Admin SDK is initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const BATCH_SIZE = 400; // Firestore batch limit is 500, using 400 for safety

/**
 * Checks for expired subscriptions and disables them
 */
export async function checkExpiredSubscriptions(
  event: ScheduledEvent
): Promise<void> {
  logger.info("checkExpiredSubscriptions: Starting scheduled check");

  try {
    const now = Timestamp.now();
    let totalProcessed = 0;
    let totalExpired = 0;
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;

    // Process in batches to handle large datasets
    while (true) {
      let query = db
        .collection("markets")
        .where("expiryDate", "<=", now)
        .where("isActive", "==", true)
        .limit(BATCH_SIZE);

      // Use cursor for pagination
      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();

      if (snapshot.empty) {
        logger.info("checkExpiredSubscriptions: No more expired stores found");
        break;
      }

      const batch = db.batch();
      let batchCount = 0;

      snapshot.docs.forEach((doc) => {
        const data = doc.data();
        const expiryDate = data.expiryDate as Timestamp | null;

        // Double-check expiry (in case of race conditions)
        if (expiryDate && expiryDate <= now && data.isActive === true) {
          batch.update(doc.ref, {
            isActive: false,
            canAddProducts: false,
            canReceiveOrders: false,
            deactivatedAt: now,
            status: "expired",
            isVisible: false, // Hide from public listings
          });
          batchCount++;
          totalExpired++;
        }
        totalProcessed++;
      });

      if (batchCount > 0) {
        await batch.commit();
        logger.info(
          `checkExpiredSubscriptions: Disabled ${batchCount} expired stores in this batch`
        );
      }

      // Update cursor for next iteration
      lastDoc = snapshot.docs[snapshot.docs.length - 1];

      // If we got fewer results than the limit, we're done
      if (snapshot.docs.length < BATCH_SIZE) {
        break;
      }
    }

    logger.info("checkExpiredSubscriptions: Completed", {
      totalProcessed,
      totalExpired,
    });
  } catch (error) {
    logger.error("checkExpiredSubscriptions: Error occurred", { error });
    throw error;
  }
}

