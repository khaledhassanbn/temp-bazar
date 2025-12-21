/**
 * Callable Function: Renew Store Subscription (Admin Only)
 * 
 * Allows admin to manually renew a store's subscription with any package.
 */

import { CallableRequest, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";
import { verifyAdmin } from "../utils/auth";

// Ensure Admin SDK is initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Renews a store's subscription with a specific package
 * 
 * Request data:
 * - storeId: string (required) - The store document ID
 * - packageId: string (required) - The package document ID
 * 
 * Returns:
 * {
 *   success: boolean
 *   message: string
 *   expiryDate: string (ISO format)
 * }
 */
export async function renewStoreSubscription(
  request: CallableRequest
): Promise<{ success: boolean; message: string; expiryDate: string }> {
  try {
    // Verify admin access
    await verifyAdmin(request.auth?.uid);

    const { storeId, packageId } = request.data;

    if (!storeId || typeof storeId !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "storeId is required and must be a string"
      );
    }

    if (!packageId || typeof packageId !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "packageId is required and must be a string"
      );
    }

    // Fetch package data
    const packageDoc = await db.collection("packages").doc(packageId).get();
    if (!packageDoc.exists) {
      throw new HttpsError("not-found", "Package not found");
    }

    const packageData = packageDoc.data()!;
    const days = packageData.days as number;
    const packageName = packageData.name as string;

    // Fetch store document
    const storeDoc = await db.collection("markets").doc(storeId).get();
    if (!storeDoc.exists) {
      throw new HttpsError("not-found", "Store not found");
    }

    // Calculate expiry date
    const now = Timestamp.now();
    const expiryDate = new Date(now.toMillis());
    expiryDate.setDate(expiryDate.getDate() + days);
    const expiryTimestamp = Timestamp.fromDate(expiryDate);

    const startDate = now;
    const endDate = expiryTimestamp;

    // Update store with subscription data
    await db.collection("markets").doc(storeId).update({
      isActive: true,
      expiryDate: expiryTimestamp,
      canAddProducts: true,
      canReceiveOrders: true,
      subscription: {
        packageName: packageName,
        startDate: startDate,
        endDate: endDate,
        durationDays: days,
      },
      deactivatedAt: null, // Clear deactivation
      status: "active", // Ensure status is active
      isVisible: true, // Make store visible
    });

    logger.info("renewStoreSubscription: Subscription renewed by admin", {
      storeId,
      packageId,
      packageName,
      expiryDate: expiryTimestamp.toDate().toISOString(),
      adminUid: request.auth?.uid,
    });

    return {
      success: true,
      message: "تم تجديد الاشتراك بنجاح",
      expiryDate: expiryTimestamp.toDate().toISOString(),
    };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error("renewStoreSubscription: Unexpected error", { error });
    throw new HttpsError("internal", "Failed to renew subscription");
  }
}

