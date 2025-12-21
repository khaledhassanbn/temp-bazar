"use strict";
/**
 * Scheduled Function: Check Expired Subscriptions
 *
 * Runs every hour to find and disable expired store subscriptions.
 * Sets isActive, canAddProducts, and canReceiveOrders to false.
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
exports.checkExpiredSubscriptions = checkExpiredSubscriptions;
const logger = __importStar(require("firebase-functions/logger"));
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-admin/firestore");
// Ensure Admin SDK is initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
const BATCH_SIZE = 400; // Firestore batch limit is 500, using 400 for safety
/**
 * Checks for expired subscriptions and disables them
 */
async function checkExpiredSubscriptions(event) {
    logger.info("checkExpiredSubscriptions: Starting scheduled check");
    try {
        const now = firestore_1.Timestamp.now();
        let totalProcessed = 0;
        let totalExpired = 0;
        let lastDoc = null;
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
                const expiryDate = data.expiryDate;
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
                logger.info(`checkExpiredSubscriptions: Disabled ${batchCount} expired stores in this batch`);
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
    }
    catch (error) {
        logger.error("checkExpiredSubscriptions: Error occurred", { error });
        throw error;
    }
}
//# sourceMappingURL=checkExpired.js.map