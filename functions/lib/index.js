"use strict";
/**
 * Firebase Cloud Functions - Store Subscription System
 *
 * This module provides:
 * - Paymob webhook integration for subscription renewals
 * - Facebook Data Deletion callback
 * - Scheduled function for cleanup and auto-renewal
 * - Order notifications (new order, status changes)
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
exports.sendPastOrderNotification = exports.sendOrderStatusNotification = exports.sendNewOrderNotification = exports.facebookDataDeletionRequest = exports.cleanupExpiredPendingPaymentsScheduled = exports.deleteExpiredAdsImagesScheduled = exports.autoRenewSubscriptionsScheduled = exports.paymobWebhookHandler = void 0;
// ---------------------------------------------------------------------------
// INITIALIZE FIREBASE ADMIN
// ---------------------------------------------------------------------------
const app_1 = require("firebase-admin/app");
try {
    (0, app_1.initializeApp)();
}
catch (error) {
    // App already initialized, ignore
}
// ---------------------------------------------------------------------------
// LOAD ENVIRONMENT VARIABLES
// ---------------------------------------------------------------------------
const dotenv = __importStar(require("dotenv"));
dotenv.config(); // Reads .env and populates process.env
const fbAppSecret = process.env.FACEBOOK_APP_SECRET;
if (!fbAppSecret) {
    console.warn("⚠️ FACEBOOK_APP_SECRET is not defined in .env or environment variables");
}
// ---------------------------------------------------------------------------
// IMPORT OTHER MODULES
// ---------------------------------------------------------------------------
const functions = __importStar(require("firebase-functions/v2"));
const v2_1 = require("firebase-functions/v2");
const webhook_1 = require("./paymob/webhook");
const autoRenew_1 = require("./subscriptions/autoRenew");
const dataDeletion_1 = require("./facebook/dataDeletion");
const deleteExpiredImages_1 = require("./ads/deleteExpiredImages");
const cleanupExpired_1 = require("./pendingPayments/cleanupExpired");
// Order Notifications
const sendOrderNotification_1 = require("./notifications/sendOrderNotification");
Object.defineProperty(exports, "sendNewOrderNotification", { enumerable: true, get: function () { return sendOrderNotification_1.sendNewOrderNotification; } });
const sendStatusNotification_1 = require("./notifications/sendStatusNotification");
Object.defineProperty(exports, "sendOrderStatusNotification", { enumerable: true, get: function () { return sendStatusNotification_1.sendOrderStatusNotification; } });
Object.defineProperty(exports, "sendPastOrderNotification", { enumerable: true, get: function () { return sendStatusNotification_1.sendPastOrderNotification; } });
// ---------------------------------------------------------------------------
// GLOBAL OPTIONS
// ---------------------------------------------------------------------------
(0, v2_1.setGlobalOptions)({
    maxInstances: 10,
    region: "europe-west1",
});
// ---------------------------------------------------------------------------
// PAYMOB WEBHOOK - Handles subscription renewals
// ---------------------------------------------------------------------------
exports.paymobWebhookHandler = functions.https.onRequest({
    cors: true,
    memory: "512MiB",
}, webhook_1.paymobWebhook);
// ---------------------------------------------------------------------------
// SCHEDULED FUNCTIONS
// ---------------------------------------------------------------------------
exports.autoRenewSubscriptionsScheduled = functions.scheduler.onSchedule({
    schedule: "0 * * * *", // Every hour
    timeZone: "Africa/Cairo",
    memory: "512MiB",
}, autoRenew_1.autoRenewSubscriptions);
exports.deleteExpiredAdsImagesScheduled = functions.scheduler.onSchedule({
    schedule: "0 2 * * *", // Every day at 2:00 AM
    timeZone: "Africa/Cairo",
    memory: "512MiB",
}, deleteExpiredImages_1.deleteExpiredAdsImages);
exports.cleanupExpiredPendingPaymentsScheduled = functions.scheduler.onSchedule({
    schedule: "0 * * * *", // Every hour
    timeZone: "Africa/Cairo",
    memory: "512MiB",
}, cleanupExpired_1.cleanupExpiredPendingPayments);
// ---------------------------------------------------------------------------
// FACEBOOK DATA DELETION CALLBACK
// ---------------------------------------------------------------------------
exports.facebookDataDeletionRequest = functions.https.onRequest({
    cors: true,
    memory: "256MiB",
}, async (req, res) => {
    // تمرير secret من env للدالة
    await (0, dataDeletion_1.facebookDataDeletion)(req, res, fbAppSecret);
});
//# sourceMappingURL=index.js.map