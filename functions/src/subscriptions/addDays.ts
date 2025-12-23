/**
 * Callable Function: Add/Subtract Days to Store Subscription (Admin Only)
 * 
 * Allows admin to manually add or subtract days from a store's subscription.
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
 * Adds or subtracts days from a store's subscription
 * 
 * Request data:
 * - storeId: string (required) - The store document ID
 * - days: number (required) - Number of days to add (positive) or subtract (negative)
 * 
 * Returns:
 * {
 *   success: boolean
 *   message: string
 *   newExpiryDate: string (ISO format)
 * }
 */
export async function addDaysToStoreSubscription(
    request: CallableRequest
): Promise<{ success: boolean; message: string; newExpiryDate: string }> {
    try {
        // Verify admin access
        await verifyAdmin(request.auth?.uid);

        const { storeId, days } = request.data;

        if (!storeId || typeof storeId !== "string") {
            throw new HttpsError(
                "invalid-argument",
                "storeId is required and must be a string"
            );
        }

        if (days === undefined || typeof days !== "number") {
            throw new HttpsError(
                "invalid-argument",
                "days is required and must be a number"
            );
        }

        // Fetch store document
        const storeDoc = await db.collection("markets").doc(storeId).get();
        if (!storeDoc.exists) {
            throw new HttpsError("not-found", "Store not found");
        }

        const storeData = storeDoc.data()!;

        // Get current expiry date
        let currentExpiry: Date;
        const expiryTimestamp = storeData.expiryDate as Timestamp | undefined;
        const licenseEndAt = storeData.licenseEndAt as Timestamp | undefined;

        if (expiryTimestamp) {
            currentExpiry = expiryTimestamp.toDate();
        } else if (licenseEndAt) {
            currentExpiry = licenseEndAt.toDate();
        } else {
            // If no expiry date, start from now
            currentExpiry = new Date();
        }

        // Calculate new expiry date
        const newExpiry = new Date(currentExpiry);
        newExpiry.setDate(newExpiry.getDate() + days);
        const newExpiryTimestamp = Timestamp.fromDate(newExpiry);

        // Check if new expiry is in the past
        const now = new Date();
        const isActive = newExpiry > now;

        // Update store document
        await db.collection("markets").doc(storeId).update({
            expiryDate: newExpiryTimestamp,
            licenseEndAt: newExpiryTimestamp,
            isActive: isActive,
            canAddProducts: isActive,
            canReceiveOrders: isActive,
            status: isActive ? "active" : "expired",
            "subscription.endDate": newExpiryTimestamp,
        });

        const action = days > 0 ? "إضافة" : "طرح";
        const daysAbs = Math.abs(days);

        logger.info("addDaysToStoreSubscription: Days modified by admin", {
            storeId,
            days,
            previousExpiry: currentExpiry.toISOString(),
            newExpiry: newExpiry.toISOString(),
            adminUid: request.auth?.uid,
        });

        return {
            success: true,
            message: `تم ${action} ${daysAbs} يوم بنجاح`,
            newExpiryDate: newExpiry.toISOString(),
        };
    } catch (error) {
        if (error instanceof HttpsError) {
            throw error;
        }
        logger.error("addDaysToStoreSubscription: Unexpected error", { error });
        throw new HttpsError("internal", "Failed to modify subscription days");
    }
}
