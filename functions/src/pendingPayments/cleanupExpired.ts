/**
 * Scheduled Function: Cleanup Expired Pending Payments
 * 
 * This function runs every hour and deletes pending payments that have expired
 * (older than 24 hours) and returns the deducted amount to the user's wallet.
 */

import { ScheduledEvent } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";

// Ensure Admin SDK is initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const BATCH_SIZE = 100; // Process in batches to avoid memory issues

/**
 * Cleans up expired pending payments
 * - Finds all pending payments older than 24 hours
 * - Returns the deducted amount to user's wallet
 * - Deletes or marks as expired the pending payment
 */
export async function cleanupExpiredPendingPayments(
  event: ScheduledEvent
): Promise<void> {
  logger.info("cleanupExpiredPendingPayments: Starting cleanup");

  try {
    const now = Timestamp.now();
    const twentyFourHoursAgo = new Date(now.toMillis() - 24 * 60 * 60 * 1000);
    const expiryTimestamp = Timestamp.fromDate(twentyFourHoursAgo);

    let totalProcessed = 0;
    let totalExpired = 0;
    let totalRefunded = 0;
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;

    // Process in batches to handle large datasets
    // Note: We query by status first, then filter by createdAt in code
    // This avoids needing a composite index
    while (true) {
      let query = db
        .collection("pending_payments")
        .where("status", "==", "pending")
        .limit(BATCH_SIZE * 2); // Get more to filter by date

      // Use cursor for pagination
      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();
      
      // Filter by createdAt in memory
      const expiredDocs = snapshot.docs.filter((doc) => {
        const data = doc.data();
        const createdAt = data.createdAt as Timestamp | null;
        return createdAt && createdAt <= expiryTimestamp;
      });

      if (expiredDocs.length === 0) {
        // If no expired docs in this batch, check if we should continue
        if (snapshot.docs.length < BATCH_SIZE * 2) {
          logger.info(
            "cleanupExpiredPendingPayments: No more expired payments found"
          );
          break;
        }
        // Update cursor and continue
        lastDoc = snapshot.docs[snapshot.docs.length - 1];
        continue;
      }

      if (snapshot.empty) {
        logger.info(
          "cleanupExpiredPendingPayments: No more expired payments found"
        );
        break;
      }

      const batch = db.batch();
      let batchCount = 0;

      for (const doc of expiredDocs) {
        const data = doc.data();
        const userId = data.userId as string;
        const amount = (data.amount ?? 0.0) as number;
        const createdAt = data.createdAt as Timestamp | null;

        // Double-check expiry (in case of race conditions)
        if (
          createdAt &&
          createdAt <= expiryTimestamp &&
          data.status === "pending"
        ) {
          try {
            // Refund the amount to user's wallet
            if (amount > 0 && userId) {
              await db.collection("users").doc(userId).update({
                walletBalance: admin.firestore.FieldValue.increment(amount),
              });
              totalRefunded += amount;
            }

            // Mark payment as expired instead of deleting (for audit trail)
            batch.update(doc.ref, {
              status: "expired",
              expiredAt: now,
            });

            batchCount++;
            totalExpired++;
          } catch (error) {
            logger.error(
              `cleanupExpiredPendingPayments: Error processing payment ${doc.id}`,
              { error, userId, amount }
            );
            // Continue with other payments even if one fails
          }
        }
        totalProcessed++;
      }

      if (batchCount > 0) {
        await batch.commit();
        logger.info(
          `cleanupExpiredPendingPayments: Processed ${batchCount} expired payments in this batch`
        );
      }

      // Update cursor for next iteration
      lastDoc = snapshot.docs[snapshot.docs.length - 1];

      // If we got fewer results than expected, we're done
      if (snapshot.docs.length < BATCH_SIZE * 2) {
        break;
      }
    }

    logger.info("cleanupExpiredPendingPayments: Completed", {
      totalProcessed,
      totalExpired,
      totalRefunded,
    });
  } catch (error) {
    logger.error("cleanupExpiredPendingPayments: Error occurred", { error });
    throw error;
  }
}

