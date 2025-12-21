/**
 * Callable Function: Check Store Status
 * 
 * Returns the current subscription status of a store.
 * Used by Flutter app to determine if store can add products, receive orders, etc.
 */

import { CallableRequest, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";
import { verifyAuth } from "../utils/auth";
import { StoreStatusResponse } from "../types";

// Ensure Admin SDK is initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Checks the subscription status of a store
 * 
 * Request data:
 * - storeId: string (required) - The store document ID
 * 
 * Returns:
 * {
 *   isActive: boolean
 *   needsRenewal: boolean
 *   expiryDate: string | null (ISO format)
 *   remainingDays: number
 *   subscription: {
 *     packageName: string | null
 *     startDate: string | null (ISO format)
 *     endDate: string | null (ISO format)
 *     durationDays: number | null
 *   }
 * }
 */
export async function checkStoreStatus(
  request: CallableRequest
): Promise<StoreStatusResponse> {
  try {
    // Verify authentication
    await verifyAuth(request.auth?.uid);

    // Get storeId from request
    const { storeId } = request.data;

    if (!storeId || typeof storeId !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "storeId is required and must be a string"
      );
    }

    // Fetch store document
    const storeDoc = await db.collection("markets").doc(storeId).get();

    if (!storeDoc.exists) {
      throw new HttpsError("not-found", "Store not found");
    }

    const storeData = storeDoc.data()!;
    const expiryDate = storeData.expiryDate as Timestamp | null;
    const isActive = storeData.isActive === true;
    const subscription = storeData.subscription || {};

    // Calculate remaining days
    let remainingDays = 0;
    if (expiryDate) {
      const now = Timestamp.now();
      const diffMs = expiryDate.toMillis() - now.toMillis();
      remainingDays = Math.max(0, Math.ceil(diffMs / (1000 * 60 * 60 * 24)));
    }

    // Determine if renewal is needed (expired or expiring soon - within 7 days)
    const needsRenewal = !isActive || remainingDays <= 7;

    // Format dates for response
    const formatDate = (timestamp: Timestamp | null): string | null => {
      if (!timestamp) return null;
      return timestamp.toDate().toISOString();
    };

    const response: StoreStatusResponse = {
      isActive,
      needsRenewal,
      expiryDate: formatDate(expiryDate),
      remainingDays,
      subscription: {
        packageName: subscription.packageName || null,
        startDate: formatDate(subscription.startDate),
        endDate: formatDate(subscription.endDate),
        durationDays: subscription.durationDays || null,
      },
    };

    logger.info("checkStoreStatus: Status retrieved", {
      storeId,
      isActive,
      remainingDays,
    });

    return response;
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error("checkStoreStatus: Unexpected error", { error });
    throw new HttpsError("internal", "Failed to check store status");
  }
}

