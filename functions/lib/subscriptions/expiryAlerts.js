"use strict";
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
exports.sendExpiryAlerts = sendExpiryAlerts;
const logger = __importStar(require("firebase-functions/logger"));
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-admin/firestore");
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
const messaging = admin.messaging();
const TARGET_DAYS = [1, 2, 3];
async function sendExpiryAlerts(event) {
    logger.info("sendExpiryAlerts: start");
    const now = firestore_1.Timestamp.now();
    const in3 = firestore_1.Timestamp.fromDate(new Date(Date.now() + 3 * 24 * 60 * 60 * 1000));
    const snapshot = await db
        .collection("markets")
        .where("expiryDate", "<=", in3)
        .where("isActive", "==", true)
        .get();
    let alertsSent = 0;
    for (const doc of snapshot.docs) {
        const data = doc.data();
        const expiry = data.expiryDate;
        const ownerId = data.ownerId;
        if (!expiry || !ownerId)
            continue;
        const diffMs = expiry.toMillis() - now.toMillis();
        const days = Math.ceil(diffMs / (1000 * 60 * 60 * 24));
        if (!TARGET_DAYS.includes(days))
            continue;
        await doc.ref.set({
            licenseAlertDaysRemaining: days,
            licenseAlertUpdatedAt: firestore_1.Timestamp.now(),
        }, { merge: true });
        try {
            const userDoc = await db.collection("users").doc(ownerId).get();
            const tokens = userDoc.data()?.fcmTokens ?? [];
            if (tokens.length > 0) {
                await messaging.sendEachForMulticast({
                    tokens,
                    notification: {
                        title: "تنبيه ترخيص المتجر",
                        body: `متبقي ${days} يوم قبل انتهاء ترخيص متجرك. جدده الآن.`,
                    },
                    data: {
                        type: "license_alert",
                        storeId: doc.id,
                        remainingDays: String(days),
                    },
                });
                alertsSent += tokens.length;
            }
        }
        catch (error) {
            logger.error("sendExpiryAlerts: push error", {
                storeId: doc.id,
                error,
            });
        }
    }
    logger.info("sendExpiryAlerts: done", { alertsSent });
}
//# sourceMappingURL=expiryAlerts.js.map