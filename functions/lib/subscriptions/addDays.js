"use strict";
/**
 * Callable Function: Add/Subtract Days to Store Subscription (Admin Only)
 *
 * Allows admin to manually add or subtract days from a store's subscription.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.addDaysToStoreSubscription = addDaysToStoreSubscription;
const https_1 = require("firebase-functions/v2/https");
const logger = __importStar(require("firebase-functions/logger"));
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("../utils/auth");
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
async function addDaysToStoreSubscription(request) {
    try {
        // Verify admin access
        await (0, auth_1.verifyAdmin)(request.auth?.uid);
        const { storeId, days } = request.data;
        if (!storeId || typeof storeId !== "string") {
            throw new https_1.HttpsError("invalid-argument", "storeId is required and must be a string");
        }
        if (days === undefined || typeof days !== "number") {
            throw new https_1.HttpsError("invalid-argument", "days is required and must be a number");
        }
        // Fetch store document
        const storeDoc = await db.collection("markets").doc(storeId).get();
        if (!storeDoc.exists) {
            throw new https_1.HttpsError("not-found", "Store not found");
        }
        const storeData = storeDoc.data();
        // Get current expiry date
        let currentExpiry;
        const expiryTimestamp = storeData.expiryDate;
        const licenseEndAt = storeData.licenseEndAt;
        if (expiryTimestamp) {
            currentExpiry = expiryTimestamp.toDate();
        }
        else if (licenseEndAt) {
            currentExpiry = licenseEndAt.toDate();
        }
        else {
            // If no expiry date, start from now
            currentExpiry = new Date();
        }
        // Calculate new expiry date
        const newExpiry = new Date(currentExpiry);
        newExpiry.setDate(newExpiry.getDate() + days);
        const newExpiryTimestamp = firestore_1.Timestamp.fromDate(newExpiry);
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
    }
    catch (error) {
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        logger.error("addDaysToStoreSubscription: Unexpected error", { error });
        throw new https_1.HttpsError("internal", "Failed to modify subscription days");
    }
}
//# sourceMappingURL=addDays.js.map