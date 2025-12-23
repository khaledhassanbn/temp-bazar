/**
 * Callable Function: Suspend Store Subscription (Admin Only)
 * 
 * Allows admin to manually suspend/deactivate a store's subscription.
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
 * Suspends a store's subscription
 * 
 * Request data:
 * - storeId: string (required) - The store document ID
 * 
 * Returns:
 * {
 *   success: boolean
 *   message: string
 * }
 */
export async function suspendStoreSubscription(
    request: CallableRequest
): Promise<{ success: boolean; message: string }> {
    try {
        // Verify admin access
        await verifyAdmin(request.auth?.uid);

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

        const now = Timestamp.now();

        // Update store document to suspended state
        await db.collection("markets").doc(storeId).update({
            isActive: false,
            canAddProducts: false,
            canReceiveOrders: false,
            status: "suspended",
            isVisible: false,
            suspendedAt: now,
            suspendedBy: request.auth?.uid,
        });

        logger.info("suspendStoreSubscription: Store suspended by admin", {
            storeId,
            adminUid: request.auth?.uid,
            suspendedAt: now.toDate().toISOString(),
        });

        return {
            success: true,
            message: "تم إيقاف ترخيص المتجر بنجاح",
        };
    } catch (error) {
        if (error instanceof HttpsError) {
            throw error;
        }
        logger.error("suspendStoreSubscription: Unexpected error", { error });
        throw new HttpsError("internal", "Failed to suspend subscription");
    }
}
