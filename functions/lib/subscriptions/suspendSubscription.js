"use strict";
/**
 * Callable Function: Suspend Store Subscription (Admin Only)
 *
 * Allows admin to manually suspend/deactivate a store's subscription.
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
exports.suspendStoreSubscription = suspendStoreSubscription;
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
async function suspendStoreSubscription(request) {
    try {
        // Verify admin access
        await (0, auth_1.verifyAdmin)(request.auth?.uid);
        const { storeId } = request.data;
        if (!storeId || typeof storeId !== "string") {
            throw new https_1.HttpsError("invalid-argument", "storeId is required and must be a string");
        }
        // Fetch store document
        const storeDoc = await db.collection("markets").doc(storeId).get();
        if (!storeDoc.exists) {
            throw new https_1.HttpsError("not-found", "Store not found");
        }
        const now = firestore_1.Timestamp.now();
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
    }
    catch (error) {
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        logger.error("suspendStoreSubscription: Unexpected error", { error });
        throw new https_1.HttpsError("internal", "Failed to suspend subscription");
    }
}
//# sourceMappingURL=suspendSubscription.js.map