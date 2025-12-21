"use strict";
/**
 * Callable Function: Check Store Status
 *
 * Returns the current subscription status of a store.
 * Used by Flutter app to determine if store can add products, receive orders, etc.
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
exports.checkStoreStatus = checkStoreStatus;
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
async function checkStoreStatus(request) {
    try {
        // Verify authentication
        await (0, auth_1.verifyAuth)(request.auth?.uid);
        // Get storeId from request
        const { storeId } = request.data;
        if (!storeId || typeof storeId !== "string") {
            throw new https_1.HttpsError("invalid-argument", "storeId is required and must be a string");
        }
        // Fetch store document
        const storeDoc = await db.collection("markets").doc(storeId).get();
        if (!storeDoc.exists) {
            throw new https_1.HttpsError("not-found", "Store not found");
        }
        const storeData = storeDoc.data();
        const expiryDate = storeData.expiryDate;
        const isActive = storeData.isActive === true;
        const subscription = storeData.subscription || {};
        // Calculate remaining days
        let remainingDays = 0;
        if (expiryDate) {
            const now = firestore_1.Timestamp.now();
            const diffMs = expiryDate.toMillis() - now.toMillis();
            remainingDays = Math.max(0, Math.ceil(diffMs / (1000 * 60 * 60 * 24)));
        }
        // Determine if renewal is needed (expired or expiring soon - within 7 days)
        const needsRenewal = !isActive || remainingDays <= 7;
        // Format dates for response
        const formatDate = (timestamp) => {
            if (!timestamp)
                return null;
            return timestamp.toDate().toISOString();
        };
        const response = {
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
    }
    catch (error) {
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        logger.error("checkStoreStatus: Unexpected error", { error });
        throw new https_1.HttpsError("internal", "Failed to check store status");
    }
}
//# sourceMappingURL=checkStatus.js.map