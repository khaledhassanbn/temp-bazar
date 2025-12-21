"use strict";
/**
 * Callable Function: Renew Store Subscription (Admin Only)
 *
 * Allows admin to manually renew a store's subscription with any package.
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
exports.renewStoreSubscription = renewStoreSubscription;
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
async function renewStoreSubscription(request) {
    try {
        // Verify admin access
        await (0, auth_1.verifyAdmin)(request.auth?.uid);
        const { storeId, packageId } = request.data;
        if (!storeId || typeof storeId !== "string") {
            throw new https_1.HttpsError("invalid-argument", "storeId is required and must be a string");
        }
        if (!packageId || typeof packageId !== "string") {
            throw new https_1.HttpsError("invalid-argument", "packageId is required and must be a string");
        }
        // Fetch package data
        const packageDoc = await db.collection("packages").doc(packageId).get();
        if (!packageDoc.exists) {
            throw new https_1.HttpsError("not-found", "Package not found");
        }
        const packageData = packageDoc.data();
        const days = packageData.days;
        const packageName = packageData.name;
        // Fetch store document
        const storeDoc = await db.collection("markets").doc(storeId).get();
        if (!storeDoc.exists) {
            throw new https_1.HttpsError("not-found", "Store not found");
        }
        // Calculate expiry date
        const now = firestore_1.Timestamp.now();
        const expiryDate = new Date(now.toMillis());
        expiryDate.setDate(expiryDate.getDate() + days);
        const expiryTimestamp = firestore_1.Timestamp.fromDate(expiryDate);
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
    }
    catch (error) {
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        logger.error("renewStoreSubscription: Unexpected error", { error });
        throw new https_1.HttpsError("internal", "Failed to renew subscription");
    }
}
//# sourceMappingURL=renewSubscription.js.map